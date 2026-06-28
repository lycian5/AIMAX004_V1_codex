from __future__ import annotations

import re
from urllib.parse import urljoin, urlparse

from bs4 import BeautifulSoup

from policy_article_collector.dedupe import normalize_space


def extract_article_text(html: str | bytes) -> tuple[str, str]:
    soup = BeautifulSoup(html, "html.parser")
    for tag in soup(["script", "style", "noscript", "svg", "iframe"]):
        tag.decompose()

    title = ""
    if soup.title:
        title = soup.title.get_text(" ", strip=True)
    if not title:
        h1 = soup.find("h1")
        title = h1.get_text(" ", strip=True) if h1 else ""

    candidates = [soup.find("article"), soup.find("main"), soup.find(attrs={"role": "main"}), soup.body]
    text = ""
    for candidate in candidates:
        if candidate is None:
            continue
        candidate_text = normalize_space(candidate.get_text(" ", strip=True))
        if len(candidate_text) > len(text):
            text = candidate_text

    return normalize_space(title), text


def extract_candidate_urls(html: str | bytes, base_url: str) -> list[str]:
    soup = BeautifulSoup(html, "html.parser")
    base_host = urlparse(base_url).netloc
    candidates: list[tuple[int, str]] = []
    for anchor in soup.find_all("a", href=True):
        href = str(anchor.get("href", "")).strip()
        absolute = urljoin(base_url, href)
        parsed = urlparse(absolute)
        if parsed.scheme not in {"http", "https"}:
            continue
        if parsed.netloc and parsed.netloc != base_host:
            continue
        if is_asset_url(parsed.path):
            continue
        score = score_article_url(absolute, anchor.get_text(" ", strip=True))
        if score <= 0:
            continue
        candidates.append((score, absolute))

    candidates.sort(key=lambda item: item[0], reverse=True)
    deduped: list[str] = []
    seen: set[str] = set()
    for _, url in candidates:
        add_url(deduped, seen, url)
    return deduped


def add_url(urls: list[str], seen: set[str], url: str) -> None:
    normalized = url.split("#", 1)[0].strip()
    if not normalized or normalized in seen:
        return
    seen.add(normalized)
    urls.append(normalized)


def is_asset_url(path: str) -> bool:
    return bool(re.search(r"\.(jpg|jpeg|png|gif|webp|svg|css|js|pdf|zip|hwp|hwpx|xlsx?)$", path, re.I))


def score_article_url(url: str, text: str) -> int:
    lowered = url.lower()
    score = 0
    for token in ("view", "detail", "article", "notice", "bbs", "board", "press", "news"):
        if token in lowered:
            score += 2
    if re.search(r"[?&](seq|id|no|ntt|bbs|article|dataid)=", lowered):
        score += 3
    if len(normalize_space(text)) >= 8:
        score += 1
    return score