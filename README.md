![CI](https://github.com/Pratik02-07/devops-cloud-platform/actions/workflows/ci.yml/badge.svg)
# DevOps Cloud Platform

A cloud-native task management API designed as a practical DevOps portfolio project.

## Tech Stack

- Python
- FastAPI
- PostgreSQL
- SQLAlchemy
- Pytest

## Current Features

- Health check endpoint
- Create tasks
- List tasks
- Get task by ID
- Delete tasks
- Automated tests

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/api/tasks/` | Create task |
| GET | `/api/tasks/` | List tasks |
| GET | `/api/tasks/{id}` | Get task |
| DELETE | `/api/tasks/{id}` | Delete task |

## Run Locally

```bash
python3 -m venv venv
source venv/bin/activate

pip install -r requirements.txt

uvicorn app.main:app --reload