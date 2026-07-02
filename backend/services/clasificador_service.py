import io
import json
import numpy as np
import onnxruntime as ort
import joblib
from PIL import Image
from sklearn.preprocessing import normalize

_MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
_STD  = np.array([0.229, 0.224, 0.225], dtype=np.float32)

class ClasificadorService:
    def __init__(self, onnx_path: str, clf_path: str, classes_path: str, meta_path: str):
        self.session     = ort.InferenceSession(onnx_path)
        self.clf         = joblib.load(clf_path)
        self.class_names = np.load(classes_path, allow_pickle=True)
        self.input_name  = self.session.get_inputs()[0].name
        self.output_name = self.session.get_outputs()[0].name

        with open(meta_path) as f:
            meta = json.load(f)
        self.umbral = meta["umbral_confianza"]

    def _preprocess(self, image_bytes: bytes) -> np.ndarray:
        # mismo preprocesado que en entrenamiento: lado corto a 256 (BICUBIC) y center crop 224x224
        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")

        short_edge, crop = 256, 224
        w, h = img.size
        if w <= h:
            new_w = short_edge
            new_h = max(crop, round(h * short_edge / w))
        else:
            new_h = short_edge
            new_w = max(crop, round(w * short_edge / h))
        img = img.resize((new_w, new_h), Image.BICUBIC)

        left = (new_w - crop) // 2
        top = (new_h - crop) // 2
        img = img.crop((left, top, left + crop, top + crop))

        arr = np.array(img, dtype=np.float32) / 255.0
        arr = (arr - _MEAN) / _STD
        arr = arr.transpose(2, 0, 1)
        return arr[np.newaxis]

    def clasificar(self, image_bytes: bytes) -> str:
        tensor   = self._preprocess(image_bytes)
        features = self.session.run([self.output_name], {self.input_name: tensor})[0]
        if features.ndim == 3:
            features = features[:, 0, :]  # CLS token

        features_norm = normalize(features, norm="l2")
        proba  = self.clf.predict_proba(features_norm)[0]
        idx    = np.argmax(proba)
        if proba[idx] < self.umbral:
            return "DESCONOCIDO"
        return str(self.class_names[idx])
