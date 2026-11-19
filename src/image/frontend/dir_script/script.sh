#!/bin/sh
set -e
exec npm run dev -- --host 0.0.0.0 --port "${FRONTEND_PORT:-5173}"