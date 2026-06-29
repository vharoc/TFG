import logging
from fastapi import APIRouter, HTTPException, Request, UploadFile, File, Form
from fastapi.responses import JSONResponse
from fastapi.concurrency import run_in_threadpool
from .config import (
    _MODOS_VALIDOS, _MAX_PROMPT, _MAX_HISTORY, _MAX_IMAGEN_BYTES,
    _tokens_request, _con_tokens, limiter,
)
from .models import Query, RutaRequest
from .state import registry
from .chat import _query_rapido, _query_pensar_agente
from .geo import _ejecutar_generar_ruta, _narrar_resumen_ruta
from .llm import _reformatear

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/query")
@router.post("/api/query")
@limiter.limit("15/minute")
async def query(request: Request, q: Query):
    _tokens_request.set(0)
    if q.modo not in _MODOS_VALIDOS:
        raise HTTPException(status_code=422, detail="modo no válido: usa 'rapido' o 'pensar'")
    if len(q.prompt) > _MAX_PROMPT:
        raise HTTPException(status_code=422, detail=f"prompt demasiado largo (máx. {_MAX_PROMPT} caracteres)")
    if len(q.history) > _MAX_HISTORY:
        raise HTTPException(status_code=422, detail=f"historial demasiado largo (máx. {_MAX_HISTORY} mensajes)")

    mon = registry.monumentos(q.ciudad)

    if q.modo == "pensar":
        monumento_activo = mon.lookup_by_id(q.monumento_id) if (mon and q.monumento_id) else None
        try:
            return await _query_pensar_agente(q, mon, monumento_activo)
        except Exception as e:
            logger.error("Error en modo pensar: %s", e, exc_info=True)
            raise HTTPException(status_code=502, detail="No se pudo generar la respuesta. Intentalo de nuevo.")

    return await _query_rapido(q, mon)


@router.post("/ruta")
@router.post("/api/ruta")
@limiter.limit("10/minute")
async def ruta(request: Request, req: RutaRequest):
    _tokens_request.set(0)
    mon = registry.monumentos(req.ciudad)
    if mon is None:
        raise HTTPException(status_code=503, detail="Servicio de monumentos no disponible")
    resultado = _ejecutar_generar_ruta(mon, req.filtro, req.lat, req.lon, req.visitados)
    if "error" in resultado:
        return _con_tokens({"paradas": [], "tiempo_total_min": 0, "resumen": resultado["error"]})
    resumen = await _narrar_resumen_ruta(resultado["paradas"])
    return _con_tokens({
        "paradas": resultado["paradas"],
        "tiempo_total_min": resultado["tiempo_total_min"],
        "resumen": resumen,
    })


@router.post("/classify")
@router.post("/api/classify")
@limiter.limit("10/minute")
async def classify(request: Request, imagen: UploadFile = File(...), modo: str = Form("rapido"), ciudad: str = Form(None)):
    _tokens_request.set(0)
    if modo not in _MODOS_VALIDOS:
        raise HTTPException(status_code=422, detail="modo no válido: usa 'rapido' o 'pensar'")
    data = await imagen.read()
    if not data:
        raise HTTPException(status_code=400, detail="Imagen vacía")
    if len(data) > _MAX_IMAGEN_BYTES:
        raise HTTPException(status_code=413, detail="Imagen demasiado grande (máx. 5 MB)")
    try:
        clase = await run_in_threadpool(registry.clasificar, data, ciudad)
    except OSError:
        raise HTTPException(status_code=400, detail="Imagen corrupta o formato no soportado")
    mon = registry.monumentos(ciudad)

    if mon is None:
        return _con_tokens({"clase": clase, "nombre": clase, "descripcion_corta": None, "pois_cercanos": []})

    monumento = mon.lookup_by_class(clase)
    if monumento is None:
        return _con_tokens({"clase": clase, "nombre": clase, "descripcion_corta": None, "pois_cercanos": []})

    pois = mon.get_nearby(monumento["id"])
    descripcion = monumento["descripcion_corta"]

    if modo == "pensar" and descripcion:
        try:
            descripcion = await _reformatear(descripcion, f"Presentame {monumento['nombre']}")
        except Exception as e:
            logger.warning("Reformateo en classify fallo: %s", e)

    return _con_tokens({
        "clase": clase,
        "id": monumento["id"],
        "nombre": monumento["nombre"],
        "descripcion_corta": descripcion,
        "lat": monumento.get("lat"),
        "lon": monumento.get("lon"),
        "pois_cercanos": [{"id": p["id"], "nombre": p["nombre"]} for p in pois],
    })


@router.get("/monumentos")
@router.get("/api/monumentos")
async def listar_monumentos(ciudad: str = None):
    mon = registry.monumentos(ciudad)
    if mon is None:
        return JSONResponse(content={"monumentos": []})
    return JSONResponse(content={
        "monumentos": [{"id": m["id"], "nombre": m["nombre"]} for m in mon._data]
    })


@router.get("/ciudades")
@router.get("/api/ciudades")
async def listar_ciudades():
    return JSONResponse(content={"ciudades": registry.listar_ciudades()})


@router.get("/health")
@router.get("/api/health")
async def health():
    return JSONResponse(content={"status": "ok"})
