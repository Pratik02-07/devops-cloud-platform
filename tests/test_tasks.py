from fastapi import status
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_check():
    response = client.get("/health")

    assert response.status_code == status.HTTP_200_OK

    data = response.json()

    assert data["status"] == "healthy"
    assert data["service"] == "devops-cloud-platform"
