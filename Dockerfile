FROM python:3.11-slim-bookworm

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN useradd --create-home appuser

COPY requirements.txt .

RUN set -eux; \
    python -m pip install --no-cache-dir --upgrade pip; \
    python -m pip install --no-cache-dir -r requirements.txt; \
    python -m pip check; \
    python -m pip uninstall -y setuptools wheel msgpack || true; \
    find /usr /opt -type d \
      \( \
        -name 'setuptools' \
        -o -name 'setuptools-*.dist-info' \
        -o -name 'setuptools-*.egg-info' \
        -o -name 'wheel' \
        -o -name 'wheel-*.dist-info' \
        -o -name 'wheel-*.egg-info' \
        -o -name 'msgpack' \
        -o -name 'msgpack-*.dist-info' \
        -o -name 'msgpack-*.egg-info' \
      \) \
      -prune -exec rm -rf {} +; \
    if find /usr /opt -type d \
      \( \
        -iname 'setuptools-*dist-info' \
        -o -iname 'setuptools-*egg-info' \
        -o -iname 'wheel-*dist-info' \
        -o -iname 'wheel-*egg-info' \
        -iname 'msgpack-*dist-info' \
        -iname 'msgpack-*egg-info' \
      \) -print -quit 2>/dev/null | grep -q .; then \
      echo 'ERROR: stale packaging or msgpack metadata remains in runtime image'; \
      exit 1; \
    fi

COPY app ./app

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]