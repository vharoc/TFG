import logging
from pathlib import Path
from typing import Optional

from services.clasificador_service import ClasificadorService
from services.monumento_service import MonumentoService

logger = logging.getLogger(__name__)


class CiudadRegistry:
    """
    Registro de ciudades soportadas.
    Carga un MonumentoService por ciudad desde `data/ciudades/<id>/ciudad.json`.
    El extractor + clasificador es, en esta fase de transición, ÚNICO y global
    (un solo modelo en models/). Cuando existan cabezas sklearn por ciudad, basta
    con convertir `self._clasificador` en un dict {ciudad: cabeza} y seleccionar
    en `clasificar()` según el parámetro `ciudad`.
    """

    def __init__(self, ciudades_dir: str, clasificador: ClasificadorService, default: str = "salamanca"):
        self._clasificador = clasificador
        self.default = default
        self._monumentos: dict[str, MonumentoService] = {}
        self._alias_ciudad: dict[str, str] = {}  # nombre/id normalizado → id de ciudad

        base = Path(ciudades_dir)
        if base.exists():
            for sub in sorted(p for p in base.iterdir() if p.is_dir()):
                cj = sub / "ciudad.json"
                if not cj.exists():
                    continue
                try:
                    svc = MonumentoService(str(cj))
                except Exception as e:
                    logger.warning("No se pudo cargar la ciudad %s: %s", sub.name, e)
                    continue
                cid = (svc.ciudad or {}).get("id", sub.name)
                self._monumentos[cid] = svc
                self._alias_ciudad[cid.strip().lower()] = cid
                nombre = (svc.ciudad or {}).get("nombre")
                if nombre:
                    self._alias_ciudad[nombre.strip().lower()] = cid
                logger.info("Ciudad cargada: %s (%d monumentos)", cid, len(svc._data))

        if not self._monumentos:
            logger.warning("CiudadRegistry vacío: no hay ciudades en %s", ciudades_dir)
        elif self.default not in self._monumentos:
            self.default = next(iter(self._monumentos))

    def _resolve(self, ciudad: Optional[str]) -> Optional[str]:
        if ciudad:
            cid = self._alias_ciudad.get(ciudad.strip().lower())
            if cid:
                return cid
        return self.default if self._monumentos else None

    def monumentos(self, ciudad: Optional[str] = None) -> Optional[MonumentoService]:
        cid = self._resolve(ciudad)
        return self._monumentos.get(cid) if cid else None

    def clasificar(self, image_bytes: bytes, ciudad: Optional[str] = None) -> str:
        return self._clasificador.clasificar(image_bytes)

    def listar_ciudades(self) -> list[dict]:
        return [svc.ciudad for svc in self._monumentos.values() if svc.ciudad]
