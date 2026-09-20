from fastapi import FastAPI

from app.database import Base, engine
from app.routes.tasks import router as tasks_router

Base.metadata.create_all(bind=engine)

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