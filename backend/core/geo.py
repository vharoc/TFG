import math
import logging
from .llm import _llamar_llm

logger = logging.getLogger(__name__)


def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return 2 * R * math.asin(math.sqrt(a))


def _filtrar_monumentos(mon, filtro: str, visitados: list[str]) -> list[dict]:
    if mon is None:
        return []
    todos = mon._data
    if filtro == "visitados":
        return [m for m in todos if m["id"] in visitados]
    if filtro == "pendientes":
        return [m for m in todos if m["id"] not in visitados]
    return list(todos)


def _nearest_neighbor(lat: float, lon: float, candidatos: list[dict]) -> list[dict]:
    pendientes = list(candidatos)
    orden = []
    pos = (lat, lon)
    while pendientes:
        cercano = min(pendientes, key=lambda m: _haversine_km(pos[0], pos[1], m["lat"], m["lon"]))
        orden.append(cercano)
        pos = (cercano["lat"], cercano["lon"])
        pendientes.remove(cercano)
    return orden


def _longitud_ruta(lat: float, lon: float, orden: list[dict]) -> float:
    total = 0.0
    pos = (lat, lon)
    for m in orden:
        total += _haversine_km(pos[0], pos[1], m["lat"], m["lon"])
        pos = (m["lat"], m["lon"])
    return total


def _dos_opt(lat: float, lon: float, orden: list[dict]) -> list[dict]:
    """Refina la ruta con 2-opt: invierte segmentos mientras acorte el total."""
    if len(orden) < 3:
        return orden
    mejor = orden
    mejor_dist = _longitud_ruta(lat, lon, mejor)
    mejorado = True
    while mejorado:
        mejorado = False
        for i in range(len(mejor) - 1):
            for j in range(i + 1, len(mejor)):
                candidato = mejor[:i] + mejor[i:j + 1][::-1] + mejor[j + 1:]
                dist = _longitud_ruta(lat, lon, candidato)
                if dist < mejor_dist - 1e-9:
                    mejor, mejor_dist = candidato, dist
                    mejorado = True
    return mejor


def _construir_paradas(lat: float, lon: float, orden: list[dict]) -> list[dict]:
    paradas = []
    pos = (lat, lon)
    for m in orden:
        dist_m = round(_haversine_km(pos[0], pos[1], m["lat"], m["lon"]) * 1000)
        paradas.append({
            "id": m["id"],
            "nombre": m["nombre"],
            "descripcion_corta": m.get("descripcion_corta", ""),
            "lat": m["lat"],
            "lon": m["lon"],
            "distancia_m": dist_m,
            "tiempo_min": max(1, round(dist_m / 80)),
        })
        pos = (m["lat"], m["lon"])
    return paradas


def _ejecutar_generar_ruta(mon, filtro: str, lat: float | None, lon: float | None, visitados: list[str]) -> dict:
    candidatos = _filtrar_monumentos(mon, filtro, visitados)
    if not candidatos:
        return {"error": f"No hay monumentos para el filtro '{filtro}'", "paradas": [], "tiempo_total_min": 0}
    lat_ini = lat if lat is not None else 40.9640
    lon_ini = lon if lon is not None else -5.6640
    orden = _nearest_neighbor(lat_ini, lon_ini, candidatos)
    orden = _dos_opt(lat_ini, lon_ini, orden)
    paradas = _construir_paradas(lat_ini, lon_ini, orden)
    return {"paradas": paradas, "tiempo_total_min": sum(p["tiempo_min"] for p in paradas)}


async def _narrar_resumen_ruta(paradas: list[dict]) -> str:
    if not paradas:
        return "No hay paradas disponibles."
    lista = "\n".join(
        f"{i+1}. {p['nombre']} (~{p['tiempo_min']} min andando)" for i, p in enumerate(paradas)
    )
    tiempo = sum(p["tiempo_min"] for p in paradas)
    messages = [
        {"role": "system", "content": (
            "Eres Clicky, guia turistico. Presenta esta ruta de forma breve y entusiasta en espanol, "
            "en 2-3 frases. No enumeres todos los monumentos; menciona el primero, el ultimo y cuantos hay en total."
        )},
        {"role": "user", "content": f"Ruta de {len(paradas)} paradas (~{tiempo} min):\n{lista}"},
    ]
    try:
        data = await _llamar_llm(messages)
        return data["choices"][0]["message"]["content"]
    except Exception:
        return f"Ruta de {len(paradas)} paradas, aproximadamente {tiempo} minutos a pie."
