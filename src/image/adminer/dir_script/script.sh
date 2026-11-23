#!/bin/sh
set -e
exec tini php -S 0.0.0.0:"${ADMINER_PORT:-8080}" -t /var/www/html