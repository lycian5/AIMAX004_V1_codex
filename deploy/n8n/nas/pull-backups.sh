#!/bin/sh
set -eu
umask 077

VPS_HOST="${VPS_HOST:-158.247.245.66}"
VPS_USER="${VPS_USER:-coa-backup}"
VPS_PORT="${VPS_PORT:-22}"
SSH_KEY="${SSH_KEY:-/volume1/backup/coa-n8n/keys/vps-backup}"
REMOTE_DIR="${REMOTE_DIR:-.}"
LOCAL_DIR="${LOCAL_DIR:-/volume1/backup/coa-n8n/vps}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

mkdir -p "$LOCAL_DIR"
rsync -av --ignore-existing --partial \
  -e "ssh -p $VPS_PORT -i $SSH_KEY -o BatchMode=yes -o StrictHostKeyChecking=yes" \
  "$VPS_USER@$VPS_HOST:$REMOTE_DIR/" "$LOCAL_DIR/"

cd "$LOCAL_DIR"
for checksum in *.sha256; do
  [ -f "$checksum" ] || continue
  sha256sum -c "$checksum"
done
find "$LOCAL_DIR" -type f -name 'coa-n8n-*.tar.gz.enc*' -mtime "+$RETENTION_DAYS" -delete
echo "NAS backup pull completed: $LOCAL_DIR"
