from services.clasificador_service import ClasificadorService
from services.ciudad_registry import CiudadRegistry

clasificador = ClasificadorService(
    onnx_path="models/dinov2_small_full.onnx",
    clf_path="models/clasificador_tourclick_final.pkl",
    classes_path="models/class_names.npy",
    meta_path="models/meta_tourclick.json",
)

registry = CiudadRegistry("data/ciudades", clasificador, default="salamanca")
