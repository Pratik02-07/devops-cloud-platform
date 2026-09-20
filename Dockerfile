FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN useradd --create-home appuser

COPY requirements.txt .

RUN python -m pip install --no-cache-dir --upgrade pip \
    && pip uninstall -y setuptools wheel 2>/dev/null || true \
    && rm -rf \
       /usr/local/lib/python3.11/site-packages/setuptools* \
       /usr/local/lib/python3.11/site-packages/wheel* \
       /usr/lib/python3/dist-packages/setuptools* \
       /usr/lib/python3/dist-packages/wheel* \
    && python -m pip install --no-cache-dir -r requirements.txt \
    && python -m pip check

COPY app ./app

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]