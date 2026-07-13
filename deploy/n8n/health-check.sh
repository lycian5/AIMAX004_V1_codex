#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="/opt/n8n"
BACKUP_DIR="${BACKUP_DIR:-/opt/backups/coa-n8n}"
ENV_FILE="$APP_DIR/.env"
failures=()

env_value() {
  sed -n "s/^$1[[:space:]]*=[[:space:]]*//p" "$ENV_FILE" | tail -n 1 | tr -d '\r'
}

docker inspect -f '{{.State.Health.Status}}' coa-n8n 2>/dev/null | grep -qx healthy || failures+=("n8n container unhealthy")
docker inspect -f '{{.State.Health.Status}}' coa-n8n-postgres 2>/dev/null | grep -qx healthy || failures+=("postgres container unhealthy")
systemctl is-active --quiet coa-agent-reach-runner || failures+=("Agent Reach runner inactive")
curl -fsS --max-time 15 https://n8n.coanews.co.kr/healthz >/dev/null || failures+=("n8n HTTPS health check failed")

latest_backup="$(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'coa-n8n-*.tar.gz.enc' -printf '%T@\n' 2>/dev/null | sort -n | tail -n 1)"
now="$(date +%s)"
if [ -z "$latest_backup" ] || [ $((now - ${latest_backup%.*})) -gt 129600 ]; then
  failures+=("encrypted backup missing or older than 36 hours")
fi

if [ "${#failures[@]}" -eq 0 ]; then
  echo "COA NEWS ops health: OK"
  exit 0
fi

message="COA NEWS VPS 장애 감지: $(IFS='; '; echo "${failures[*]}")"
echo "$message" >&2
webhook="$(env_value SLACK_WEBHOOK_URL)"
if [ -n "$webhook" ]; then
  payload="$(python3 -c 'import json,sys; print(json.dumps({"text":sys.argv[1]}))' "$message")"
  curl -fsS --max-time 15 -H 'Content-Type: application/json' --data "$payload" "$webhook" >/dev/null || true
fi
exit 1
