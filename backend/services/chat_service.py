import ollama


def chat_simple(mensaje:str):
    respuesta = ollama.chat(
        model="qwen2.5:3b",
        messages=[
            {
                "role": "system", 
                "content": """Eres un guía turístico experto en Salamanca. Responde siempre en español, de forma clara y amable. Si te preguntan algo que no tiene que ver con turismo o Salamanca, redirige amablemente la conversación hacia el turismo en Salamanca. Si te preguntan algo que no sabes, responde que no lo sabes, pero que puedes ayudar con información turística sobre Salamanca."""
            },
            {
                "role": "user", 
                "content": mensaje
            }
        ]
    )
    return respuesta["message"]["content"]