FROM python:3.11-slim-bookworm

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN useradd --create-home appuser

COPY requirements.txt .

RUN set -eux; \
    python -m pip uninstall -y setuptools wheel || true; \
    find /usr /opt -type d \
      \( \
        -name 'setuptools' \
        -o -name 'setuptools-*.dist-info' \
        -o -name 'setuptools-*.egg-info' \
        -o -name 'wheel' \
        -o -name 'wheel-*.dist-info' \
        -o -name 'wheel-*.egg-info' \
      \) \
      -prune -exec rm -rf {} +; \
    python -m pip install --no-cache-dir --upgrade pip; \
    python -m pip install --no-cache-dir \
      --ignore-installed \
      'setuptools==84.0.0' \
      'wheel==0.48.0'; \
    python -m pip install --no-cache-dir -r requirements.txt; \
    python -m pip check; \
    python -c "from importlib.metadata import version; \
      assert version('setuptools') == '84.0.0'; \
      assert version('wheel') == '0.48.0'; \
      print('setuptools', version('setuptools')); \
      print('wheel', version('wheel'))"; \
    if find /usr /opt -type d \
      \( \
        -name 'setuptools-70.3.0.dist-info' \
        -o -name 'setuptools-70.3.0.egg-info' \
        -o -name 'wheel-0.45.1.dist-info' \
        -o -name 'wheel-0.45.1.egg-info' \
      \) -print -quit 2>/dev/null | grep -q .; then \
      echo 'ERROR: vulnerable packaging metadata found in image'; \
      exit 1; \
    fi

COPY app ./app

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]