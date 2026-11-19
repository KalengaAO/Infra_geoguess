#!/bin/sh
set -e

[ -n "$POSTGRES_PASSWORD_FILE" ] && export POSTGRES_PASSWORD="$(cat "$POSTGRES_PASSWORD_FILE")"

echo ">> A aplicar migrações..."
python manage.py migrate --noinput


if [ "$(id -u)" = "0" ]; then
    mkdir -p /app/staticfiles /app/media
    chown -R appuser:appuser /app/staticfiles /app/media
    exec gosu appuser "$0" "$@"
fi

echo ">> A aguardar o Postgres..."
until python -c "import socket; s=socket.socket(); s.settimeout(2); s.connect(('${POSTGRES_HOST:-postgres}', 5432))" 2>/dev/null; do
    sleep 2
done

echo ">> A recolher ficheiros estáticos..."
python manage.py collectstatic --noinput || true

echo ">> A arrancar Gunicorn..."
exec gunicorn "${DJANGO_WSGI_MODULE:-config.wsgi:application}" \
  --bind 0.0.0.0:"${BACKEND_PORT:-8000}" \
  --workers 3