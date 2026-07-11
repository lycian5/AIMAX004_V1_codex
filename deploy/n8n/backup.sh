#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

APP_DIR="/opt/n8n"
BACKUP_DIR="${BACKUP_DIR:-/opt/backups/coa-n8n}"
ENV_FILE="$APP_DIR/.env"
STAMP="$(date +%Y%m%d-%H%M%S)"
WORK_DIR="$(mktemp -d)"
PLAIN_ARCHIVE="$WORK_DIR/coa-n8n-$STAMP.tar.gz"
FINAL_ARCHIVE="$BACKUP_DIR/coa-n8n-$STAMP.tar.gz.enc"
N8N_STOPPED=0

env_value() {
  sed -n "s/^$1[[:space:]]*=[[:space:]]*//p" "$ENV_FILE" | tail -n 1 | tr -d '\r'
}

cleanup() {
  if [ "$N8N_STOPPED" -eq 1 ]; then
    docker compose -f "$APP_DIR/docker-compose.yml" --env-file "$ENV_FILE" start n8n >/dev/null || true
  fi
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

[ -f "$ENV_FILE" ] || { echo "Missing $ENV_FILE" >&2; exit 1; }
POSTGRES_USER="$(env_value POSTGRES_USER)"; POSTGRES_USER="${POSTGRES_USER:-n8n}"
POSTGRES_PASSWORD="$(env_value POSTGRES_PASSWORD)"
POSTGRES_DB="$(env_value POSTGRES_DB)"; POSTGRES_DB="${POSTGRES_DB:-n8n}"
BACKUP_ENCRYPTION_PASSWORD="$(env_value BACKUP_ENCRYPTION_PASSWORD)"
BACKUP_RETENTION_DAYS="$(env_value BACKUP_RETENTION_DAYS)"; BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
SUPABASE_DB_URL="$(env_value SUPABASE_DB_URL)"

[ -n "$POSTGRES_PASSWORD" ] || { echo "POSTGRES_PASSWORD is empty" >&2; exit 1; }
[ -n "$BACKUP_ENCRYPTION_PASSWORD" ] || { echo "BACKUP_ENCRYPTION_PASSWORD is empty" >&2; exit 1; }
mkdir -p "$BACKUP_DIR" "$WORK_DIR/payload"

echo "==> Dump n8n PostgreSQL"
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" coa-n8n-postgres \
  pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc > "$WORK_DIR/payload/postgres.dump"

echo "==> Snapshot n8n data volume"
docker compose -f "$APP_DIR/docker-compose.yml" --env-file "$ENV_FILE" stop n8n
N8N_STOPPED=1
docker run --rm -v coa_n8n_data:/data:ro -v "$WORK_DIR/payload:/backup" alpine:3.20 \
  tar -C /data -czf /backup/n8n-data.tar.gz .
docker compose -f "$APP_DIR/docker-compose.yml" --env-file "$ENV_FILE" start n8n
N8N_STOPPED=0

if [ -n "$SUPABASE_DB_URL" ]; then
  echo "==> Dump Supabase PostgreSQL"
  docker run --rm postgres:16 pg_dump "$SUPABASE_DB_URL" -Fc > "$WORK_DIR/payload/supabase.dump"
fi

cp "$APP_DIR/docker-compose.yml" "$APP_DIR/Caddyfile" "$APP_DIR/.env" "$WORK_DIR/payload/"
tar -C "$WORK_DIR/payload" -czf "$PLAIN_ARCHIVE" .
export BACKUP_ENCRYPTION_PASSWORD
openssl enc -aes-256-cbc -salt -pbkdf2 -iter 200000 \
  -in "$PLAIN_ARCHIVE" -out "$FINAL_ARCHIVE" -pass env:BACKUP_ENCRYPTION_PASSWORD
(cd "$BACKUP_DIR" && sha256sum "$(basename "$FINAL_ARCHIVE")" > "$(basename "$FINAL_ARCHIVE").sha256")
find "$BACKUP_DIR" -type f -name 'coa-n8n-*.tar.gz.enc*' -mtime "+$BACKUP_RETENTION_DAYS" -delete
echo "Backup created: $FINAL_ARCHIVE"
