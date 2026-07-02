import json
import math
import unicodedata
from pathlib import Path
from typing import Optional


class MonumentoService:
    def __init__(self, json_path: str, vecinos: int = 3):
        raw = json.loads(Path(json_path).read_text(encoding="utf-8"))
        # Acepta dos formatos:
        #  - nuevo:   {"ciudad": {...geo...}, "monumentos": [...]}
        #  - legacy:  [ ...monumentos... ]   (sin geo de ciudad)
        if isinstance(raw, dict):
            self.ciudad: Optional[dict] = raw.get("ciudad")
            self._data: list[dict] = raw.get("monumentos", [])
        else:
            self.ciudad = None
            self._data = raw

        self._by_class: dict[str, dict] = {
            self._normalizar(m["classifier_class"]): m for m in self._data
        }
        self._by_id: dict[str, dict] = {m["id"]: m for m in self._data}
        self._by_alias: dict[str, dict] = {}
        for m in self._data:
            for a in m.get("alias", []):
                key = self._normalizar(a)
                if key not in self._by_alias:
                    self._by_alias[key] = m
        self._grafo: dict[str, list[dict]] = self._build_graph(vecinos)

    def lookup_by_id(self, monument_id: str) -> Optional[dict]:
        return self._by_id.get(monument_id)

    def lookup_by_class(self, class_name: str) -> Optional[dict]:
        return self._by_class.get(self._normalizar(class_name))

    def detectar_en_texto(self, texto: str) -> Optional[dict]:
        """Devuelve el primer monumento cuyo alias o clase aparece en texto."""
        texto_norm = self._normalizar(texto)
        # Aliases de mayor a menor longitud para preferir coincidencias específicas
        for alias_norm in sorted(self._by_alias, key=len, reverse=True):
            if alias_norm in texto_norm:
                return self._by_alias[alias_norm]
        for class_norm, monumento in self._by_class.items():
            if class_norm in texto_norm:
                return monumento
        return None

    @staticmethod
    def _normalizar(s: str) -> str:
        return unicodedata.normalize("NFC", s).strip().upper()

    def get_nearby(self, monument_id: str) -> list[dict]:
        return self._grafo.get(monument_id, [])

    def _build_graph(self, n: int) -> dict[str, list[dict]]:
        grafo: dict[str, list[dict]] = {}
        for m in self._data:
            distancias = [
                {
                    "id": other["id"],
                    "nombre": other["nombre"],
                    "distancia_m": round(
                        self._haversine(m["lat"], m["lon"], other["lat"], other["lon"]) * 1000
                    ),
                }
                for other in self._data
                if other["id"] != m["id"]
            ]
            distancias.sort(key=lambda x: x["distancia_m"])
            grafo[m["id"]] = distancias[:n]
        return grafo

    @staticmethod
    def _haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        R = 6371.0
        phi1, phi2 = math.radians(lat1), math.radians(lat2)
        dphi = math.radians(lat2 - lat1)
        dlambda = math.radians(lon2 - lon1)
        a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
        return 2 * R * math.asin(math.sqrt(a))
