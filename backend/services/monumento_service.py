import json
import math
from pathlib import Path
from typing import Optional


class MonumentoService:
    def __init__(self, json_path: str, vecinos: int = 3):
        self._data: list[dict] = json.loads(Path(json_path).read_text(encoding="utf-8"))
        self._by_class: dict[str, dict] = {
            m["classifier_class"].strip().upper(): m for m in self._data
        }
        self._grafo: dict[str, list[dict]] = self._build_graph(vecinos)

    def lookup_by_class(self, class_name: str) -> Optional[dict]:
        return self._by_class.get(class_name.strip().upper())

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
