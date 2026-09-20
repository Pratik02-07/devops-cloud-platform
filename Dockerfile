FROM python:3.11-slim-bookworm

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN useradd --create-home appuser

COPY requirements.txt .

RUN python -m pip uninstall -y setuptools wheel || true \
    && rm -rf \
       /usr/local/lib/python3.11/site-packages/setuptools* \
       /usr/local/lib/python3.11/site-packages/wheel* \
       /usr/lib/python3/dist-packages/setuptools* \
       /usr/lib/python3/dist-packages/wheel* \
    && python -m pip install --no-cache-dir --upgrade pip \
    && python -m pip install --no-cache-dir \
       "setuptools==84.0.0" \
       "wheel==0.48.0" \
    && python -m pip install --no-cache-dir -r requirements.txt \
    && python -m pip check \
    && python -c "import setuptools, wheel; assert setuptools.__version__ == '84.0.0'; assert wheel.__version__ == '0.48.0'; print('setuptools', setuptools.__version__); print('wheel', wheel.__version__)" \
    && if find /usr /opt -type d \( -name 'wheel-0.45.1.dist-info' -o -name 'wheel-0.45.1.egg-info' \) -print -quit 2>/dev/null | grep -q .; then echo 'ERROR: vulnerable wheel 0.45.1 metadata found in image'; exit 1; fi

COPY app ./app

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]