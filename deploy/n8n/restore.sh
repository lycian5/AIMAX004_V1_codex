#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

APP_DIR="/opt/n8n"
ENV_FILE="$APP_DIR/.env"
ARCHIVE="${1:-}"
CONFIRM="${2:-}"

if [ -z "$ARCHIVE" ] || [ "$CONFIRM" != "RESTORE" ]; then
  echo "Usage: $0 /opt/backups/coa-n8n/coa-n8n-YYYYMMDD-HHMMSS.tar.gz.enc RESTORE" >&2
  exit 1
fi
[ -f "$ARCHIVE" ] || { echo "Archive not found: $ARCHIVE" >&2; exit 1; }

env_value() {
  sed -n "s/^$1[[:space:]]*=[[:space:]]*//p" "$ENV_FILE" | tail -n 1 | tr -d '\r'
}

POSTGRES_USER="$(env_value POSTGRES_USER)"; POSTGRES_USER="${POSTGRES_USER:-n8n}"
POSTGRES_PASSWORD="$(env_value POSTGRES_PASSWORD)"
POSTGRES_DB="$(env_value POSTGRES_DB)"; POSTGRES_DB="${POSTGRES_DB:-n8n}"
BACKUP_ENCRYPTION_PASSWORD="$(env_value BACKUP_ENCRYPTION_PASSWORD)"
[ -n "$BACKUP_ENCRYPTION_PASSWORD" ] || { echo "BACKUP_ENCRYPTION_PASSWORD is empty" >&2; exit 1; }

echo "==> Create a safety backup before restore"
"$APP_DIR/backup.sh"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
export BACKUP_ENCRYPTION_PASSWORD
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \
  -in "$ARCHIVE" -out "$WORK_DIR/backup.tar.gz" -pass env:BACKUP_ENCRYPTION_PASSWORD
mkdir "$WORK_DIR/payload"
tar -C "$WORK_DIR/payload" -xzf "$WORK_DIR/backup.tar.gz"

docker compose -f "$APP_DIR/docker-compose.yml" --env-file "$ENV_FILE" stop n8n
docker run --rm -v coa_n8n_data:/data -v "$WORK_DIR/payload:/backup:ro" alpine:3.20 \
  sh -c 'find /data -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + && tar -C /data -xzf /backup/n8n-data.tar.gz'
docker exec -i -e PGPASSWORD="$POSTGRES_PASSWORD" coa-n8n-postgres \
  pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists --no-owner < "$WORK_DIR/payload/postgres.dump"
docker compose -f "$APP_DIR/docker-compose.yml" --env-file "$ENV_FILE" start n8n
echo "Restore completed. Check: docker compose -f $APP_DIR/docker-compose.yml ps"
