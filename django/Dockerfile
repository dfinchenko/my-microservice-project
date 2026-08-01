FROM python:3.12-slim

# Unbuffered output so pod logs appear immediately.
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    APP_PORT=8000

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
RUN chmod +x /app/entrypoint.sh

RUN useradd --uid 10001 --create-home --shell /usr/sbin/nologin django \
    && chown -R django:django /app
USER 10001

EXPOSE 8000

CMD ["/app/entrypoint.sh"]
