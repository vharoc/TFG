"""
Sube el catálogo de monumentos por ciudad a Firestore.

Estructura resultante:
    monumentos/{ciudadId}                 ← metadata de la ciudad
    monumentos/{ciudadId}/items/{poiId}   ← cada monumento

Lee todas las carpetas bajo backend/data/ciudades/ y para cada una carga el
fichero ciudad.json. Idempotente: usar `set()` con merge sobrescribe sin duplicar.

Uso:
    cd backend
    .\\venv\\Scripts\\activate
    python scripts/upload_monumentos.py
"""

import json
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

ROOT = Path(__file__).resolve().parent.parent
CRED_PATH = ROOT / "serviceTourClickFirebaseKey.json"
CIUDADES_DIR = ROOT / "data" / "ciudades"


def init_firestore():
    if not firebase_admin._apps:
        cred = credentials.Certificate(str(CRED_PATH))
        firebase_admin.initialize_app(cred)
    return firestore.client()


def subir_ciudad(db, ciudad_path: Path) -> tuple[str, int]:
    with ciudad_path.open(encoding="utf-8") as f:
        data = json.load(f)

    ciudad = data["ciudad"]
    monumentos = data.get("monumentos", [])
    ciudad_id = ciudad["id"]

    # Doc raíz con metadata de la ciudad (lat/lon/radio_km/nombre)
    db.collection("monumentos").document(ciudad_id).set(
        {
            "nombre": ciudad["nombre"],
            "lat": ciudad["lat"],
            "lon": ciudad["lon"],
            "radio_km": ciudad["radio_km"],
        },
        merge=True,
    )

    # Subcolección items con cada monumento
    items_ref = db.collection("monumentos").document(ciudad_id).collection("items")
    batch = db.batch()
    for m in monumentos:
        doc_ref = items_ref.document(m["id"])
        batch.set(
            doc_ref,
            {
                "nombre": m["nombre"],
                "descripcionCorta": m.get("descripcion_corta", ""),
                "lat": m["lat"],
                "lon": m["lon"],
                "alias": m.get("alias", []),
                "classifierClass": m.get("classifier_class", ""),
            },
            merge=True,
        )
    batch.commit()
    return ciudad_id, len(monumentos)


def main():
    db = init_firestore()
    if not CIUDADES_DIR.exists():
        raise SystemExit(f"No se encontró el directorio: {CIUDADES_DIR}")

    total = 0
    for ciudad_dir in sorted(CIUDADES_DIR.iterdir()):
        if not ciudad_dir.is_dir():
            continue
        ciudad_json = ciudad_dir / "ciudad.json"
        if not ciudad_json.exists():
            print(f"  · saltando {ciudad_dir.name} (no tiene ciudad.json)")
            continue
        ciudad_id, n = subir_ciudad(db, ciudad_json)
        print(f"  · {ciudad_id}: {n} monumentos subidos")
        total += n

    print(f"\nTotal: {total} monumentos en Firestore.")


if __name__ == "__main__":
    main()
