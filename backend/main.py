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


def _clases_soportadas() -> list[str]:
    if monumentos is None:
        return []
    return [m.get("classifier_class", "").strip().upper() for m in monumentos._data if m.get("classifier_class")]


def _detectar_monumento_en_texto(texto: str) -> str | None:
    """
    Comprueba si el texto del usuario menciona algún monumento soportado.
    Usa matching exacto contra la lista normalizada de classifier_class.
    Devuelve la clase del monumento detectado, o None si no hay coincidencia.
    """
    texto_upper = texto.upper()
    for clase in _clases_soportadas():
        if clase in texto_upper:
            return clase
    return None


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

    # --- Determinar qué monumento usar para RAG ---
    clase_rag: str | None = None
    monumento_rag = monumento

    if monumento:
        clase_actual = monumento.get("classifier_class", "").strip().upper()
        # Comprobar si el usuario menciona un monumento diferente en el texto
        clase_mencionada = _detectar_monumento_en_texto(q.prompt)
        if clase_mencionada and clase_mencionada != clase_actual and monumentos:
            m_nuevo = monumentos.lookup_by_class(clase_mencionada)
            if m_nuevo:
                monumento_rag = m_nuevo
                clase_rag = clase_mencionada
                logger.info("Cambio de contexto: %s -> %s", clase_actual, clase_rag)
            else:
                clase_rag = clase_actual
        else:
            clase_rag = clase_actual
    else:
        # Sin contexto de foto: detectar monumento mencionado en el texto
        clase_mencionada = _detectar_monumento_en_texto(q.prompt)
        if clase_mencionada and monumentos:
            m = monumentos.lookup_by_class(clase_mencionada)
            if m:
                monumento_rag = m
                clase_rag = clase_mencionada

    # --- RAG si hay clase válida ---
    if clase_rag:
        chunks = consultar_rag(q.prompt, clase_rag, n_resultados=1)
        logger.info("RAG: clase=%s chunks=%d", clase_rag, len(chunks))
        texto = chunks[0]["texto"] if chunks else (monumento_rag.get("descripcion_corta", "") if monumento_rag else "")

        if texto:
            if q.modo == "rapido":
                return JSONResponse(content={"response": texto, "modo": "rapido"})
            try:
                respuesta = await _reformatear(texto, q.prompt)
            except Exception as e:
                logger.error("Reformateo fallo: %s", e)
                respuesta = texto
            return JSONResponse(content={"response": respuesta, "modo": "pensar"})

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
