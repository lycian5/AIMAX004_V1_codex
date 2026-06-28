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

## Features

- Policy Briefing, Bizinfo, Work24, Public Data Portal seeds
- Article-like URL discovery
- Progressive fetch strategy in Python collector
- Static HTML browser collector for quick use
- JSON, JSONL, CSV, Markdown export

## Security

Do not commit GitHub tokens or API keys. Keep secrets in environment variables only.