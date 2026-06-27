import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi.errors import RateLimitExceeded
from slowapi import _rate_limit_exceeded_handler
from rag.rag_module import inicializar_rag
from core.config import limiter, GROQ_API_KEY
from core.llm import cerrar_cliente
from core.routers import router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    if not GROQ_API_KEY:
        logger.warning("GROQ_API_KEY no configurada: las respuestas de IA fallarán (401 de Groq).")
    try:
        inicializar_rag(chroma_path="./chroma_db")
    except Exception as e:
        logger.warning("RAG no disponible: %s", e)
    yield
    await cerrar_cliente()


app = FastAPI(title="TourClick API", version="1.0.0", lifespan=lifespan)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)
