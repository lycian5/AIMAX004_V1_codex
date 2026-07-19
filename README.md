# aimax004_v1_codex

COA NEWS의 대량 기사 소재 수집, 중복 제거, 점수화, 리서치 브리프와 편집용 맥락 요약을 제공하는 운영 프로젝트입니다.

운영 기준의 단일 원본은 [`docs/OPERATING_STANDARD.md`](docs/OPERATING_STANDARD.md)입니다.

## 운영 화면

- 배포 URL: `https://aimax-004-v1-codex.vercel.app`
- 수집 제어: `/vps-collector`
- 리서치 브리프: `/research-briefs`
- 소재 초안: `/editorial-drafts`
- 등록용 기사 준비: `/coanews-draft`

수집 제어, 리서치 브리프, 소재 초안은 하나의 관리자 세션을 사용합니다. Vercel Production에 다음 값을 설정합니다.

```text
CRON_SECRET=<자동화 전용 비밀값>
DASHBOARD_PASSWORD=<관리자 로그인 비밀번호, 12자 이상>
DASHBOARD_SESSION_SECRET=<선택, 32자 이상의 별도 세션 비밀값>
```

`CRON_SECRET`을 사람의 로그인 비밀번호로 사용하지 않습니다. `/admin-login`에서 로그인하면 세션은 7일간 유지됩니다.

## 수집 전략

- Vercel 기본 수집은 Naver와 Google 중심으로 매일 18개 키워드를 처리합니다.
- VPS Agent Reach는 Exa, 공식 기관, RSS를 중심으로 매일 54개 키워드를 처리합니다.
- 원시 수집에는 OpenAI를 사용하지 않습니다.
- 중복 제거, 출처 평가, 점수화, 사건 클러스터링 후 최대 100개 브리프를 표시합니다.
- AI는 선택된 소재의 200~1600자 맥락 요약에만 사용합니다.
- 완성 기사는 채택된 소재에 한해 별도 작성하고 신문 플랫폼에 수동 등록합니다.

## 편집 및 플랫폼 상태

소재 초안의 `pending_editor_approval`은 내부 검토대기 상태입니다. 신문 플랫폼에 기사가 등록되거나 승인됐다는 뜻이 아닙니다. 플랫폼 등록과 편집장 승인 여부는 플랫폼의 실제 상태로 별도 확인합니다.

등록용 기사 준비 화면은 `article.json`, `body.html`, 선택한 대표 이미지와 체크리스트가 포함된 ZIP을 만듭니다. 자동 게시 기능은 제공하지 않으며, 플랫폼에 JSON 또는 CSV 가져오기 기능이 생길 때까지 수동 등록을 유지합니다.

## Vercel 배포

- GitHub: `lycian5/AIMAX004_V1_codex`
- Vercel 프로젝트: `aimax-004-v1-codex`
- Framework Preset: Other
- Output Directory: `docs`

`vercel.json`이 정적 화면과 API cron 구성을 관리합니다.

## VPS 및 n8n 배포

```powershell
cd C:\Users\user\Documents\aimax004_v1_codex\deploy\n8n
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\deploy.ps1
```

n8n은 `127.0.0.1:5678`에만 바인딩하고 Caddy HTTPS를 통해 접근합니다. 설치, 비밀값, Agent Reach, 백업, DS220j와 복원 절차는 [`deploy/n8n/README.md`](deploy/n8n/README.md)를 따릅니다.

## 로컬 실행

정적 화면:

```powershell
npm start
```

Python 수집기:

```powershell
python -m venv .venv
.venv\Scripts\activate
pip install -e .
policy-collector collect --max-pages 5 --format json --output exports/latest.json
```

FastAPI 화면:

```powershell
uvicorn policy_article_collector.app:app --reload --host 127.0.0.1 --port 8080
```

## 보안

API 키, Supabase service role key, 데이터베이스 URL, 백업 암호와 `.env` 파일을 Git에 커밋하지 않습니다. n8n의 5678 포트와 Agent Reach runner의 8787 포트를 인터넷에 공개하지 않습니다.
