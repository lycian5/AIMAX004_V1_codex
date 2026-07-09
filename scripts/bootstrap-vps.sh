#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/coa-news}"
REPO_URL="${REPO_URL:-https://github.com/lycian5/AIMAX004_V1_codex.git}"
BRANCH="${BRANCH:-main}"
N8N_DIR="$APP_DIR/n8n"
ENV_FILE="$APP_DIR/.env"
SERVICE_FILE="/etc/systemd/system/coa-agent-reach-runner.service"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root: sudo bash scripts/bootstrap-vps.sh"
  exit 1
fi

log() {
  printf '\n[%s] %s\n' "$(date +%H:%M:%S)" "$*"
}

random_hex() {
  openssl rand -hex 32
}

public_ip() {
  curl -fsS https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}'
}

ensure_env_key() {
  local file="$1"
  local key="$2"
  local value="$3"
  grep -q "^${key}=" "$file" 2>/dev/null || printf '%s=%s\n' "$key" "$value" >> "$file"
}

log "Installing OS packages"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates curl git gnupg lsb-release openssl ufw fail2ban \
  python3 python3-venv python3-pip nodejs npm

if ! command -v docker >/dev/null 2>&1; then
  log "Installing Docker"
  curl -fsSL https://get.docker.com | sh
fi

if ! docker compose version >/dev/null 2>&1; then
  log "Docker Compose plugin is missing"
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  log "Installing GitHub CLI"
  mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
  chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y gh
fi

log "Configuring firewall"
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 5678/tcp
ufw --force enable

log "Preparing application directory: $APP_DIR"
mkdir -p "$APP_DIR"
if [[ -d "$APP_DIR/.git" ]]; then
  git -C "$APP_DIR" fetch origin "$BRANCH"
  git -C "$APP_DIR" checkout "$BRANCH"
  git -C "$APP_DIR" pull --ff-only origin "$BRANCH"
else
  git clone --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
fi

SERVER_IP="${SERVER_IP:-$(public_ip)}"
WEBHOOK_SECRET="${AGENT_REACH_WEBHOOK_SECRET:-$(random_hex)}"
N8N_PASSWORD_VALUE="${N8N_PASSWORD:-$(random_hex)}"

if [[ ! -f "$ENV_FILE" ]]; then
  log "Creating $ENV_FILE"
  cat > "$ENV_FILE" <<EOF
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
OPENAI_API_KEY=
NAVER_CLIENT_ID=
NAVER_CLIENT_SECRET=
SLACK_WEBHOOK_URL=
CRON_SECRET=$(random_hex)

SERVER_IP=$SERVER_IP
N8N_USER=admin
N8N_PASSWORD=$N8N_PASSWORD_VALUE
N8N_BIND_HOST=0.0.0.0
N8N_HOST=0.0.0.0
N8N_PROTOCOL=http
N8N_WEBHOOK_URL=http://$SERVER_IP:5678/
N8N_SECURE_COOKIE=false

AGENT_REACH_WEBHOOK_URL=http://$SERVER_IP:5678/webhook/agent-reach-collect
AGENT_REACH_WEBHOOK_SECRET=$WEBHOOK_SECRET
AGENT_REACH_RUNNER_SECRET=$WEBHOOK_SECRET
AGENT_REACH_RUNNER_HOST=0.0.0.0
AGENT_REACH_RUNNER_PORT=8787
AGENT_REACH_RUNNER_URL=http://host.docker.internal:8787/run
AGENT_REACH_SOURCES=exa,rss,youtube,github
AGENT_REACH_LIMIT_KEYWORDS=18
AGENT_REACH_EXA_RESULTS=5
AGENT_REACH_YOUTUBE_RESULTS=3
AGENT_REACH_GITHUB_RESULTS=5
AGENT_REACH_TIMEOUT_MS=45000
AGENT_REACH_JINA_ENRICH=false
AGENT_REACH_RSS_FEEDS=
EOF
else
  log "Keeping existing $ENV_FILE"
  ensure_env_key "$ENV_FILE" "SERVER_IP" "$SERVER_IP"
  ensure_env_key "$ENV_FILE" "N8N_USER" "admin"
  ensure_env_key "$ENV_FILE" "N8N_PASSWORD" "$N8N_PASSWORD_VALUE"
  ensure_env_key "$ENV_FILE" "N8N_BIND_HOST" "0.0.0.0"
  ensure_env_key "$ENV_FILE" "N8N_HOST" "0.0.0.0"
  ensure_env_key "$ENV_FILE" "N8N_PROTOCOL" "http"
  ensure_env_key "$ENV_FILE" "N8N_WEBHOOK_URL" "http://$SERVER_IP:5678/"
  ensure_env_key "$ENV_FILE" "N8N_SECURE_COOKIE" "false"
  ensure_env_key "$ENV_FILE" "AGENT_REACH_WEBHOOK_URL" "http://$SERVER_IP:5678/webhook/agent-reach-collect"
  ensure_env_key "$ENV_FILE" "AGENT_REACH_WEBHOOK_SECRET" "$WEBHOOK_SECRET"
  ensure_env_key "$ENV_FILE" "AGENT_REACH_RUNNER_SECRET" "$WEBHOOK_SECRET"
  ensure_env_key "$ENV_FILE" "AGENT_REACH_RUNNER_HOST" "0.0.0.0"
  ensure_env_key "$ENV_FILE" "AGENT_REACH_RUNNER_PORT" "8787"
  ensure_env_key "$ENV_FILE" "AGENT_REACH_RUNNER_URL" "http://host.docker.internal:8787/run"
  ensure_env_key "$ENV_FILE" "AGENT_REACH_SOURCES" "exa,rss,youtube,github"
  ensure_env_key "$ENV_FILE" "AGENT_REACH_LIMIT_KEYWORDS" "18"
  ensure_env_key "$ENV_FILE" "AGENT_REACH_EXA_RESULTS" "5"
  ensure_env_key "$ENV_FILE" "AGENT_REACH_YOUTUBE_RESULTS" "3"
  ensure_env_key "$ENV_FILE" "AGENT_REACH_GITHUB_RESULTS" "5"
  ensure_env_key "$ENV_FILE" "AGENT_REACH_TIMEOUT_MS" "45000"
  ensure_env_key "$ENV_FILE" "AGENT_REACH_JINA_ENRICH" "false"
fi

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

: "${N8N_USER:=admin}"
: "${N8N_PASSWORD:=$N8N_PASSWORD_VALUE}"

log "Installing Agent Reach"
python3 -m venv /root/.agent-reach-venv
/root/.agent-reach-venv/bin/python -m pip install --upgrade pip
/root/.agent-reach-venv/bin/python -m pip install "https://github.com/Panniantong/Agent-Reach/archive/main.zip"
export PATH="/root/.agent-reach-venv/bin:$PATH"
agent-reach install --env=auto || true
mcporter config add exa https://mcp.exa.ai/mcp || true

log "Installing Agent Reach runner systemd service"
NODE_BIN="$(command -v node)"
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=COA NEWS Agent Reach Runner
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR
EnvironmentFile=$ENV_FILE
Environment=PATH=/root/.agent-reach-venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=$NODE_BIN $APP_DIR/scripts/agent-reach-runner.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now coa-agent-reach-runner

log "Starting n8n with Docker Compose"
mkdir -p "$N8N_DIR/n8n-data"
docker compose --env-file "$ENV_FILE" -f "$N8N_DIR/docker-compose.yml" up -d

log "Smoke checks"
systemctl --no-pager --full status coa-agent-reach-runner || true
docker ps --filter name=coa-n8n
curl -fsS "http://127.0.0.1:8787/health" || true

cat <<EOF

Bootstrap complete.

n8n URL:
  http://$SERVER_IP:5678

n8n login:
  user: ${N8N_USER:-admin}
  password: $N8N_PASSWORD

Next required steps:
  1. Fill SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, OPENAI_API_KEY, NAVER keys, SLACK_WEBHOOK_URL in:
     $ENV_FILE
  2. Restart services:
     systemctl restart coa-agent-reach-runner
     docker compose --env-file "$ENV_FILE" -f "$N8N_DIR/docker-compose.yml" up -d
  3. Import n8n workflows from:
     $N8N_DIR/workflow_collect.json
     $N8N_DIR/workflow_agent_reach_collect.json
     $N8N_DIR/workflow_suggest.json
EOF
