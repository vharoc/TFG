from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional
import httpx
import json
import logging
import math
import os
from dotenv import load_dotenv
from services.clasificador_service import ClasificadorService
from services.monumento_service import MonumentoService
from rag.rag_module import inicializar_rag, consultar_rag

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

clasificador = ClasificadorService(
    onnx_path="models/dinov2_small_full.onnx",
    clf_path="models/clasificador_tourclick_final.pkl",
    classes_path="models/class_names.npy",
    meta_path="models/meta_tourclick.json",
)

try:
    monumentos = MonumentoService("/home/tfg/data/monumentos_salamanca.json")
    logger.info(f"MonumentoService cargado con {len(monumentos._data)} monumentos")
except FileNotFoundError:
    monumentos = None
    logger.warning("No se encontro monumentos_salamanca.json — /classify devolvera solo la clase")


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        inicializar_rag(chroma_path="./chroma_db/chroma_db")
    except Exception as e:
        logger.warning("RAG no disponible: %s", e)
    yield


app = FastAPI(title="TourClick API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
MODEL = "llama-3.3-70b-versatile"

DEFAULT_SYSTEM_PROMPT = (
    "Eres Clicky, un asistente turistico especializado en monumentos y patrimonio cultural. "
    "Hablas en espanol con un tono cercano, entusiasta y culto. "
    "Responde siempre en 2-3 frases como maximo. "
    "Te centras en que ver y conocer; si te preguntan por comida, restaurantes o actividades de ocio, "
    "redirige amablemente hacia los monumentos y lugares de interes. "
    "Nunca uses 'nuestra ciudad': usa 'esta ciudad' o el nombre del lugar. "
)

PENSAR_SYSTEM_PROMPT = (
    "Eres Clicky, un asistente turistico especializado en monumentos y patrimonio cultural. "
    "Hablas en espanol con un tono cercano, entusiasta y culto. "
    "Puedes extenderte hasta 3-4 frases cuando el tema lo merece. "
    "Te centras en que ver y conocer; si te preguntan por comida, restaurantes o actividades de ocio, "
    "redirige amablemente hacia los monumentos y lugares de interes. "
    "Nunca uses 'nuestra ciudad': usa 'esta ciudad' o el nombre del lugar. "
    "No termines tus respuestas con preguntas genericas como '¿en que puedo ayudarte?' o '¿que te trae por aqui?'."
)

class Message(BaseModel):
    role: str
    content: str

class Query(BaseModel):
    prompt: str
    system: Optional[str] = None
    ciudad: Optional[str] = None
    history: list[Message] = []
    monumento_id: Optional[str] = None
    modo: str = "rapido"  # "rapido" | "pensar"
    lat: Optional[float] = None
    lon: Optional[float] = None
    visitados: list[str] = []


class RutaRequest(BaseModel):
    lat: float
    lon: float
    filtro: str = "pendientes"   # "todos" | "visitados" | "pendientes"
    visitados: list[str] = []

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "usar_rag",
            "description": (
                "Busca información verificada sobre un monumento o lugar de interés de la ciudad. "
                "Úsala cuando el usuario pregunte sobre un monumento, edificio, escultura o patrimonio concreto."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "nombre": {"type": "string", "description": "Nombre o descripción del monumento a buscar"}
                },
                "required": ["nombre"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "generar_ruta",
            "description": (
                "Genera una ruta turística personalizada por los monumentos de la ciudad, "
                "ordenada por proximidad. Úsala cuando el usuario pida una ruta, itinerario o plan de visita."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "filtro": {
                        "type": "string",
                        "enum": ["todos", "visitados", "pendientes"],
                        "description": "Monumentos a incluir: todos, solo los ya visitados, o solo los aún no visitados"
                    }
                },
                "required": ["filtro"]
            }
        }
    }
]


async def _llamar_llm(messages: list, tools: list | None = None, timeout: float = 60.0) -> dict:
    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {"model": MODEL, "messages": messages, "stream": False}
    if tools:
        payload["tools"] = tools
    async with httpx.AsyncClient(timeout=timeout) as client:
        res = await client.post(GROQ_URL, headers=headers, json=payload)
        res.raise_for_status()
        return res.json()


def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return 2 * R * math.asin(math.sqrt(a))


def _filtrar_monumentos(filtro: str, visitados: list[str]) -> list[dict]:
    if monumentos is None:
        return []
    todos = monumentos._data
    if filtro == "visitados":
        return [m for m in todos if m["id"] in visitados]
    if filtro == "pendientes":
        return [m for m in todos if m["id"] not in visitados]
    return list(todos)


def _nearest_neighbor(lat: float, lon: float, candidatos: list[dict]) -> list[dict]:
    pendientes = list(candidatos)
    ruta = []
    pos = (lat, lon)
    while pendientes:
        cercano = min(pendientes, key=lambda m: _haversine_km(pos[0], pos[1], m["lat"], m["lon"]))
        dist_m = round(_haversine_km(pos[0], pos[1], cercano["lat"], cercano["lon"]) * 1000)
        tiempo_min = max(1, round(dist_m / 80))  # ~80 m/min a pie
        ruta.append({
            "id": cercano["id"],
            "nombre": cercano["nombre"],
            "descripcion_corta": cercano.get("descripcion_corta", ""),
            "lat": cercano["lat"],
            "lon": cercano["lon"],
            "distancia_m": dist_m,
            "tiempo_min": tiempo_min,
        })
        pos = (cercano["lat"], cercano["lon"])
        pendientes.remove(cercano)
    return ruta


def _ejecutar_generar_ruta(filtro: str, lat: float | None, lon: float | None, visitados: list[str]) -> dict:
    candidatos = _filtrar_monumentos(filtro, visitados)
    if not candidatos:
        return {"error": f"No hay monumentos para el filtro '{filtro}'", "paradas": [], "tiempo_total_min": 0}
    lat_ini = lat if lat is not None else 40.9640
    lon_ini = lon if lon is not None else -5.6640
    paradas = _nearest_neighbor(lat_ini, lon_ini, candidatos)
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


def _usar_rag(nombre: str) -> dict:
    if monumentos is None:
        return {"informacion": "Servicio de monumentos no disponible.", "monumento_id": None, "pois_cercanos": []}

    m = monumentos.detectar_en_texto(nombre)
    if m is None:
        return {"informacion": f"No tengo información verificada sobre '{nombre}'.", "monumento_id": None, "pois_cercanos": []}

    clase_rag = m["classifier_class"].strip().upper()
    chunks = consultar_rag(nombre, clase_rag, n_resultados=1)
    texto = chunks[0]["texto"] if chunks else m.get("descripcion_corta", "")

    pois = monumentos.get_nearby(m["id"])
    return {
        "informacion": texto,
        "monumento_id": m["id"],
        "nombre_monumento": m["nombre"],
        "pois_cercanos": [{"id": p["id"], "nombre": p["nombre"]} for p in pois],
    }


async def _query_pensar_agente(q: "Query", monumento_activo: dict | None) -> "JSONResponse":
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

    # Primera llamada: el modelo decide si usar usar_rag o responder directo
    data = await _llamar_llm(messages, tools=TOOLS)
    choice = data["choices"][0]

    monumento_id = None
    pois_data = []

    ruta_data = None

    if choice.get("finish_reason") == "tool_calls":
        tool_call = choice["message"]["tool_calls"][0]
        tool_name = tool_call["function"]["name"]
        args = json.loads(tool_call["function"]["arguments"])
        logger.info("Tool call: %s(%s)", tool_name, args)

        if tool_name == "usar_rag":
            resultado = _usar_rag(args["nombre"])
            monumento_id = resultado["monumento_id"]
            pois_data = resultado["pois_cercanos"]
            tool_content = json.dumps({"informacion": resultado["informacion"]}, ensure_ascii=False)

        elif tool_name == "generar_ruta":
            ejecutado = _ejecutar_generar_ruta(
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

    return JSONResponse(content={
        "response": respuesta,
        "modo": "pensar",
        "monumento_id": monumento_id,
        "pois_cercanos": pois_data,
        "ruta": ruta_data,
    })



async def _reformatear(texto: str, pregunta: str) -> str:
    system = (
        "Eres Clicky, el asistente turistico de Salamanca. Reformatea el siguiente texto verificado "
        "para que suene natural y cercano en espanol, en 2 frases como maximo. "
        "IMPORTANTE: usa unicamente la informacion del texto proporcionado. "
        "No inventes fechas, nombres, cifras ni datos que no esten en el."
    )
    messages = [
        {"role": "system", "content": system},
        {"role": "user", "content": f"Pregunta del usuario: {pregunta}\n\nInformacion verificada:\n{texto}"},
    ]
    data = await _llamar_llm(messages)
    return data["choices"][0]["message"]["content"]


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.post("/query")
@app.post("/api/query")
async def query(q: Query):
    # Modo pensar: agente con tool calling
    if q.modo == "pensar":
        monumento_activo = monumentos.lookup_by_id(q.monumento_id) if (monumentos and q.monumento_id) else None
        try:
            return await _query_pensar_agente(q, monumento_activo)
        except Exception as e:
            logger.error("Error en modo pensar: %s", e)
            raise HTTPException(status_code=500, detail=str(e))

    # Modo rápido: alias matching + RAG directo, sin LLM para monumentos
    monumento = monumentos.lookup_by_id(q.monumento_id) if (monumentos and q.monumento_id) else None
    m_mencionado = monumentos.detectar_en_texto(q.prompt) if monumentos else None

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

    if clase_rag and monumento_rag:
        chunks = consultar_rag(q.prompt, clase_rag, n_resultados=1)
        logger.info("RAG rapido: clase=%s chunks=%d", clase_rag, len(chunks))
        texto = chunks[0]["texto"] if chunks else monumento_rag.get("descripcion_corta", "")
        if texto:
            mid = monumento_rag["id"]
            pois = monumentos.get_nearby(mid) if monumentos else []
            pois_data = [{"id": p["id"], "nombre": p["nombre"]} for p in pois]
            return JSONResponse(content={"response": texto, "modo": "rapido", "monumento_id": mid, "pois_cercanos": pois_data})

    # Sin RAG: LLM con contexto de monumento activo si lo hay
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
        return JSONResponse(content={"response": data["choices"][0]["message"]["content"], "monumento_id": None, "pois_cercanos": []})
    except Exception as e:
        logger.error("Error en modo rapido: %s", e)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/ruta")
@app.post("/api/ruta")
async def ruta(req: RutaRequest):
    if monumentos is None:
        raise HTTPException(status_code=503, detail="Servicio de monumentos no disponible")
    resultado = _ejecutar_generar_ruta(req.filtro, req.lat, req.lon, req.visitados)
    if "error" in resultado:
        return JSONResponse(content={"paradas": [], "tiempo_total_min": 0, "resumen": resultado["error"]})
    resumen = await _narrar_resumen_ruta(resultado["paradas"])
    return JSONResponse(content={
        "paradas": resultado["paradas"],
        "tiempo_total_min": resultado["tiempo_total_min"],
        "resumen": resumen,
    })


@app.get("/health")
@app.get("/api/health")
async def health():
    return JSONResponse(content={"status": "ok"})


@app.post("/classify")
@app.post("/api/classify")
async def classify(imagen: UploadFile = File(...), modo: str = Form("rapido")):
    data = await imagen.read()
    clase = clasificador.clasificar(data)

    if monumentos is None:
        return JSONResponse(content={"clase": clase, "nombre": clase, "descripcion_corta": None, "pois_cercanos": []})

    monumento = monumentos.lookup_by_class(clase)
    if monumento is None:
        return JSONResponse(content={"clase": clase, "nombre": clase, "descripcion_corta": None, "pois_cercanos": []})

    pois = monumentos.get_nearby(monumento["id"])
    descripcion = monumento["descripcion_corta"]

    if modo == "pensar" and descripcion:
        try:
            descripcion = await _reformatear(descripcion, f"Presentame {monumento['nombre']}")
        except Exception as e:
            logger.warning("Reformateo en classify fallo: %s", e)

    return JSONResponse(content={
        "clase": clase,
        "id": monumento["id"],
        "nombre": monumento["nombre"],
        "descripcion_corta": descripcion,
        "pois_cercanos": [{"id": p["id"], "nombre": p["nombre"]} for p in pois],
    })
