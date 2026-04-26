from fastapi import APIRouter
from pydantic import BaseModel
from services.chat_service import chat_simple

router = APIRouter()


class QueryRequest(BaseModel):
    prompt: str
    system: str = ""


class QueryResponse(BaseModel):
    response: str


class ChatRequest(BaseModel):
    mensaje: str


class ChatResponse(BaseModel):
    respuesta: str


@router.post("/query", response_model=QueryResponse)
def query(req: QueryRequest):
    respuesta = chat_simple(req.prompt, req.system)
    return QueryResponse(response=respuesta)


@router.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    respuesta = chat_simple(req.mensaje)
    return ChatResponse(respuesta=respuesta)
