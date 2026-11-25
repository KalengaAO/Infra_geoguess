#!/bin/sh
set -e

BACKUP_DIR=/backups
INTERVAL_H="${BACKUP_INTERVAL_HOURS:-24}"
KEEP_DAYS="${BACKUP_RETENTION_DAYS:-7}"
PASS_FILE="${POSTGRES_PASSWORD_FILE:-/run/secrets/postgres_password}"

export PGPASSWORD="$(cat "$PASS_FILE")"
export PGHOST=postgres
export PGUSER="$POSTGRES_USER"
export PGDATABASE="$POSTGRES_DB"

mkdir -p "$BACKUP_DIR"

write_status() {  # $1=status $2=ficheiro
    printf '{"status":"%s","epoch":%s,"file":"%s"}\n' "$1" "$(date +%s)" "$2" \
        > "$BACKUP_DIR/last_backup.json"
}

do_backup() {
    ts="$(date +%Y%m%d_%H%M%S)"
    db="$BACKUP_DIR/db_${ts}.dump"
    media="$BACKUP_DIR/media_${ts}.tar.gz"
    
    echo ">> Backup $ts..."
    if pg_dump -Fc -f "$db.tmp" \
       && pg_restore --list "$db.tmp" > /dev/null \
       && tar -C /app --numeric-owner -czf "$media.tmp" media; then
        mv "$db.tmp" "$db"
        mv "$media.tmp" "$media"
        find "$BACKUP_DIR" -maxdepth 1 \( -name 'db_*.dump' -o -name 'media_*.tar.gz' \) \
             -mtime +"$KEEP_DAYS" -delete
        write_status ok "db_${ts}.dump"
        touch "$BACKUP_DIR/last_backup.ok"
        echo ">> Backup concluído: db_${ts}.dump"
    else
        rm -f "$db.tmp" "$media.tmp"
        write_status error "-"
        echo ">> ERRO no backup" >&2
        return 1
    fi
}

restore() {
    f="$1"
    if [ "$f" = "latest" ]; then
        f="$(ls -1 "$BACKUP_DIR"/db_*.dump 2>/dev/null | sort | tail -n 1 | xargs -r basename)"
    fi
    [ -n "$f" ] && [ -f "$BACKUP_DIR/$f" ] || { echo "Backup '$f' não encontrado"; exit 1; }

    echo ">> A restaurar a base de dados a partir de $f..."
    pg_restore --clean --if-exists --no-owner --no-privileges -d "$PGDATABASE" "$BACKUP_DIR/$f" || \
        echo ">> pg_restore terminou com avisos (verifica acima)"

    m="media_$(echo "$f" | sed 's/^db_//; s/\.dump$//').tar.gz"
    if [ -f "$BACKUP_DIR/$m" ]; then
        echo ">> A restaurar media a partir de $m..."
        find /app/media -mindepth 1 -delete
        tar -C /app --numeric-owner -xzf "$BACKUP_DIR/$m"
    fi
    echo ">> Restauro concluído."
}

case "${1:-daemon}" in
    daemon)
        trap 'exit 0' TERM INT
        until pg_isready -q; do sleep 3; done
        while true; do
            do_backup || true
            sleep $((INTERVAL_H * 3600)) &
            wait $!
        done
        ;;
    now)     do_backup ;;
    list)    ls -lh "$BACKUP_DIR" ;;
    restore) restore "${2:?Uso: restore <ficheiro.dump|latest>}" ;;
    *)       echo "Uso: script.sh [daemon|now|list|restore <ficheiro|latest>]"; exit 1 ;;
esac