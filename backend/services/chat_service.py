import ollama


DEFAULT_SYSTEM_PROMPT = """Eres un guía turístico experto en Salamanca. Responde siempre en español, de forma clara y amable. Si te preguntan algo que no tiene que ver con turismo o Salamanca, redirige amablemente la conversación hacia el turismo en Salamanca. Si te preguntan algo que no sabes, responde que no lo sabes, pero que puedes ayudar con información turística sobre Salamanca."""


def chat_simple(mensaje: str, system: str = "") -> str:
    system_prompt = system.strip() or DEFAULT_SYSTEM_PROMPT
    respuesta = ollama.chat(
        model="qwen2.5:3b",
        messages=[
            {
                "role": "system",
                "content": system_prompt,
            },
            {
                "role": "user",
                "content": mensaje,
            },
        ],
    )
    return respuesta["message"]["content"]
