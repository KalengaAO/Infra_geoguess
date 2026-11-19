#!/bin/sh
set -e

CONF=/etc/postgresql/postgresql.conf
PASS_FILE="${POSTGRES_PASSWORD_FILE:-/run/secrets/postgres_password}"

: "${POSTGRES_USER:?POSTGRES_USER não definido}"
: "${POSTGRES_DB:?POSTGRES_DB não definido}"
[ -f "$PASS_FILE" ] || { echo "Secret $PASS_FILE não encontrado"; exit 1; }
DB_PASS="$(cat "$PASS_FILE")"

mkdir -p "$PGDATA" /var/run/postgresql
chown -R postgres:postgres "$PGDATA" /var/run/postgresql
chmod 700 "$PGDATA"

if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo ">> A inicializar o cluster..."
    gosu postgres initdb -D "$PGDATA" \
        --auth-local=peer --auth-host=scram-sha-256 --locale=C.UTF-8 --encoding=UTF8
    echo "host all all 0.0.0.0/0 scram-sha-256" >> "$PGDATA/pg_hba.conf"

    echo ">> A criar utilizador e base de dados..."
    gosu postgres pg_ctl -D "$PGDATA" -w start \
        -o "-c config_file=$CONF -c listen_addresses=''"

    gosu postgres psql -v ON_ERROR_STOP=1 -d postgres \
        -v pw="$DB_PASS" -v dbuser="$POSTGRES_USER" -v dbname="$POSTGRES_DB" <<'SQL'
CREATE USER :"dbuser" WITH PASSWORD :'pw';
CREATE DATABASE :"dbname" OWNER :"dbuser";
SQL

    gosu postgres pg_ctl -D "$PGDATA" -m fast -w stop
    echo ">> Inicialização concluída."
fi

exec gosu postgres postgres -D "$PGDATA" -c config_file="$CONF"