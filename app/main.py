from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

from app.routes.tasks import router as tasks_router

app = FastAPI(
    title="DevOps Cloud Platform",
    description="Cloud-native task management API",
    version="1.0.0"
)

app.include_router(tasks_router)


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "devops-cloud-platform"
    }


Instrumentator().instrument(app).expose(app)
