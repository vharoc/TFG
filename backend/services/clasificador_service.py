import io
import numpy as np
import onnxruntime as ort
import joblib
from PIL import Image

_MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
_STD  = np.array([0.229, 0.224, 0.225], dtype=np.float32)

class ClasificadorService:
    def __init__(self, onnx_path: str, clf_path: str, classes_path: str):
        self.session     = ort.InferenceSession(onnx_path)
        self.clf         = joblib.load(clf_path)
        self.class_names = np.load(classes_path, allow_pickle=True)
        self.input_name  = self.session.get_inputs()[0].name
        self.output_name = self.session.get_outputs()[0].name

    def _preprocess(self, image_bytes: bytes) -> np.ndarray:
        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        img = img.resize((224, 224), Image.BILINEAR)
        arr = np.array(img, dtype=np.float32) / 255.0
        arr = (arr - _MEAN) / _STD
        arr = arr.transpose(2, 0, 1)
        return arr[np.newaxis]

    def clasificar(self, image_bytes: bytes) -> str:
        tensor   = self._preprocess(image_bytes)
        features = self.session.run([self.output_name], {self.input_name: tensor})[0]

        if features.ndim == 3:
            features = features[:, 0, :]  # CLS token

        pred = self.clf.predict(features)[0]

        if isinstance(pred, (int, np.integer)):
            return str(self.class_names[pred])
        return str(pred)