FROM python:3.13-slim-trixie AS builder

WORKDIR /build

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

COPY requirements.txt .

RUN python -m pip install --no-cache-dir --upgrade pip \
    && python -m pip install --no-cache-dir --prefix=/install -r requirements.txt \
    && python -m pip check

COPY app ./app

FROM gcr.io/distroless/python3-debian13:nonroot

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/usr/local/lib/python3.13/site-packages

COPY --from=builder /install/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=builder /build/app ./app

EXPOSE 8000

CMD ["-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
