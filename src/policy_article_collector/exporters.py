from __future__ import annotations

import csv
import json
from dataclasses import asdict
from pathlib import Path
from typing import Iterable

from policy_article_collector.models import CollectedArticle, FetchStrategy


def article_to_dict(article: CollectedArticle) -> dict:
    data = asdict(article)
    data["fetched_at"] = article.fetched_at.isoformat()
    data["strategy"] = article.strategy.value
    data["attempts"] = [
        {**asdict(attempt), "strategy": attempt.strategy.value}
        for attempt in article.attempts
    ]
    return data


def export_articles(articles: Iterable[CollectedArticle], path: str | Path, fmt: str) -> Path:
    output_path = Path(path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    rows = list(articles)
    if fmt == "json":
        output_path.write_text(json.dumps([article_to_dict(article) for article in rows], ensure_ascii=False, indent=2), encoding="utf-8")
    elif fmt == "jsonl":
        output_path.write_text("\n".join(json.dumps(article_to_dict(article), ensure_ascii=False) for article in rows), encoding="utf-8")
    elif fmt == "csv":
        with output_path.open("w", newline="", encoding="utf-8-sig") as fp:
            writer = csv.DictWriter(fp, fieldnames=["source_type", "title", "url", "strategy", "content_hash", "summary"])
            writer.writeheader()
            for article in rows:
                writer.writerow({
                    "source_type": article.source_type,
                    "title": article.title,
                    "url": article.url,
                    "strategy": article.strategy.value,
                    "content_hash": article.content_hash,
                    "summary": article.summary,
                })
    elif fmt == "md":
        output_path.write_text(render_markdown(rows), encoding="utf-8")
    else:
        raise ValueError(f"Unsupported export format: {fmt}")
    return output_path


def render_markdown(articles: list[CollectedArticle]) -> str:
    chunks = ["# Collected Policy Articles", ""]
    for article in articles:
        chunks.extend([
            f"## {article.title}",
            "",
            f"- Source: `{article.source_type}`",
            f"- Strategy: `{article.strategy.value}`",
            f"- URL: {article.url}",
            "",
            article.raw_content[:2000],
            "",
        ])
    return "\n".join(chunks)