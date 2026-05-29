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

OLLAMA_URL = "http://127.0.0.1:11434/api/chat"
MODEL = "qwen2.5:1.5b"

DEFAULT_SYSTEM_PROMPT = (
    "Eres un guia turistico experto en Salamanca. Responde siempre en espanol, de forma clara y amable. "
    "Da respuestas muy cortas y concisas, maximo 2-3 frases. "
    "Si te preguntan algo que no tiene que ver con turismo o Salamanca, "
    "redirige amablemente la conversacion hacia el turismo en Salamanca."
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



async def _reformatear(texto: str, pregunta: str) -> str:
    """
    Pasa el texto recuperado (descripcion corta o chunk RAG) por Qwen
    unicamente para mejorar el formato y el estilo, sin añadir informacion.
    """
    system = (
        "Eres un guia turistico de Salamanca. Presenta la siguiente informacion de forma "
        "natural y amable en espanol. "
        "CRITICO: NO añadas datos, fechas, nombres, lugares ni informacion que no este "
        "en el texto original. Solo reformatea lo que ya esta escrito."
    )
    messages = [
        {"role": "system", "content": system},
        {
            "role": "user",
            "content": f"Pregunta del usuario: {pregunta}\n\nInformacion verificada:\n{texto}",
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
    m_mencionado = monumentos.detectar_en_texto(q.prompt) if monumentos else None

    # --- Determinar qué monumento usar para RAG ---
    monumento_rag = monumento
    clase_rag: str | None = None

    if monumento:
        if m_mencionado and m_mencionado["id"] != monumento["id"]:
            monumento_rag = m_mencionado
            logger.info("Cambio de contexto: %s -> %s", monumento["id"], m_mencionado["id"])
        clase_rag = monumento_rag["classifier_class"].strip().upper()
    elif m_mencionado:
        monumento_rag = m_mencionado
        clase_rag = m_mencionado["classifier_class"].strip().upper()

    # --- RAG si hay clase válida ---
    if clase_rag and monumento_rag:
        chunks = consultar_rag(q.prompt, clase_rag, n_resultados=1)
        logger.info("RAG: clase=%s chunks=%d", clase_rag, len(chunks))
        texto = chunks[0]["texto"] if chunks else monumento_rag.get("descripcion_corta", "")

        if texto:
            mid = monumento_rag["id"]
            if q.modo == "rapido":
                return JSONResponse(content={"response": texto, "modo": "rapido", "monumento_id": mid})
            try:
                respuesta = await _reformatear(texto, q.prompt)
            except Exception as e:
                logger.error("Reformateo fallo: %s", e)
                respuesta = texto
            return JSONResponse(content={"response": respuesta, "modo": "pensar", "monumento_id": mid})

    # --- Flujo general: conversacion sin monumento o RAG vacio ---
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
        return JSONResponse(content={"response": data["message"]["content"], "monumento_id": None})
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

    # Modo pensar: Qwen reformatea la descripcion corta antes de devolverla
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
