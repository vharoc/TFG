from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional
import httpx
import logging
from services.clasificador_service import ClasificadorService
from services.monumento_service import MonumentoService

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

clasificador = ClasificadorService(
        onnx_path="models/dinov2_small_full.onnx",
        clf_path="models/clasificador_tourclick_final.pkl",
        classes_path="models/class_names.npy",
        meta_path="models/meta_tourclick.json",
)

try:
    monumentos = MonumentoService("data/monumentos_salamanca.json")
    logger.info(f"MonumentoService cargado con {len(monumentos._data)} monumentos")
except FileNotFoundError:
    monumentos = None
    logger.warning("No se encontró monumentos_salamanca.json — /classify devolverá solo la clase")

app = FastAPI(title="TourClick API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

OLLAMA_URL = "http://127.0.0.1:11434/api/chat"
MODEL = "qwen2.5:1.5b"

DEFAULT_SYSTEM_PROMPT = """Eres un guía turístico experto en Salamanca. Responde siempre en español, de forma clara y amable. Da respuestas muy cortas y concisas, máximo 2-3 frases. Si te preguntan algo que no tiene que ver con turismo o Salamanca, redirige amablemente la conversación hacia el turismo en Salamanca."""


class Message(BaseModel):
    role: str  # "user" | "assistant" | "system"
    content: str


class Query(BaseModel):
    prompt: str
    system: Optional[str] = None
    ciudad: Optional[str] = None
    history: list[Message] = []


def build_system_prompt(system: Optional[str], ciudad: Optional[str]) -> str:
    base = system.strip() if system and system.strip() else DEFAULT_SYSTEM_PROMPT
    if ciudad and ciudad.strip():
        return f"{base}\nEl usuario se encuentra actualmente en: {ciudad.strip()}."
    return base

@app.post("/query")
@app.post("/api/query")
async def query(q: Query):
    messages = [
        {
                "role": "system", "content": build_system_prompt(q.system, q.ciudad)
        },
        *[m.model_dump() for m in q.history],
        {
                "role": "user", "content": q.prompt
        },
    ]

    try:
        async with httpx.AsyncClient(timeout=300.0) as client:
            res = await client.post(OLLAMA_URL, json={"model": MODEL, "messages": messages, "stream": False})
            res.raise_for_status()
            data = res.json()
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
async def classify(imagen: UploadFile = File(...)):
    data = await imagen.read()
    clase = clasificador.clasificar(data)

    if monumentos is None:
        return JSONResponse(content={"clase": clase, "nombre": clase, "descripcion_corta": None, "pois_cercanos": []})

    monumento = monumentos.lookup_by_class(clase)
    if monumento is None:
        return JSONResponse(content={"clase": clase, "nombre": clase, "descripcion_corta": None, "pois_cercanos": []})

    pois = monumentos.get_nearby(monumento["id"])
    return JSONResponse(content={
        "clase": clase,
        "nombre": monumento["nombre"],
        "descripcion_corta": monumento["descripcion_corta"],
        "pois_cercanos": [{"id": p["id"], "nombre": p["nombre"]} for p in pois],
    })