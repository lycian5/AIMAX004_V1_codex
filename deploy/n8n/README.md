# n8n 운영 배포

Vultr Ubuntu 24.04의 `/opt/n8n`에 Postgres 16, n8n latest, Agent Reach runner, Caddy와 암호화 백업을 설치합니다. n8n은 `127.0.0.1:5678`에만 바인딩하며 외부에서는 Caddy의 80/443만 사용합니다.

## 현재 선행 조건

- VPS: `158.247.245.66`
- 도메인: `n8n.coanews.co.kr`
- DNS 관리 주체: 신문 플랫폼의 DNSZi 네임서버
- 플랫폼에 요청할 A 레코드: `n8n.coanews.co.kr -> 158.247.245.66`
- Windows OpenSSH Client와 VPS root SSH 로그인 수단

DNS가 아직 없어도 배포할 수 있습니다. 이 경우 n8n과 백업은 시작되고 Caddy HTTPS 적용만 건너뜁니다. DNS 반영 후 같은 스크립트를 다시 실행하면 HTTPS가 활성화됩니다.

## Windows 배포

```powershell
cd C:\Users\user\Documents\aimax004_v1_codex\deploy\n8n
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\deploy.ps1
```

첫 실행에 `.env`가 없으면 `.env.example`을 복사하고 종료합니다. `.env`의 `POSTGRES_PASSWORD`를 직접 입력한 뒤 다시 실행하십시오. 이후 스크립트가 비어 있는 다음 값을 암호학적 난수로 생성합니다.

- `N8N_ENCRYPTION_KEY`
- `AGENT_REACH_RUNNER_SECRET`, `AGENT_REACH_WEBHOOK_SECRET`
- `BACKUP_ENCRYPTION_PASSWORD`

`.env`는 Git에 포함되지 않습니다. 생성된 값은 별도 비밀번호 관리자에도 보관하십시오. `N8N_ENCRYPTION_KEY`를 잃으면 n8n 자격 증명을 복호화할 수 없고, 백업 암호를 잃으면 백업을 복원할 수 없습니다.

VPS에 접속하지 않고 로컬 비밀값만 먼저 준비할 수도 있습니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\deploy.ps1 -PrepareOnly
```

배포 스크립트는 Docker와 Caddy를 설치하고, UFW에서 OpenSSH/80/443만 허용하며, Agent Reach systemd 서비스와 일일 백업 타이머를 등록합니다. `5678`과 `8787`은 외부 방화벽에 열지 않습니다.

## DNS 전 임시 접속

Windows에서 SSH 터널을 유지한 상태로 로컬 브라우저를 엽니다.

```powershell
ssh -L 5678:127.0.0.1:5678 root@158.247.245.66
```

```text
http://127.0.0.1:5678
```

VPS IP의 `:5678`로 직접 접속하는 방식은 사용하지 않습니다.

## DNS 및 HTTPS 확인

신문 플랫폼이 DNSZi에 A 레코드를 추가한 뒤 확인합니다.

```powershell
Resolve-DnsName n8n.coanews.co.kr
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\deploy.ps1
curl.exe -I https://n8n.coanews.co.kr
```

정상 접속 주소는 `https://n8n.coanews.co.kr`입니다.

## 운영 점검

```bash
cd /opt/n8n
docker compose ps
docker compose logs --tail=100 n8n
systemctl status coa-agent-reach-runner --no-pager
systemctl status coa-n8n-backup.timer --no-pager
journalctl -u caddy -n 100 --no-pager
```

## 백업과 복구

VPS는 매일 02:10(Asia/Seoul)에 다음을 `/opt/backups/coa-n8n`에 암호화하여 보관합니다.

- n8n Postgres dump
- n8n 데이터 볼륨
- Docker/Caddy 설정과 `.env`
- `SUPABASE_DB_URL`이 설정된 경우 Supabase Postgres dump

수동 백업:

```bash
sudo /opt/n8n/backup.sh
```

복구는 실행 직전 안전 백업을 하나 더 만든 후 진행합니다.

```bash
sudo /opt/n8n/restore.sh /opt/backups/coa-n8n/coa-n8n-YYYYMMDD-HHMMSS.tar.gz.enc RESTORE
```

DS220j 연계 절차는 `nas/README.md`를 따릅니다. NAS가 VPS의 암호화 파일을 가져오는 pull 방식이므로 NAS 포트를 인터넷에 공개하지 않습니다.

## 수동 설치 핵심 명령

자동 스크립트를 쓰지 않을 경우에도 Ubuntu 24.04에 Docker Compose를 설치한 뒤 아래 순서를 사용합니다.

```bash
mkdir -p /opt/n8n
cd /opt/n8n
docker compose up -d
cp /opt/n8n/Caddyfile /etc/caddy/Caddyfile
caddy validate --config /etc/caddy/Caddyfile
systemctl reload caddy
docker ps
```

Caddy 적용은 DNS가 `158.247.245.66`으로 확인된 뒤 수행해야 합니다.
