#!/bin/sh
set -e

SSL_DIR=/etc/nginx/ssl
DOMAIN="${DOMAIN_NAME}"

mkdir -p "$SSL_DIR"

# Só gera se ainda não existirem (podes colocar certificados teus na pasta)
if [ ! -s "$SSL_DIR/geoguess.crt" ] || [ ! -s "$SSL_DIR/geoguess.key" ]; then
    echo ">> A gerar certificado TLS autoassinado para ${DOMAIN}..."
    openssl req -x509 -nodes -newkey rsa:2048 -sha256 \
        -days "${CERT_DAYS:-365}" \
        -keyout "$SSL_DIR/geoguess.key" \
        -out "$SSL_DIR/geoguess.crt" \
        -subj "/C=AO/ST=Luanda/L=Luanda/O=42Luanda Angola/CN=${DOMAIN}" \
        -addext "subjectAltName=DNS:${DOMAIN},DNS:${DOMAIN_NAME},IP:127.0.0.1"
    chmod 600 "$SSL_DIR/geoguess.key"
    chmod 644 "$SSL_DIR/geoguess.crt"
fi

nginx -t
exec nginx -g 'daemon off;'