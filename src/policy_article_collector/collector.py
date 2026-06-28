from __future__ import annotations

import asyncio
from datetime import datetime, timezone

import httpx

from policy_article_collector.dedupe import content_hash
from policy_article_collector.extract import add_url, extract_article_text, extract_candidate_urls
from policy_article_collector.models import CollectionReport, CollectedArticle, FetchAttempt, FetchStrategy, SeedSource
from policy_article_collector.sources import DEFAULT_SOURCES


class ArticleCollector:
    """Standalone policy article collector with progressive fetch strategies."""

    def __init__(
        self,
        timeout: float = 15.0,
        concurrency: int = 4,
        sources: tuple[SeedSource, ...] = DEFAULT_SOURCES,
        max_pages_per_source: int = 10,
    ) -> None:
        self.timeout = timeout
        self.concurrency = concurrency
        self.sources = sources
        self.max_pages_per_source = max_pages_per_source
        self.failures: dict[str, list[FetchAttempt]] = {}

    async def collect(self, source_type: str | None = None) -> CollectionReport:
        target_sources = tuple(source for source in self.sources if source_type in (None, source.source_type))
        semaphore = asyncio.Semaphore(self.concurrency)
        discovered: list[tuple[SeedSource, str]] = []
        for source in target_sources:
            urls = await self._discover_source_urls(source)
            discovered.extend((source, url) for url in urls)

        tasks = [self._collect_one(source=source, url=url, semaphore=semaphore) for source, url in discovered]
        collected: list[CollectedArticle] = []
        seen_hashes: set[str] = set()
        skipped = 0
        for article in await asyncio.gather(*tasks):
            if article is None:
                continue
            if article.content_hash in seen_hashes:
                skipped += 1
                continue
            seen_hashes.add(article.content_hash)
            collected.append(article)
        return CollectionReport(articles=collected, failures=self.failures, skipped_duplicates=skipped)

    async def _discover_source_urls(self, source: SeedSource) -> list[str]:
        discovered: list[str] = []
        seen: set[str] = set()
        for seed_url in source.urls:
            add_url(discovered, seen, seed_url)
            html = await self._fetch_first_html(seed_url)
            if not html:
                continue
            for url in extract_candidate_urls(html, seed_url):
                if len(discovered) >= self.max_pages_per_source:
                    break
                add_url(discovered, seen, url)
        return discovered

    async def _fetch_first_html(self, url: str) -> bytes | None:
        for strategy in FetchStrategy:
            html, attempt = await self._fetch(url=url, strategy=strategy)
            if html and attempt.ok:
                return html
        return None

    async def _collect_one(self, source: SeedSource, url: str, semaphore: asyncio.Semaphore) -> CollectedArticle | None:
        async with semaphore:
            attempts: list[FetchAttempt] = []
            for strategy in FetchStrategy:
                html, attempt = await self._fetch(url=url, strategy=strategy)
                attempts.append(attempt)
                if not html:
                    continue

                title, text = extract_article_text(html)
                if not text:
                    attempts.append(FetchAttempt(url=url, strategy=strategy, ok=False, error="empty_content"))
                    continue

                title = title or source.name
                return CollectedArticle(
                    source_type=source.source_type,
                    source_name=source.name,
                    title=title[:500],
                    url=url,
                    raw_content=text[:12000],
                    content_hash=content_hash(title, text),
                    fetched_at=datetime.now(timezone.utc),
                    strategy=strategy,
                    attempts=attempts,
                )

            self.failures[url] = attempts
            return None

    async def _fetch(self, url: str, strategy: FetchStrategy) -> tuple[bytes | None, FetchAttempt]:
        request_url = build_strategy_url(url, strategy)
        try:
            async with httpx.AsyncClient(timeout=self.timeout, follow_redirects=True) as client:
                response = await client.get(request_url, headers=build_headers(strategy))
            if response.status_code >= 400:
                return None, FetchAttempt(url=url, strategy=strategy, ok=False, status_code=response.status_code)
            return response.content, FetchAttempt(url=url, strategy=strategy, ok=True, status_code=response.status_code)
        except httpx.HTTPError as exc:
            return None, FetchAttempt(url=url, strategy=strategy, ok=False, error=exc.__class__.__name__)


def build_strategy_url(url: str, strategy: FetchStrategy) -> str:
    if strategy == FetchStrategy.jina_reader:
        return "https://r.jina.ai/http://" + url.removeprefix("https://").removeprefix("http://")
    return url


def build_headers(strategy: FetchStrategy) -> dict[str, str]:
    user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"
    if strategy == FetchStrategy.mobile:
        user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    return {
        "User-Agent": user_agent,
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "ko-KR,ko;q=0.9,en-US;q=0.6,en;q=0.5",
    }