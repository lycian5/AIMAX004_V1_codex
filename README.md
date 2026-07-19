# aimax004_v1_codex

Standalone policy article collector.

## Vercel URL

Target deployment URL:

https://aimax-004-v1-codex.vercel.app

## Admin Login

The collection dashboard, research briefs, and editorial drafts use one administrator session. Set these Vercel Production environment variables before deployment:

```text
CRON_SECRET=<machine-to-machine automation secret>
DASHBOARD_PASSWORD=<separate administrator password, at least 12 characters>
```

Optionally set `DASHBOARD_SESSION_SECRET` to a separate random value with at least 32 characters. Open `/admin-login` and sign in once; the secure `HttpOnly` session lasts seven days and is shared by `/vps-collector`, `/research-briefs`, and `/editorial-drafts`. Changing `DASHBOARD_PASSWORD` invalidates existing sessions. Do not use `CRON_SECRET` as the dashboard password.

To get this exact URL in Vercel, create or import the project with this project name:

```text
aimax-004-v1-codex
```

This repo includes `vercel.json`, so Vercel serves the static collector UI from `docs/` at the site root.

## One-Click Web Use

The browser UI is located at:

```text
docs/index.html
```

It runs in the browser and uses Jina Reader for browser-friendly fetching. It can preview collected articles and download JSON, CSV, or Markdown.

## COA NEWS Manual Draft Package

The collector does not log in to the newspaper platform or publish articles automatically. Use the safe manual-review flow instead:

1. Collect article ideas in `docs/index.html`.
2. Select `코아뉴스 초안` on a result card.
3. Complete the title, subtitles, body, category, reporter, tags, and image attribution.
4. Add a JPG or PNG representative image. The browser creates an `800 x 400` JPG preview.
5. Download the ZIP package containing `article.json`, `body.html`, the optional `thumbnail.jpg`, and a registration checklist.
6. Review the package, enter it in the COA NEWS administrator article form, and select `뉴스등록`.
7. The registered article remains pending until the editor-in-chief approves, holds, or rejects it.

The package is always marked `pending_editor_approval` with `publish_allowed: false`. It represents an article saved through `뉴스등록` and waiting for the editor-in-chief's decision. Main exposure, headline exposure, advertorial mode, comments, and shared-news distribution are disabled by default.

Open a blank draft directly at:

```text
docs/coanews-draft.html
```

If the newspaper platform later adds an import module, use `article.json` as the versioned interchange contract. Imported articles must enter the same editor-approval queue as manually registered news and remain unpublished until approval.

## Deploy To Vercel

Import this GitHub repo into Vercel:

- Repository: `lycian5/AIMAX004_V1_codex`
- Project Name: `aimax-004-v1-codex`
- Framework Preset: Other
- Build Command: disabled by `vercel.json`
- Install Command: disabled by `vercel.json`
- Output Directory: `docs`

## Python CLI

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -e .
policy-collector collect --max-pages 5 --format json --output exports/latest.json
```

## Local FastAPI UI

```bash
uvicorn policy_article_collector.app:app --reload --host 127.0.0.1 --port 8080
```

Then open `http://127.0.0.1:8080`.

## Agent Reach VPS Collector

Agent Reach enrichment runs on the Vultr VPS, not Vercel serverless. Use the canonical Windows deployment:

```powershell
cd C:\Users\user\Documents\aimax004_v1_codex\deploy\n8n
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\deploy.ps1
```

The deployment starts n8n even before DNS is available and enables Caddy HTTPS after `n8n.coanews.co.kr` resolves to `158.247.245.66`. See `deploy/n8n/README.md` for secrets, backup, DS220j, and recovery operations. The legacy `scripts/bootstrap-vps.sh` path is disabled because it exposed port 5678.

Collector checks:

```bash
node scripts/agent-reach-collect.js --dry-run --limit-keywords=2 --sources=exa
node scripts/agent-reach-runner.js
node scripts/agent-reach-collect.js
```

It reads active `tracked_keywords`, collects Exa/RSS/YouTube/GitHub candidates, and upserts them into Supabase `raw_articles`.
Vercel can trigger the VPS/n8n workflow through `/api/cron/agent-reach` when `AGENT_REACH_WEBHOOK_URL` is configured.
See `deploy/n8n/README.md` for VPS and n8n setup.

## Features

- Policy Briefing, Bizinfo, Work24, Public Data Portal seeds
- Article-like URL discovery
- Progressive fetch strategy in Python collector
- Static HTML browser collector for quick use
- Agent Reach VPS enrichment for Exa, RSS, YouTube, and GitHub
- JSON, JSONL, CSV, Markdown export

## Security

Do not commit GitHub tokens or API keys. Keep secrets in environment variables only.
