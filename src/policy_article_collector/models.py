from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum


class FetchStrategy(str, Enum):
    direct = "direct"
    mobile = "mobile"
    jina_reader = "jina_reader"


@dataclass(frozen=True)
class SeedSource:
    source_type: str
    name: str
    urls: tuple[str, ...]


@dataclass
class FetchAttempt:
    url: str
    strategy: FetchStrategy
    ok: bool
    status_code: int | None = None
    error: str | None = None


@dataclass
class CollectedArticle:
    source_type: str
    source_name: str
    title: str
    url: str
    raw_content: str
    content_hash: str
    fetched_at: datetime
    strategy: FetchStrategy
    attempts: list[FetchAttempt] = field(default_factory=list)

    @property
    def summary(self) -> str:
        return self.raw_content[:240].strip()


@dataclass
class CollectionReport:
    articles: list[CollectedArticle]
    failures: dict[str, list[FetchAttempt]]
    skipped_duplicates: int

    @property
    def total_attempted(self) -> int:
        return len(self.articles) + len(self.failures)