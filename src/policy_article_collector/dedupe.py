import hashlib
import re


def normalize_space(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


def normalize_title(title: str) -> str:
    title = normalize_space(title).lower()
    return re.sub(r"[\[\]().,!?]", "", title)


def content_hash(title: str, content: str) -> str:
    compact_content = normalize_space(content)
    normalized = f"{normalize_title(title)}\n{compact_content}"
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()