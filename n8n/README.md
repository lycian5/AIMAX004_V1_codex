# COA NEWS — n8n VPS 운영 가이드

> **중요:** 이 문서는 초기 설계 기록입니다. 실제 배포에는 `deploy/n8n/README.md`와 `deploy/n8n/deploy.ps1`만 사용하십시오. 구형 bootstrap은 비활성화되었으며 n8n 5678 포트를 외부에 열면 안 됩니다.

> **Hetzner CAX11** (ARM64 · 2 vCPU · 4 GB RAM · 40 GB SSD · €3.79/월)
> Docker + n8n + Supabase + Claude/OpenAI 파이프라인

---

## 1. Hetzner 서버 생성

### 1-1. Hetzner Cloud Console

1. https://console.hetzner.cloud 접속 → 회원가입/로그인
2. **New Project** 생성 (예: `coa-news`)
3. **Add Server** 클릭

### 1-2. 서버 설정

| 항목 | 설정값 |
|---|---|
| Location | Helsinki (eu-central) 또는 Ashburn (us-east) |
| Image | **Ubuntu 24.04** |
| Type | **CAX11** (Shared vCPU, ARM64) |
| Networking | Public IPv4 ✅, Public IPv6 ✅ |
| SSH Keys | 본인 SSH 공개키 등록 (필수) |
| Name | `coa-news-n8n` |

> 💡 **SSH 키가 없다면**: 로컬 PC에서 `ssh-keygen -t ed25519` 실행 후
> `~/.ssh/id_ed25519.pub` 내용을 Hetzner에 등록

### 1-3. 서버 생성 완료 후

서버 IP 주소를 메모합니다 (예: `65.21.xxx.xxx`)

---

## 2. 서버 초기 설정

### 2-1. SSH 접속

```bash
ssh root@<서버IP>
```

### 2-2. 시스템 업데이트 + 기본 패키지

```bash
apt update && apt upgrade -y
apt install -y curl wget git ufw fail2ban
```

### 2-3. 방화벽 설정

```bash
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 5678/tcp  # n8n (초기 설정용, 나중에 닫을 수 있음)
ufw enable
```

### 2-4. (선택) 일반 사용자 생성

```bash
adduser coa
usermod -aG sudo coa
cp -r ~/.ssh /home/coa/.ssh
chown -R coa:coa /home/coa/.ssh

# 이후 coa 유저로 접속
# ssh coa@<서버IP>
```

---

## 3. Docker 설치

```bash
# Docker 공식 설치 스크립트 (ARM64 지원)
curl -fsSL https://get.docker.com | sh

# docker-compose 플러그인 확인
docker compose version

# Docker를 sudo 없이 사용 (선택)
sudo usermod -aG docker $USER
# 재로그인 필요
```

---

## 4. n8n 설치 (Docker Compose)

### 4-1. 디렉토리 생성

```bash
mkdir -p /opt/coa-news/n8n-data
cd /opt/coa-news
```

### 4-2. docker-compose.yml 작성

```bash
cat > docker-compose.yml << 'EOF'
version: "3.8"

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: coa-n8n
    restart: always
    ports:
      - "5678:5678"
    environment:
      # ── 기본 설정 ──
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://${SERVER_IP}:5678/
      - GENERIC_TIMEZONE=Asia/Seoul
      - TZ=Asia/Seoul

      # ── 보안 ──
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}

      # ── 실행 설정 ──
      - EXECUTIONS_DATA_SAVE_ON_ERROR=all
      - EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
      - EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true
      - N8N_DIAGNOSTICS_ENABLED=false
      - N8N_HIRING_BANNER_ENABLED=false

    volumes:
      - ./n8n-data:/home/node/.n8n
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF
```

### 4-3. 환경변수 파일 생성

```bash
cat > .env << 'EOF'
# ── 서버 ──
SERVER_IP=여기에_서버_IP_입력

# ── n8n 로그인 ──
N8N_USER=admin
N8N_PASSWORD=여기에_강력한_비밀번호_입력

# ── API Keys (n8n Credentials에서 사용) ──
# 아래 값들은 n8n UI의 Credentials에서 직접 설정합니다.
# 여기에는 참고용으로만 기록합니다.
# SUPABASE_URL=https://xxxxxxxx.supabase.co
# SUPABASE_SERVICE_ROLE_KEY=eyJ...
# NAVER_CLIENT_ID=
# NAVER_CLIENT_SECRET=
# OPENAI_API_KEY=sk-...
# ANTHROPIC_API_KEY=sk-ant-...
# SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
EOF
```

### 4-4. n8n 실행

```bash
docker compose up -d

# 로그 확인
docker compose logs -f n8n

# 상태 확인
docker ps
```

### 4-5. 접속 확인

브라우저에서 `http://<서버IP>:5678` 접속
→ 설정한 아이디/비밀번호로 로그인

---

## 5. (선택) Caddy로 HTTPS 설정

도메인이 있다면 Caddy 리버스 프록시로 HTTPS를 자동 설정할 수 있습니다.

### 5-1. docker-compose.yml에 Caddy 추가

```yaml
  caddy:
    image: caddy:2-alpine
    container_name: coa-caddy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config

volumes:
  caddy_data:
  caddy_config:
```

### 5-2. Caddyfile 작성

```bash
cat > Caddyfile << 'EOF'
n8n.yourdomain.com {
    reverse_proxy n8n:5678
}
EOF
```

이 경우 n8n의 포트를 외부에 직접 노출하지 않아도 됩니다:
```yaml
# docker-compose.yml의 n8n ports를 변경
ports:
  - "127.0.0.1:5678:5678"  # 내부만 접근
```

---

## 6. n8n Credentials 설정

n8n UI에 로그인한 후, **Settings → Credentials** 에서 다음을 추가합니다:

### 6-1. Supabase (Header Auth)

| 필드 | 값 |
|---|---|
| Name | `Supabase API` |
| Type | Header Auth |
| Header Name | `apikey` |
| Header Value | `<SUPABASE_SERVICE_ROLE_KEY>` |

추가로 URL도 필요하므로 워크플로우의 HTTP Request 노드에서 Base URL을 설정합니다.

### 6-2. 네이버 API (Header Auth)

| 필드 | 값 |
|---|---|
| Name | `Naver API` |
| Type | Header Auth |
| Header Name | `X-Naver-Client-Id` |
| Header Value | `<NAVER_CLIENT_ID>` |

> ⚠️ 네이버 API는 헤더가 2개 필요합니다. n8n에서는 HTTP Request 노드의 추가 헤더로 `X-Naver-Client-Secret`을 설정합니다.

### 6-3. OpenAI 또는 Anthropic

| 필드 | 값 |
|---|---|
| Name | `OpenAI` 또는 `Anthropic` |
| Type | OpenAI / HTTP Header Auth |
| API Key | `<API_KEY>` |

### 6-4. Slack (Webhook)

워크플로우의 HTTP Request 노드에서 직접 Webhook URL을 사용합니다.

---

## 7. 워크플로우 Import

### 7-1. 워크플로우 파일 업로드

이 디렉토리의 JSON 파일을 n8n에 import합니다:

1. n8n UI → **Workflows** → **Import from File**
2. `workflow_collect.json` import
3. `workflow_suggest.json` import
4. `workflow_agent_reach_collect.json` import (VPS Agent Reach 보강 수집)

### 7-2. Credentials 연결

Import 후 각 노드에서 사용하는 Credentials를 위에서 생성한 것으로 연결합니다.

### 7-3. 워크플로우 활성화

각 워크플로우를 **Active** 상태로 전환하면 Cron 스케줄에 따라 자동 실행됩니다.

---

## 8. Agent Reach 보강 수집 설정

기존 Vercel/API 수집은 네이버·구글·정책 소스를 계속 담당하고, Agent Reach는 VPS에서 Exa 검색·RSS·YouTube·GitHub 소재를 보강해 같은 `raw_articles` 테이블에 저장합니다.

### 8-1. VPS 원클릭 bootstrap

Ubuntu 24.04 VPS에서 root 또는 sudo로 실행합니다. 이 스크립트는 Docker, n8n, Agent Reach, GitHub CLI, host runner, systemd service까지 설치합니다.

```bash
curl -fsSL https://raw.githubusercontent.com/lycian5/AIMAX004_V1_codex/main/scripts/bootstrap-vps.sh -o /tmp/bootstrap-vps.sh
sudo bash /tmp/bootstrap-vps.sh
```

이미 저장소를 받은 상태라면 저장소 안에서 직접 실행해도 됩니다:

```bash
sudo bash scripts/bootstrap-vps.sh
```

bootstrap 이후 구성 파일은 `/opt/coa-news/.env`에 생성됩니다. 생성 직후 반드시 Supabase, OpenAI, Naver, Slack 값을 채운 뒤 서비스를 재시작합니다.

```bash
sudo nano /opt/coa-news/.env
sudo systemctl restart coa-agent-reach-runner
cd /opt/coa-news
sudo docker compose --env-file .env -f n8n/docker-compose.yml up -d
```

### 8-2. n8n 접속 및 workflow import

브라우저에서 `http://<VPS_IP>:5678`로 접속한 뒤 bootstrap 출력에 나온 계정으로 로그인합니다.

다음 파일을 n8n UI에서 import합니다:

1. `n8n/workflow_collect.json`
2. `n8n/workflow_agent_reach_collect.json`
3. `n8n/workflow_suggest.json`

`workflow_agent_reach_collect.json`은 다음 흐름입니다:

```text
Schedule/Webhook → n8n HTTP Request → host Agent Reach runner → Supabase raw_articles
```

n8n은 Docker 컨테이너 안에서 직접 Agent Reach CLI를 실행하지 않습니다. 대신 호스트 systemd 서비스인 `coa-agent-reach-runner`를 `http://host.docker.internal:8787/run`으로 호출합니다.

### 8-3. 필수 환경변수

```bash
SUPABASE_URL=https://xxxxxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
OPENAI_API_KEY=sk-...
NAVER_CLIENT_ID=
NAVER_CLIENT_SECRET=
SLACK_WEBHOOK_URL=

N8N_USER=admin
N8N_PASSWORD=강력한_비밀번호
N8N_WEBHOOK_URL=http://<VPS_IP>:5678/

AGENT_REACH_WEBHOOK_URL=http://<VPS_IP>:5678/webhook/agent-reach-collect
AGENT_REACH_WEBHOOK_SECRET=강력한_랜덤_문자열
AGENT_REACH_RUNNER_SECRET=AGENT_REACH_WEBHOOK_SECRET와_동일하게_설정
AGENT_REACH_RUNNER_URL=http://host.docker.internal:8787/run
AGENT_REACH_SOURCES=exa,rss,youtube,github
AGENT_REACH_LIMIT_KEYWORDS=18
AGENT_REACH_EXA_RESULTS=5
AGENT_REACH_YOUTUBE_RESULTS=3
AGENT_REACH_GITHUB_RESULTS=5

# 선택: RSS 보강 피드
# 형식: 이름|URL|카테고리
AGENT_REACH_RSS_FEEDS=OpenAI|https://openai.com/news/rss.xml|ai_business
```

### 8-4. 수동 실행 테스트

```bash
cd /opt/coa-news
set -a && . ./.env && set +a
export PATH="$HOME/.agent-reach-venv/bin:$PATH"

node scripts/agent-reach-collect.js --dry-run --limit-keywords=2 --sources=exa --exa-results=2
curl -fsS http://127.0.0.1:8787/health
curl -fsS -X POST http://127.0.0.1:8787/run \
  -H "Authorization: Bearer $AGENT_REACH_RUNNER_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"dryRun":true,"sources":"exa","limitKeywords":2,"exaResults":2}'
```

정상 실행 시 JSON 요약이 출력되고, dry-run이 아니면 `raw_articles`에 `agent_reach_exa`, `agent_reach_youtube`, `agent_reach_github`, `agent_reach_rss:*` 소스로 저장됩니다.

### 8-5. Vercel API에서 VPS webhook 호출

Vercel 환경변수에는 다음을 설정합니다:

```bash
AGENT_REACH_WEBHOOK_URL=http://<VPS_IP>:5678/webhook/agent-reach-collect
AGENT_REACH_WEBHOOK_SECRET=VPS와_동일한_랜덤_문자열
```

`vercel.json`에는 `/api/cron/agent-reach`가 21:30 UTC(한국시간 06:30)에 실행되도록 추가되어 있습니다.

### 8-6. 운영 확인

```bash
sudo systemctl status coa-agent-reach-runner
sudo journalctl -u coa-agent-reach-runner -f
cd /opt/coa-news
sudo docker compose --env-file .env -f n8n/docker-compose.yml ps
sudo docker compose --env-file .env -f n8n/docker-compose.yml logs -f n8n
```

---

## 9. 유지보수

### 로그 확인
```bash
docker compose logs -f --tail=100 n8n
```

### n8n 업데이트
```bash
cd /opt/coa-news
docker compose pull
docker compose up -d
```

### 백업
```bash
# n8n 데이터 백업
tar -czf n8n-backup-$(date +%Y%m%d).tar.gz n8n-data/
```

### 디스크 확인
```bash
df -h
docker system df
docker system prune -f  # 불필요한 이미지/컨테이너 정리
```

---

## 트러블슈팅

| 증상 | 해결 |
|---|---|
| n8n 접속 불가 | `docker ps`로 컨테이너 상태 확인, `ufw status`로 방화벽 확인 |
| ARM64 이미지 오류 | `n8nio/n8n:latest`는 ARM64 지원. `docker pull --platform linux/arm64` 확인 |
| 메모리 부족 | `free -h`로 확인, swap 추가: `fallocate -l 2G /swapfile && ...` |
| Cron 미실행 | n8n UI에서 워크플로우가 **Active** 상태인지 확인 |
| Agent Reach 수집 실패 | `agent-reach doctor`와 `mcporter config list` 확인. n8n Docker 내부 실행이면 컨테이너 안 PATH/설치를 확인 |
