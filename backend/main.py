from fastapi import FastAPI

app = FastAPI(title="api", version="1.0.0")

@app.get("/")
def root():
    return {"status": "ok", "message": "Hello World"}