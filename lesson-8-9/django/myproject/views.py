import socket

from django.http import JsonResponse


def index(request):
    """Root endpoint, also used as the readiness/liveness probe target.

    Does not touch the database, so a slow Postgres does not pull healthy pods
    out of the Service. Returns the hostname (pod name) to show which replica
    answered.
    """
    return JsonResponse(
        {
            "status": "ok",
            "app": "django-app",
            "pod": socket.gethostname(),
        }
    )
