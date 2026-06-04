from pydantic import BaseModel
from typing import Optional


class Message(BaseModel):
    role: str
    content: str


class Query(BaseModel):
    prompt: str
    system: Optional[str] = None
    ciudad: Optional[str] = None
    history: list[Message] = []
    monumento_id: Optional[str] = None
    modo: str = "rapido"
    lat: Optional[float] = None
    lon: Optional[float] = None
    visitados: list[str] = []


class RutaRequest(BaseModel):
    lat: float
    lon: float
    filtro: str = "pendientes"
    visitados: list[str] = []
    ciudad: Optional[str] = None
