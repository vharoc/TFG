"""
Tests de seguridad para la API de TourClick.
Ejecutar con el servidor activo:
    python -m pytest tests/test_security.py -v
O directamente:
    python tests/test_security.py

Cambia BASE_URL si el servidor está en remoto.
"""

import io
import time
import asyncio
import httpx

BASE_URL = "http://localhost:8000"  # cambiar a la URL del servidor si es remoto


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def url(path: str) -> str:
    return f"{BASE_URL}{path}"


def query_payload(**kwargs) -> dict:
    base = {"prompt": "Hola", "ciudad": "salamanca", "modo": "rapido"}
    base.update(kwargs)
    return base


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

def test_health():
    r = httpx.get(url("/api/health"))
    assert r.status_code == 200, f"Health falló: {r.status_code}"
    print("  [OK] /health responde")


def test_query_ok():
    r = httpx.post(url("/api/query"), json=query_payload(), timeout=30)
    assert r.status_code == 200, f"Query básico falló: {r.status_code} {r.text}"
    print("  [OK] /query responde correctamente")


def test_prompt_demasiado_largo():
    r = httpx.post(url("/api/query"), json=query_payload(prompt="A" * 1501), timeout=10)
    assert r.status_code == 422, f"Esperaba 422, obtuvo {r.status_code}"
    print("  [OK] /query rechaza prompts > 1500 caracteres")


def test_modo_invalido():
    r = httpx.post(url("/api/query"), json=query_payload(modo="hackear"), timeout=10)
    assert r.status_code == 422, f"Esperaba 422, obtuvo {r.status_code}"
    print("  [OK] /query rechaza modo inválido")


def test_historial_demasiado_largo():
    history = [{"role": "user", "content": "hola"}] * 21
    r = httpx.post(url("/api/query"), json=query_payload(history=history), timeout=10)
    assert r.status_code == 422, f"Esperaba 422, obtuvo {r.status_code}"
    print("  [OK] /query rechaza historial > 20 mensajes")


def test_classify_contenido_invalido():
    # Un PDF con content-type image/jpeg debe ser rechazado por Pillow → 400
    fake_pdf = io.BytesIO(b"%PDF-1.4 fake content here")
    r = httpx.post(
        url("/api/classify"),
        files={"imagen": ("doc.pdf", fake_pdf, "image/jpeg")},
        data={"ciudad": "salamanca"},
        timeout=10,
    )
    assert r.status_code == 400, f"Esperaba 400, obtuvo {r.status_code}"
    print("  [OK] /classify rechaza contenido no-imagen aunque el content-type sea image/jpeg")


def test_classify_imagen_grande():
    big_image = io.BytesIO(b"\xff\xd8\xff" + b"0" * (5 * 1024 * 1024 + 1))
    r = httpx.post(
        url("/api/classify"),
        files={"imagen": ("grande.jpg", big_image, "image/jpeg")},
        data={"ciudad": "salamanca"},
        timeout=15,
    )
    assert r.status_code == 413, f"Esperaba 413, obtuvo {r.status_code}"
    print("  [OK] /classify rechaza imágenes > 5 MB")


def test_rate_limit_query():
    """Envía 17 peticiones rápidas; las últimas deben recibir 429."""
    responses = []
    for i in range(17):
        r = httpx.post(url("/api/query"), json=query_payload(), timeout=30)
        responses.append(r.status_code)

    got_429 = any(s == 429 for s in responses)
    assert got_429, f"Esperaba al menos un 429. Respuestas: {responses}"
    print(f"  [OK] Rate limit activo en /query (respuestas: {set(responses)})")


def test_classify_imagen_corrupta():
    # JPEG válido en content-type pero datos truncados → 400, no 500
    fake = io.BytesIO(b"\xff\xd8\xff\xe0" + b"0" * 100)
    r = httpx.post(
        url("/api/classify"),
        files={"imagen": ("truncado.jpg", fake, "image/jpeg")},
        data={"ciudad": "salamanca"},
        timeout=10,
    )
    assert r.status_code == 400, f"Esperaba 400, obtuvo {r.status_code}"
    print("  [OK] /classify devuelve 400 para imagen corrupta (no 500)")


def test_rate_limit_classify():
    """Envía 12 peticiones de classify; las últimas deben ser 429."""
    fake = io.BytesIO(b"\xff\xd8\xff\xe0" + b"0" * 100)
    responses = []
    for i in range(12):
        fake.seek(0)
        r = httpx.post(
            url("/api/classify"),
            files={"imagen": ("test.jpg", fake, "image/jpeg")},
            data={"ciudad": "salamanca"},
            timeout=15,
        )
        responses.append(r.status_code)

    got_429 = any(s == 429 for s in responses)
    assert got_429, f"Esperaba al menos un 429. Respuestas: {responses}"
    # Las respuestas intermedias serán 400 (imagen corrupta) hasta que salte el 429
    print(f"  [OK] Rate limit activo en /classify (respuestas: {set(responses)})")


# ---------------------------------------------------------------------------
# Runner manual (sin pytest)
# ---------------------------------------------------------------------------

TESTS = [
    test_health,
    test_query_ok,
    test_prompt_demasiado_largo,
    test_modo_invalido,
    test_historial_demasiado_largo,
    test_classify_contenido_invalido,
    test_classify_imagen_grande,
    test_classify_imagen_corrupta,
    test_rate_limit_query,
    test_rate_limit_classify,
]

if __name__ == "__main__":
    print(f"\nTestando contra {BASE_URL}\n")
    passed = failed = 0
    for t in TESTS:
        name = t.__name__.replace("test_", "").replace("_", " ")
        try:
            t()
            passed += 1
        except AssertionError as e:
            print(f"  [FAIL] {name}: {e}")
            failed += 1
        except Exception as e:
            print(f"  [ERROR] {name}: {e}")
            failed += 1

    print(f"\n{'='*40}")
    print(f"Resultado: {passed} pasados, {failed} fallados")
    if failed:
        print("ATENCIÓN: algunos tests de seguridad han fallado.")
    else:
        print("Todo correcto.")
