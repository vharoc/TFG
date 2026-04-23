from fastapi import APIRouter
from pydantic import BaseModel
from services.chat_service import chat_simple

router = APIRouter()

class ChatRequest(BaseModel):
    mensaje: str

class ChatResponse(BaseModel):
    respuesta: str

@router.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    respuesta = chat_simple(req.mensaje)
    return ChatResponse(respuesta=respuesta)