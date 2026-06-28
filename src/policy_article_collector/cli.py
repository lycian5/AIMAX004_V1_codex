from __future__ import annotations

import argparse
import asyncio
from pathlib import Path

from policy_article_collector.collector import ArticleCollector
from policy_article_collector.exporters import export_articles


def main() -> None:
    parser = argparse.ArgumentParser(prog="policy-collector")
    subparsers = parser.add_subparsers(dest="command", required=True)

    collect = subparsers.add_parser("collect", help="Collect policy articles")
    collect.add_argument("--source", choices=["policy_briefing", "bizinfo", "work24", "public_data"], default=None)
    collect.add_argument("--max-pages", type=int, default=10)
    collect.add_argument("--concurrency", type=int, default=4)
    collect.add_argument("--timeout", type=float, default=15.0)
    collect.add_argument("--format", choices=["json", "jsonl", "csv", "md"], default="json")
    collect.add_argument("--output", default="exports/latest.json")

    args = parser.parse_args()
    if args.command == "collect":
        asyncio.run(run_collect(args))


async def run_collect(args: argparse.Namespace) -> None:
    collector = ArticleCollector(timeout=args.timeout, concurrency=args.concurrency, max_pages_per_source=args.max_pages)
    report = await collector.collect(source_type=args.source)
    output = export_articles(report.articles, Path(args.output), args.format)
    print(f"collected={len(report.articles)} skipped_duplicates={report.skipped_duplicates} failures={len(report.failures)}")
    print(f"output={output}")


if __name__ == "__main__":
    main()