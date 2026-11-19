#!/bin/sh
set -e

[ -n "$DJANGO_SECRET_KEY_FILE" ] && export DJANGO_SECRET_KEY="$(cat "$DJANGO_SECRET_KEY_FILE")"
[ -n "$POSTGRES_PASSWORD_FILE" ] && export POSTGRES_PASSWORD="$(cat "$POSTGRES_PASSWORD_FILE")"

echo ">> A aplicar migrações..."
python manage.py migrate --noinput

echo ">> A recolher ficheiros estáticos..."
python manage.py collectstatic --noinput || true

echo ">> A arrancar Gunicorn..."
exec gunicorn "${DJANGO_WSGI_MODULE:-config.wsgi:application}" \
  --bind 0.0.0.0:"${BACKEND_PORT:-8000}" \
  --workers 3