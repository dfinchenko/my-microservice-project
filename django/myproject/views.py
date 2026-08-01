import os
import socket
import time

from django.db import connection
from django.http import JsonResponse


def index(request):
    """Probe target. Deliberately does not touch the database, so a slow RDS
    does not pull healthy pods out of the Service.
    """
    return JsonResponse(
        {
            "status": "ok",
            "app": "django-app",
            "pod": socket.gethostname(),
            "version": os.environ.get("APP_VERSION", "dev"),
        }
    )


def healthz(request):
    """Deep check: runs a query, so unlike the probes it does report on RDS."""
    started = time.monotonic()

    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT version()")
            version = cursor.fetchone()[0]
        database = {
            "reachable": True,
            "server": version.split(",")[0],
            "host": connection.settings_dict.get("HOST"),
            "name": connection.settings_dict.get("NAME"),
        }
        status = 200
    except Exception as exc:  # noqa: BLE001 — the message is the whole point here
        database = {
            "reachable": False,
            "error": str(exc),
            "host": connection.settings_dict.get("HOST"),
        }
        status = 503

    return JsonResponse(
        {
            "status": "ok" if status == 200 else "degraded",
            "pod": socket.gethostname(),
            "database": database,
            "took_ms": round((time.monotonic() - started) * 1000, 1),
        },
        status=status,
    )


def load(request):
    """Keeps the CPU busy for a given number of milliseconds, so the HPA has
    something to react to during the demo.
    """
    try:
        duration_ms = min(int(request.GET.get("ms", "200")), 5000)
    except ValueError:
        duration_ms = 200

    deadline = time.monotonic() + duration_ms / 1000
    iterations = 0
    while time.monotonic() < deadline:
        iterations += 1
        sum(i * i for i in range(1000))

    return JsonResponse(
        {
            "status": "ok",
            "pod": socket.gethostname(),
            "burned_ms": duration_ms,
            "iterations": iterations,
        }
    )
