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
                    "nombre": {
                        "type": "string",
                        "description": "Nombre exacto del monumento a buscar"
                    },
                    "query": {
                        "type": "string",
                        "description": (
                            "Descripción semántica del contenido que se busca, en términos del tema "
                            "real (no de la intención del usuario). Debe ser descriptiva y rica para "
                            "maximizar la relevancia de los resultados. "
                            "Ejemplos: 'leyendas y mitos de la Catedral de Salamanca', "
                            "'curiosidades y datos sorprendentes de la Casa de las Conchas', "
                            "'historia de construcción y arquitectura de la Plaza Mayor'. "
                            "Si el usuario pide más información sobre un tema ya tratado en el historial, "
                            "construye la query con el mismo tema para recuperar fragmentos distintos."
                        )
                    }
                },
                "required": ["nombre", "query"]
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


# Cliente httpx compartido: reutiliza conexiones (keep-alive) hacia Groq en vez
# de abrir y cerrar una nueva por cada petición. Se cierra en el shutdown de la
# app (ver lifespan en main.py -> cerrar_cliente).
_client: httpx.AsyncClient | None = None


def _get_client() -> httpx.AsyncClient:
    global _client
    if _client is None or _client.is_closed:
        _client = httpx.AsyncClient(timeout=60.0)
    return _client


async def cerrar_cliente() -> None:
    global _client
    if _client is not None and not _client.is_closed:
        await _client.aclose()
    _client = None


async def _llamar_llm(messages: list, tools: list | None = None, timeout: float = 60.0) -> dict:
    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {"model": MODEL, "messages": messages, "stream": False}
    if tools:
        payload["tools"] = tools
    res = await _get_client().post(GROQ_URL, headers=headers, json=payload, timeout=timeout)
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
