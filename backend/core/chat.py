import json
import logging
from fastapi import HTTPException
from fastapi.responses import JSONResponse
from rag.rag_module import consultar_rag
from .config import (
    PENSAR_SYSTEM_PROMPT, DEFAULT_SYSTEM_PROMPT,
    _con_tokens, _KEYWORDS_NAVEGACION,
)
from .llm import _llamar_llm, TOOLS
from .geo import _haversine_km, _ejecutar_generar_ruta
from .models import Query

logger = logging.getLogger(__name__)


def _es_consulta_navegacion(prompt: str) -> bool:
    p = prompt.lower()
    return any(k in p for k in _KEYWORDS_NAVEGACION)


def _buscar_monumento_por_nombre(mon, nombre: str) -> dict | None:
    if mon is None:
        return None
    resultado = mon.detectar_en_texto(nombre)
    if resultado:
        return resultado
    nombre_lower = nombre.lower()
    for m in mon._data:
        if nombre_lower in m["nombre"].lower() or m["nombre"].lower() in nombre_lower:
            return m
    return None


def _info_navegacion(mon, nombre: str, lat: float | None, lon: float | None) -> dict | None:
    monumento = _buscar_monumento_por_nombre(mon, nombre)
    if monumento is None:
        return None
    distancia_m = None
    tiempo_min = None
    if lat is not None and lon is not None:
        distancia_m = round(_haversine_km(lat, lon, monumento["lat"], monumento["lon"]) * 1000)
        tiempo_min = max(1, round(distancia_m / 80))
    return {
        "id": monumento["id"],
        "nombre": monumento["nombre"],
        "lat": monumento["lat"],
        "lon": monumento["lon"],
        "distancia_m": distancia_m,
        "tiempo_min": tiempo_min,
    }


def _usar_rag(mon, nombre: str, query: str | None = None) -> dict:
    if mon is None:
        return {"informacion": "Servicio de monumentos no disponible.", "monumento_id": None, "pois_cercanos": []}

    m = mon.detectar_en_texto(nombre)
    if m is None:
        return {"informacion": f"No tengo información verificada sobre '{nombre}'.", "monumento_id": None, "pois_cercanos": []}

    rag_key = m.get("rag_key") or m["classifier_class"]
    chunks = consultar_rag(query or nombre, rag_key, n_resultados=3)

    sims = [round(c["similitud"], 3) for c in chunks]
    logger.info("usar_rag: key=%s | query=%r | %d chunks | similitudes=%s", rag_key, query or nombre, len(chunks), sims)

    relevantes = [c["texto"] for c in chunks]
    informacion = "\n\n".join(relevantes) if relevantes else m.get("descripcion_corta", "")

    pois = mon.get_nearby(m["id"])
    return {
        "informacion": informacion,
        "monumento_id": m["id"],
        "nombre_monumento": m["nombre"],
        "pois_cercanos": [{"id": p["id"], "nombre": p["nombre"]} for p in pois],
    }


async def _query_pensar_agente(q: Query, mon, monumento_activo: dict | None) -> JSONResponse:
    system = PENSAR_SYSTEM_PROMPT
    if q.ciudad and q.ciudad.strip():
        system += f"\nEl usuario se encuentra en: {q.ciudad.strip()}."
    if monumento_activo:
        system += f"\nContexto actual: el usuario está visitando '{monumento_activo['nombre']}'."

    messages = [
        {"role": "system", "content": system},
        *[m.model_dump() for m in q.history],
        {"role": "user", "content": q.prompt},
    ]

    data = await _llamar_llm(messages, tools=TOOLS)
    choice = data["choices"][0]

    monumento_id = None
    pois_data = []
    ruta_data = None
    navegacion_data = None

    if choice.get("finish_reason") == "tool_calls":
        tool_call = choice["message"]["tool_calls"][0]
        tool_name = tool_call["function"]["name"]
        args = json.loads(tool_call["function"]["arguments"])
        logger.info("Tool call: %s(%s)", tool_name, args)

        if tool_name == "usar_rag":
            resultado = _usar_rag(mon, args["nombre"], query=q.prompt)
            monumento_id = resultado["monumento_id"]
            pois_data = resultado["pois_cercanos"]
            tool_content = json.dumps({"informacion": resultado["informacion"]}, ensure_ascii=False)

        elif tool_name == "generar_ruta":
            ejecutado = _ejecutar_generar_ruta(
                mon,
                filtro=args.get("filtro", "todos"),
                lat=q.lat, lon=q.lon,
                visitados=q.visitados,
            )
            ruta_data = ejecutado
            paradas_resumen = [
                {"nombre": p["nombre"], "distancia_m": p["distancia_m"], "tiempo_min": p["tiempo_min"]}
                for p in ejecutado.get("paradas", [])
            ]
            tool_content = json.dumps({
                "paradas": paradas_resumen,
                "tiempo_total_min": ejecutado.get("tiempo_total_min", 0),
            }, ensure_ascii=False)

        elif tool_name == "como_llegar":
            info = _info_navegacion(mon, args["nombre"], q.lat, q.lon)
            if info is None:
                tool_content = json.dumps({"error": f"No encontré '{args['nombre']}' en la ciudad."}, ensure_ascii=False)
            else:
                navegacion_data = {"nombre": info["nombre"], "lat": info["lat"], "lon": info["lon"]}
                desc = f"{info['nombre']}"
                if info["distancia_m"] is not None:
                    desc += f" está a {info['distancia_m']} metros (~{info['tiempo_min']} min a pie)"
                tool_content = json.dumps({"destino": desc, **info}, ensure_ascii=False)

        else:
            tool_content = json.dumps({"error": f"Herramienta '{tool_name}' no reconocida"})

        messages.append(choice["message"])
        messages.append({
            "role": "tool",
            "tool_call_id": tool_call["id"],
            "content": tool_content,
        })
        final = await _llamar_llm(messages)
        respuesta = final["choices"][0]["message"]["content"]
    else:
        respuesta = choice["message"]["content"]

    return _con_tokens({
        "response": respuesta,
        "modo": "pensar",
        "monumento_id": monumento_id,
        "pois_cercanos": pois_data,
        "ruta": ruta_data,
        "navegacion": navegacion_data,
    })


async def _query_rapido(q: Query, mon) -> JSONResponse:
    monumento = mon.lookup_by_id(q.monumento_id) if (mon and q.monumento_id) else None
    m_mencionado = mon.detectar_en_texto(q.prompt) if mon else None

    monumento_rag = monumento
    clase_rag: str | None = None

    if monumento:
        if m_mencionado:
            if m_mencionado["id"] != monumento["id"]:
                monumento_rag = m_mencionado
                logger.info("Cambio de contexto: %s -> %s", monumento["id"], m_mencionado["id"])
            clase_rag = monumento_rag["classifier_class"].strip().upper()
    elif m_mencionado:
        monumento_rag = m_mencionado
        clase_rag = m_mencionado["classifier_class"].strip().upper()

    if _es_consulta_navegacion(q.prompt):
        destino_nombre = (m_mencionado or monumento_rag or {}).get("nombre", "")
        if not destino_nombre:
            destino_nombre = q.prompt
        info = _info_navegacion(mon, destino_nombre, q.lat, q.lon)
        if info:
            nav_data = {"nombre": info["nombre"], "lat": info["lat"], "lon": info["lon"]}
            partes = [f"📍 {info['nombre']}"]
            if info["distancia_m"] is not None:
                partes.append(f"Está a {info['distancia_m']} metros desde donde estás, aproximadamente {info['tiempo_min']} minutos a pie.")
            else:
                partes.append("Pulsa 'Cómo llegar' para abrir la navegación.")
            partes.append("¡Pulsa el botón 'Cómo llegar' para abrir Google Maps con la ruta a pie!")
            return _con_tokens({
                "response": " ".join(partes),
                "modo": "rapido",
                "monumento_id": info.get("id"),
                "pois_cercanos": [],
                "navegacion": nav_data,
            })

    if clase_rag and monumento_rag:
        rag_key = monumento_rag.get("rag_key") or monumento_rag["classifier_class"]
        chunks = consultar_rag(q.prompt, rag_key, n_resultados=1)
        logger.info("RAG rapido: key=%s chunks=%d", rag_key, len(chunks))
        texto = chunks[0]["texto"] if chunks else monumento_rag.get("descripcion_corta", "")
        if texto:
            mid = monumento_rag["id"]
            pois = mon.get_nearby(mid) if mon else []
            pois_data = [{"id": p["id"], "nombre": p["nombre"]} for p in pois]
            return _con_tokens({
                "response": texto,
                "modo": "rapido",
                "monumento_id": mid,
                "pois_cercanos": pois_data,
                "navegacion": None,
            })

    system = DEFAULT_SYSTEM_PROMPT
    if q.ciudad and q.ciudad.strip():
        system += f"\nEl usuario se encuentra en: {q.ciudad.strip()}."
    if monumento_rag:
        system += (
            f"\nContexto: el usuario visita '{monumento_rag['nombre']}'. "
            f"Descripcion verificada: {monumento_rag.get('descripcion_corta', '')} "
            f"Habla de este lugar si la pregunta guarda relacion, o responde normalmente si no."
        )

    messages = [
        {"role": "system", "content": system},
        *[m.model_dump() for m in q.history],
        {"role": "user", "content": q.prompt},
    ]
    try:
        data = await _llamar_llm(messages)
        return _con_tokens({
            "response": data["choices"][0]["message"]["content"],
            "monumento_id": None,
            "pois_cercanos": [],
            "navegacion": None,
        })
    except Exception as e:
        logger.error("Error en modo rapido: %s", e)
        raise HTTPException(status_code=500, detail=str(e))
