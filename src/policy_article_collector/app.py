from __future__ import annotations

from fastapi import FastAPI, Query
from fastapi.responses import HTMLResponse

from policy_article_collector.collector import ArticleCollector
from policy_article_collector.exporters import article_to_dict

app = FastAPI(title="Policy Article Collector", version="0.1.0")


@app.get("/", response_class=HTMLResponse)
def index() -> str:
    return """
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Policy Article Collector</title>
  <style>
    :root { --bg:#f5f7fb; --panel:#fff; --ink:#17202a; --muted:#64748b; --line:#dce3ea; --accent:#0f766e; }
    body { margin:0; background:var(--bg); color:var(--ink); font-family:Arial, sans-serif; }
    main { max-width:1120px; margin:0 auto; padding:28px; }
    header { display:flex; align-items:center; justify-content:space-between; gap:16px; }
    h1 { margin:0; font-size:28px; }
    .controls, .card { background:var(--panel); border:1px solid var(--line); border-radius:8px; padding:16px; }
    .controls { display:grid; grid-template-columns:1fr 140px 140px; gap:10px; margin:22px 0; }
    select, input, button { min-height:40px; border:1px solid var(--line); border-radius:6px; padding:0 10px; font:inherit; }
    button { background:var(--accent); color:white; cursor:pointer; }
    .grid { display:grid; gap:12px; }
    .meta { color:var(--muted); font-size:13px; }
    a { color:var(--accent); overflow-wrap:anywhere; }
    pre { white-space:pre-wrap; font-size:13px; line-height:1.45; }
  </style>
</head>
<body>
  <main>
    <header><h1>Policy Article Collector</h1><span class="meta">Standalone UI</span></header>
    <section class="controls">
      <select id="source">
        <option value="">All sources</option>
        <option value="policy_briefing">Policy Briefing</option>
        <option value="bizinfo">Bizinfo</option>
        <option value="work24">Work24</option>
        <option value="public_data">Public Data</option>
      </select>
      <input id="maxPages" type="number" value="5" min="1" max="30" />
      <button id="run">Collect</button>
    </section>
    <section id="status" class="meta"></section>
    <section id="results" class="grid"></section>
  </main>
  <script>
    const run = document.querySelector('#run');
    const status = document.querySelector('#status');
    const results = document.querySelector('#results');
    run.onclick = async () => {
      run.disabled = true;
      status.textContent = 'Collecting...';
      results.innerHTML = '';
      const source = document.querySelector('#source').value;
      const maxPages = document.querySelector('#maxPages').value;
      const url = `/api/collect?max_pages=${maxPages}` + (source ? `&source=${source}` : '');
      try {
        const data = await fetch(url, { method: 'POST' }).then(r => r.json());
        status.textContent = `Collected ${data.articles.length}, failures ${Object.keys(data.failures).length}, skipped ${data.skipped_duplicates}`;
        results.innerHTML = data.articles.map(article => `
          <article class="card">
            <h2>${escapeHtml(article.title)}</h2>
            <p class="meta">${article.source_type} · ${article.strategy}</p>
            <p><a href="${article.url}" target="_blank">${article.url}</a></p>
            <pre>${escapeHtml(article.raw_content.slice(0, 700))}</pre>
          </article>`).join('');
      } catch (error) {
        status.textContent = String(error);
      } finally {
        run.disabled = false;
      }
    };
    function escapeHtml(value) {
      return String(value).replace(/[&<>'"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));
    }
  </script>
</body>
</html>
"""


@app.post("/api/collect")
async def collect(
    source: str | None = Query(default=None),
    max_pages: int = Query(default=5, ge=1, le=30),
    concurrency: int = Query(default=4, ge=1, le=10),
):
    collector = ArticleCollector(concurrency=concurrency, max_pages_per_source=max_pages)
    report = await collector.collect(source_type=source)
    return {
        "articles": [article_to_dict(article) for article in report.articles],
        "failures": {
            url: [{**attempt.__dict__, "strategy": attempt.strategy.value} for attempt in attempts]
            for url, attempts in report.failures.items()
        },
        "skipped_duplicates": report.skipped_duplicates,
    }