import logging
from sentence_transformers import SentenceTransformer
import chromadb

logger = logging.getLogger(__name__)

_model: SentenceTransformer | None = None
_collection = None


def inicializar_rag(chroma_path: str = "./chroma_db") -> None:
    global _model, _collection
    logger.info("RAG: cargando sentence-transformers...")
    _model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
    logger.info("RAG: conectando a ChromaDB en %s", chroma_path)
    client = chromadb.PersistentClient(path=chroma_path)
    _collection = client.get_collection("monumentos_salamanca")
    logger.info("RAG listo — %d chunks indexados", _collection.count())


def consultar_rag(pregunta: str, monumento: str, n_resultados: int = 3) -> list[dict]:
    if _model is None or _collection is None:
        return []
    embedding = _model.encode([pregunta])[0].tolist()
    results = _collection.query(
        query_embeddings=[embedding],
        n_results=n_resultados,
        where={"monumento": monumento},
        include=["documents", "metadatas", "distances"],
    )
    chunks = []
    for i, doc in enumerate(results["documents"][0]):
        similitud = round(1 - results["distances"][0][i], 4)
        chunks.append({
            "texto": doc,
            "monumento": results["metadatas"][0][i]["monumento"],
            "similitud": similitud,
        })
    return chunks
