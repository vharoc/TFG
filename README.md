# TourClick

App de turismo para ciudades españolas. De momento solo está Salamanca.

La idea es sencilla: te registras, eliges ciudad y hablas con Clicky, un guía
que va contándote cosas de los monumentos. Además reconoce monumentos a partir
de una foto, te arma rutas a pie y va guardando los sitios por los que ya has
pasado.

Este repo es mi Trabajo de Fin de Grado.

## Estructura

- `frontend/` — la app en Flutter (Android y web).
- `backend/` — servidor en FastAPI que lleva el chat, la búsqueda de
  información, la clasificación de imágenes y las rutas.

## Qué hay por debajo

- **Chat**: Groq con Llama 3.3 70B. Tiene dos modos. El rápido tira
  directamente de la información ya verificada del monumento y se salta el LLM
  cuando puede; el modo "pensar" deja que el modelo decida solo cuándo consultar
  la base de conocimiento o generar una ruta.
- **Reconocer monumentos**: DINOv2 para sacar el embedding de la foto y un
  clasificador de scikit-learn encima, con un umbral de confianza para descartar
  lo que no reconoce.
- **RAG**: ChromaDB con embeddings multilingües para recuperar la ficha del
  monumento.
- **Rutas**: vecino más cercano y luego 2-opt para ordenar las paradas.
- **Cuentas y datos**: Firebase (Auth + Firestore).

## Cómo levantarlo

### Backend

Desde `backend/`:

```bash
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Hace falta un `.env` con la clave de Groq:

```
GROQ_API_KEY=tu-clave
```

Los modelos de clasificación y la base de ChromaDB no están en el repo; viven
en el servidor.

### Frontend

Desde `frontend/`:

```bash
flutter pub get
flutter run
```

Por defecto apunta al backend desplegado. Si lo corres en local, cambia la URL:

```bash
flutter run --dart-define=OLLAMA_API_BASE_URL=http://localhost:8000/api
```
