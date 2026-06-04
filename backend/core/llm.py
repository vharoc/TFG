import httpx
import json
import logging
from .config import GROQ_API_KEY, GROQ_URL, MODEL, _tokens_request

logger = logging.getLogger(__name__)

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
    },
    {
        "type": "function",
        "function": {
            "name": "como_llegar",
            "description": (
                "Proporciona indicaciones de cómo llegar a un monumento desde la posición actual del usuario. "
                "Úsala cuando el usuario pregunte cómo llegar, cómo ir, dónde está, qué camino tomar "
                "o pida indicaciones para desplazarse a un lugar concreto."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "nombre": {
                        "type": "string",
                        "description": "Nombre del monumento o lugar al que el usuario quiere ir"
                    }
                },
                "required": ["nombre"]
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
        data = res.json()
        usage = data.get("usage") or {}
        _tokens_request.set(_tokens_request.get() + int(usage.get("total_tokens", 0) or 0))
        return data


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
