#! /usr/bin/bash

# environment variable used by Cloud Run etc.
APP_PORT=${PORT:-8000}

cd /app/
/opt/venv/bin/gunicorn src.main:app --worker-class uvicorn.workers.UvicornWorker --bind "0.0.0.0:${APP_PORT}"
