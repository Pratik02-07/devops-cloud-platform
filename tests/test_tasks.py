import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.main import app

SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)


@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "service": "devops-cloud-platform"}


def test_create_task():
    response = client.post(
        "/tasks/",
        json={"title": "Test Task", "description": "Test Description", "completed": False},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Test Task"
    assert data["description"] == "Test Description"
    assert data["completed"] is False
    assert "id" in data


def test_get_tasks():
    client.post("/tasks/", json={"title": "Task 1"})
    client.post("/tasks/", json={"title": "Task 2"})

    response = client.get("/tasks/")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2


def test_get_task_by_id():
    res = client.post("/tasks/", json={"title": "Task 1", "description": "Desc 1"})
    task_id = res.json()["id"]

    response = client.get(f"/tasks/{task_id}")
    assert response.status_code == 200
    assert response.json()["title"] == "Task 1"


def test_update_task():
    res = client.post("/tasks/", json={"title": "Task 1", "completed": False})
    task_id = res.json()["id"]

    response = client.put(f"/tasks/{task_id}", json={"completed": True})
    assert response.status_code == 200
    assert response.json()["completed"] is True


def test_delete_task():
    res = client.post("/tasks/", json={"title": "Task 1"})
    task_id = res.json()["id"]

    del_res = client.delete(f"/tasks/{task_id}")
    assert del_res.status_code == 204

    get_res = client.get(f"/tasks/{task_id}")
    assert get_res.status_code == 404
