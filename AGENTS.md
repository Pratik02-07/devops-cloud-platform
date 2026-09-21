# Project Summary & Agent Guide: DevOps Cloud Platform

This document serves as an authoritative guide for AI coding agents and developers working on the **DevOps Cloud Platform** repository.

---

## 1. Project Overview

**DevOps Cloud Platform** is a production-grade, cloud-native task management REST API and infrastructure stack designed as an end-to-end DevOps demonstration project. 

It showcases modern DevOps best practices including:
- **Cloud-Native Application**: Python FastAPI backend with PostgreSQL / MySQL persistence and Prometheus instrumentation.
- **Infrastructure as Code (IaC)**: Modular Terraform managing AWS VPC, EKS (Kubernetes 1.31), ECR, and IAM with OIDC authentication.
- **GitOps Deployment**: Declarative Kubernetes manifests managed via Kustomize (`base` and `dev` overlay) and automatically deployed to EKS using ArgoCD.
- **Automated CI/CD Pipeline**: GitHub Actions pipeline covering code linting (Ruff), unit/integration testing (Pytest), container vulnerability scanning (Trivy), secure passwordless AWS image publishing (OIDC -> ECR), and automated GitOps manifest updates.
- **Observability & Autoscaling**: Horizontal Pod Autoscaler (HPA), Kubernetes ServiceMonitor for Prometheus Operator, and Grafana dashboard monitoring.

---

## 2. Technology Stack

| Domain | Technology / Tool | Purpose / Details |
| :--- | :--- | :--- |
| **Language & Runtime** | Python 3.11 | Application backend runtime |
| **Framework** | FastAPI | Async REST API framework |
| **ORM & Database** | SQLAlchemy, Pydantic v2, PyMySQL | Database layer, data validation, PostgreSQL/MySQL driver |
| **Testing & Linting** | Pytest, Ruff | Automated test execution and static code analysis |
| **Containerization** | Docker | Multi-stage production container build (`python:3.11-slim`) |
| **Infrastructure (IaC)**| Terraform (~> 5.0 provider) | Provisioning AWS VPC, EKS cluster, ECR repository, and IAM roles |
| **Cloud Provider** | AWS (AWS EKS, ECR, VPC, IAM, S3) | Cloud infrastructure hosting (`ap-south-1`) |
| **Orchestration** | Kubernetes 1.31, Kustomize | Container orchestration & environment manifest overlays |
| **GitOps Delivery** | ArgoCD | Automated continuous deployment syncing Git manifests to EKS |
| **CI/CD Automation** | GitHub Actions | Automated build, test, scan, push to ECR, and GitOps update |
| **Security Scanning** | Trivy | Vulnerability scanning for container images (fails on HIGH/CRITICAL) |
| **Authentication** | AWS OIDC | Keyless authentication for GitHub Actions to AWS IAM/ECR |
| **Observability** | Prometheus, Grafana | Prometheus metrics (`prometheus-fastapi-instrumentator`) & Grafana visualization |

---

## 3. Repository Architecture & Directory Structure

```
devops-cloud-platform/
├── .github/
│   └── workflows/
│       └── ci.yml             # Main CI/CD pipeline (Lint -> Test -> Docker -> Trivy -> ECR Push -> GitOps update)
├── app/                       # FastAPI Application Source Code
│   ├── routes/
│   │   └── tasks.py           # REST endpoints for Task CRUD operations
│   ├── database.py            # SQLAlchemy engine, session maker, and DB dependency injection
│   ├── main.py                # App entrypoint, health checks, Prometheus instrumentator setup
│   ├── models.py              # SQLAlchemy ORM database models (`Task`)
│   └── schemas.py             # Pydantic schemas for request/response serialization
├── argocd/                    # GitOps Configuration
│   └── application.yaml       # ArgoCD Application CRD manifest pointing to k8s/overlays/dev
├── Docs/                      # Visual documentation & screenshots (ArgoCD, CI, Grafana)
├── k8s/                       # Kubernetes Manifests & GitOps Overlays
│   ├── base/                  # Base Kubernetes resources (Deployment, Service, HPA, ServiceMonitor, Namespace)
│   └── overlays/
│       └── dev/               # Development overlay (Kustomization config updated automatically by CI)
├── terraform/                 # AWS Infrastructure as Code (IaC)
│   ├── vpc.tf                 # VPC, public/private subnets, NAT Gateway, Internet Gateway
│   ├── eks.tf                 # EKS Cluster definition & managed node group config
│   ├── ecr.tf                 # Private AWS ECR repository with scan-on-push enabled
│   ├── iam.tf                 # IAM roles, OIDC provider for GitHub Actions & IRSA
│   ├── locals.tf              # Common tagging and naming variables
│   ├── outputs.tf             # Key terraform outputs (ECR URL, EKS endpoint, OIDC ARN)
│   └── variables.tf           # Configurable input parameters
├── tests/                     # Automated Test Suite
│   └── test_tasks.py          # Pytest test cases for task API endpoints
├── Dockerfile                 # Multi-stage production container build definition
├── docker-compose.yml         # Local containerized environment setup
├── pyproject.toml             # Ruff and tool configuration settings
├── requirements.txt           # Production Python dependencies
└── requirements-dev.txt       # Development & testing Python dependencies
```

---

## 4. API Endpoints

| Method | Endpoint | Description | Query / Body Parameters |
| :--- | :--- | :--- | :--- |
| `GET` | `/health` | Application health check endpoint | None |
| `GET` | `/metrics` | Prometheus metrics endpoint | None |
| `POST` | `/api/tasks/` | Create a new task | `{ "title": string, "description": string, "completed": boolean }` |
| `GET` | `/api/tasks/` | List all tasks | None |
| `GET` | `/api/tasks/{id}` | Retrieve specific task by ID | Path parameter `id` (integer) |
| `DELETE` | `/api/tasks/{id}` | Delete task by ID | Path parameter `id` (integer) |

---

## 5. CI/CD & Deployment Workflow

The CI/CD pipeline defined in `.github/workflows/ci.yml` consists of 5 dependent jobs:

1. **`test`**: Spins up a MySQL database service container, installs dependencies, executes `ruff check .`, and runs `pytest -v`.
2. **`docker-build`**: Builds the Docker container image locally and verifies core Python library imports (`fastapi`, `uvicorn`, `sqlalchemy`, `pymysql`).
3. **`security-scan`**: Scans the compiled container image using **Trivy** for OS & library vulnerabilities. Pipeline fails if unfixed `HIGH` or `CRITICAL` issues are found.
4. **`push-to-ecr`** *(runs on push to `main`)*: Uses **AWS OIDC** to securely assume the GitHub Actions IAM role without hardcoded credentials, logins to Amazon ECR, and pushes the image tagged with `github.sha`.
5. **`update-gitops`** *(runs on push to `main`)*: Uses `kustomize edit set image` to update `k8s/overlays/dev/kustomization.yaml` with the new ECR image tag, then commits and pushes the updated manifest back to Git. **ArgoCD** detects this commit and continuously syncs the new deployment onto the EKS cluster.

---

## 6. Development & Agent Collaboration Guidelines

When modifying this repository, follow these conventions:

### Backend Development (`app/` & `tests/`)
- Always add unit/integration tests in `tests/` for new endpoints or logic modifications.
- Keep database models in `app/models.py` synchronized with Pydantic schemas in `app/schemas.py`.
- Ensure `ruff check .` passes without warnings before submitting code changes.
- Test locally using:
  ```bash
  uvicorn app.main:app --reload
  # or using docker-compose
  docker-compose up --build
  ```

### Infrastructure & Terraform (`terraform/`)
- Follow modular principles and avoid hardcoding environment-specific values.
- Declare common resource tags and naming standard in `locals.tf`.
- Never commit secret variables or `.tfstate` files. Use `terraform.tfvars.example` for reference.

### Kubernetes & GitOps (`k8s/` & `argocd/`)
- Place base resource definitions in `k8s/base/`.
- Place environment overrides in `k8s/overlays/<env>/`.
- Do not manually edit the image tag in `k8s/overlays/dev/kustomization.yaml` unless testing local overlay changes; the CI pipeline manages production/dev tags dynamically.

---

*This document is kept up to date for seamless agent-to-agent and human-to-agent collaboration.*
