from fastapi import FastAPI
from routers.chat import router

app = FastAPI(title="TourClick API", version="1.0.0")

app.include_router(router, prefix="/api")