FROM python:3.11-slim-bookworm

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN useradd --create-home appuser

COPY requirements.txt .

RUN python -m pip uninstall -y setuptools || true \
    && rm -rf \
       /usr/local/lib/python3.11/site-packages/setuptools* \
       /usr/lib/python3/dist-packages/setuptools* \
    && python -m pip install --no-cache-dir --upgrade pip \
    && python -m pip install --no-cache-dir \
       "setuptools==78.1.1" \
       "wheel==0.46.2" \
    && python -m pip install --no-cache-dir -r requirements.txt \
    && python -m pip check \
    && python -c "import setuptools, wheel; assert setuptools.__version__ == '78.1.1'; assert wheel.__version__ == '0.46.2'; print('setuptools', setuptools.__version__); print('wheel', wheel.__version__)"

COPY app ./app

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]