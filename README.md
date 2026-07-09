# aimax004_v1_codex

Standalone policy article collector.

## Vercel URL

Target deployment URL:

https://aimax-004-v1-codex.vercel.app

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

Agent Reach enrichment is designed to run on the VPS, not Vercel serverless. Bootstrap a fresh Ubuntu VPS with:

```bash
curl -fsSL https://raw.githubusercontent.com/lycian5/AIMAX004_V1_codex/main/scripts/bootstrap-vps.sh -o /tmp/bootstrap-vps.sh
sudo bash /tmp/bootstrap-vps.sh
```

Then edit `/opt/coa-news/.env`, restart services, and import the n8n workflows.

Collector checks:

```bash
node scripts/agent-reach-collect.js --dry-run --limit-keywords=2 --sources=exa
node scripts/agent-reach-runner.js
node scripts/agent-reach-collect.js
```

It reads active `tracked_keywords`, collects Exa/RSS/YouTube/GitHub candidates, and upserts them into Supabase `raw_articles`.
Vercel can trigger the VPS/n8n workflow through `/api/cron/agent-reach` when `AGENT_REACH_WEBHOOK_URL` is configured.
See `n8n/README.md` for VPS and n8n setup.

## Features

- Policy Briefing, Bizinfo, Work24, Public Data Portal seeds
- Article-like URL discovery
- Progressive fetch strategy in Python collector
- Static HTML browser collector for quick use
- Agent Reach VPS enrichment for Exa, RSS, YouTube, and GitHub
- JSON, JSONL, CSV, Markdown export

## Security

Do not commit GitHub tokens or API keys. Keep secrets in environment variables only.
