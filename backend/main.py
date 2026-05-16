from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional
import httpx
import logging
from services.clasificador_service import ClasificadorService
from services.monumento_service import MonumentoService
from rag.rag_module import inicializar_rag, consultar_rag

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
    logger.warning("No se encontró monumentos_salamanca.json — /classify devolverá solo la clase")


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        inicializar_rag(chroma_path="./chroma_db")
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

OLLAMA_URL = "http://127.0.0.1:11434/api/chat"
MODEL = "qwen2.5:1.5b"

DEFAULT_SYSTEM_PROMPT = (
    "Eres un guía turístico experto en Salamanca. Responde siempre en español, de forma clara y amable. "
    "Da respuestas muy cortas y concisas, máximo 2-3 frases. "
    "Si te preguntan algo que no tiene que ver con turismo o Salamanca, "
    "redirige amablemente la conversación hacia el turismo en Salamanca."
)

# Tool que Qwen puede invocar para buscar información en ChromaDB
RAG_TOOL = {
    "type": "function",
    "function": {
        "name": "buscar_info_monumento",
        "description": "Busca información relevante sobre un monumento de Salamanca en la base de conocimiento.",
        "parameters": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "Consulta de búsqueda semántica sobre el monumento (en español)",
                }
            },
            "required": ["query"],
        },
    },
}


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


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

async def _llamar_qwen(messages: list, tools: list | None = None, timeout: float = 300.0) -> dict:
    payload = {"model": MODEL, "messages": messages, "stream": False}
    if tools:
        payload["tools"] = tools
    async with httpx.AsyncClient(timeout=timeout) as client:
        res = await client.post(OLLAMA_URL, json=payload)
        res.raise_for_status()
        return res.json()


async def _extraer_query(prompt: str, monumento: dict, history: list[Message]) -> str:
    """
    Llama a Qwen con la definición de la tool RAG para que extraiga la query
    semántica más relevante del prompt del usuario.
    Fallback: devuelve el prompt original si el modelo no llama a la tool.
    """
    system = (
        f"Eres un asistente turístico de Salamanca. Cuando el usuario pregunte sobre "
        f"{monumento.get('nombre', 'el monumento')}, usa la tool buscar_info_monumento "
        f"para buscar información en la base de conocimiento."
    )
    messages = [
        {"role": "system", "content": system},
        *[m.model_dump() for m in history],
        {"role": "user", "content": prompt},
    ]
    try:
        data = await _llamar_qwen(messages, tools=[RAG_TOOL], timeout=60.0)
        tool_calls = data.get("message", {}).get("tool_calls", [])
        if tool_calls:
            args = tool_calls[0].get("function", {}).get("arguments", {})
            query = args.get("query", "").strip()
            if query:
                logger.info("Tool call extrajo query: %s", query)
                return query
    except Exception as e:
        logger.warning("Tool call falló, usando prompt directo: %s", e)
    return prompt


async def _reformatear(texto: str, pregunta: str) -> str:
    """
    Pasa el texto recuperado (descripción corta o chunk RAG) por Qwen
    únicamente para mejorar el formato y el estilo, sin añadir información.
    """
    system = (
        "Eres un guía turístico de Salamanca. Presenta la siguiente información de forma "
        "natural y amable en español. "
        "CRÍTICO: NO añadas datos, fechas, nombres, lugares ni información que no esté "
        "en el texto original. Solo reformatea lo que ya está escrito."
    )
    messages = [
        {"role": "system", "content": system},
        {
            "role": "user",
            "content": f"Pregunta del usuario: {pregunta}\n\nInformación verificada:\n{texto}",
        },
    ]
    data = await _llamar_qwen(messages)
    return data["message"]["content"]


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.post("/query")
@app.post("/api/query")
async def query(q: Query):
    monumento = monumentos.lookup_by_id(q.monumento_id) if (monumentos and q.monumento_id) else None

    # --- Flujo con monumento conocido: RAG ---
    if monumento:
        clase = monumento.get("classifier_class", "").upper()

        # Paso 1 — Qwen extrae la query semántica vía tool call
        query_extraida = await _extraer_query(q.prompt, monumento, q.history)

        # Paso 2 — Búsqueda en ChromaDB
        chunks = consultar_rag(query_extraida, clase, n_resultados=1)
        texto = chunks[0]["texto"] if chunks else monumento.get("descripcion_corta", "")

        # Modo rápido: el chunk va directo a la app, Qwen no genera respuesta
        if q.modo == "rapido":
            return JSONResponse(content={"response": texto, "modo": "rapido"})

        # Modo pensar: Qwen reformatea el chunk sin añadir información
        try:
            respuesta = await _reformatear(texto, q.prompt)
        except Exception as e:
            logger.error("Reformateo falló, devolviendo texto sin formatear: %s", e)
            respuesta = texto
        return JSONResponse(content={"response": respuesta, "modo": "pensar"})

    # --- Flujo general: conversación sin monumento ---
    system = q.system.strip() if q.system and q.system.strip() else DEFAULT_SYSTEM_PROMPT
    if q.ciudad and q.ciudad.strip():
        system = f"{system}\nEl usuario se encuentra actualmente en: {q.ciudad.strip()}."

    messages = [
        {"role": "system", "content": system},
        *[m.model_dump() for m in q.history],
        {"role": "user", "content": q.prompt},
    ]
    try:
        data = await _llamar_qwen(messages)
        return JSONResponse(content={"response": data["message"]["content"]})
    except Exception as e:
        logger.error(f"ERROR: {type(e).__name__}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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

    # Modo pensar: Qwen reformatea la descripción corta antes de devolverla
    if modo == "pensar" and descripcion:
        try:
            descripcion = await _reformatear(descripcion, f"Preséntame {monumento['nombre']}")
        except Exception as e:
            logger.warning("Reformateo en classify falló: %s", e)

    return JSONResponse(content={
        "clase": clase,
        "id": monumento["id"],
        "nombre": monumento["nombre"],
        "descripcion_corta": descripcion,
        "pois_cercanos": [{"id": p["id"], "nombre": p["nombre"]} for p in pois],
    })
