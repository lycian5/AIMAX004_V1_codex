#!/usr/bin/env bash
set -Eeuo pipefail

PUBLIC_KEY="${1:-}"
if [[ ! "$PUBLIC_KEY" =~ ^(ssh-ed25519|sk-ssh-ed25519@openssh.com)[[:space:]] ]]; then
  echo "Usage: $0 'ssh-ed25519 AAAA... nas-coa-backup'" >&2
  exit 1
fi

SSH_DIR="/home/coa-backup/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
install -d -m 0700 -o coa-backup -g coa-backup "$SSH_DIR"
printf 'restrict,command="/usr/bin/rrsync -ro /opt/backups/coa-n8n" %s\n' "$PUBLIC_KEY" > "$AUTHORIZED_KEYS"
chown coa-backup:coa-backup "$AUTHORIZED_KEYS"
chmod 0600 "$AUTHORIZED_KEYS"
echo "NAS backup public key installed with read-only rsync access."
