#!/bin/sh
# Migrations run on every pod start. Django locks django_migrations, so replicas
# starting at once are safe — the second one finds nothing left to apply.
set -e

echo "Waiting for ${POSTGRES_HOST:-db}:${POSTGRES_PORT:-5432} ..."
for attempt in $(seq 1 30); do
  if python - <<'PY'
import os
import socket
import sys

host = os.environ.get("POSTGRES_HOST", "db")
port = int(os.environ.get("POSTGRES_PORT", "5432"))
try:
    with socket.create_connection((host, port), timeout=3):
        pass
except OSError:
    sys.exit(1)
PY
  then
    echo "Database is reachable."
    break
  fi
  echo "  attempt ${attempt}/30 — not up yet, retrying in 5s"
  sleep 5
done

python manage.py migrate --noinput

# One worker, many threads: prometheus_client keeps counters in process memory,
# so extra workers would make each scrape hit a different set. Scaling out is the
# HPA's job.
exec gunicorn myproject.wsgi:application \
  --bind "0.0.0.0:${APP_PORT:-8000}" \
  --workers "${GUNICORN_WORKERS:-1}" \
  --threads "${GUNICORN_THREADS:-8}" \
  --access-logfile - \
  --error-logfile -
