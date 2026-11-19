#!/bin/sh
set -e
mkdir -p /var/lib/redis && chown redis:redis /var/lib/redis
exec gosu redis redis-server \
  --port "${REDIS_PORT:-6379}" \
  --bind 0.0.0.0 \
  --protected-mode no \
  --dir /var/lib/redis \
  --save "" \
  --appendonly no \
  --daemonize no