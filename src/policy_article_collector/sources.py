"""COA NEWS AI Content Engine — 소재 수집 소스 목록."""
from policy_article_collector.models import SeedSource

# ── AI 비즈니스 소스 ─────────────────────────────────────────
AI_SOURCES = (
    SeedSource("ai_openai",     "OpenAI Blog",        ("https://openai.com/news/",)),
    SeedSource("ai_anthropic",  "Anthropic News",     ("https://www.anthropic.com/news",)),
    SeedSource("ai_google",     "Google AI Blog",     ("https://blog.google/technology/ai/",)),
    SeedSource("ai_microsoft",  "Microsoft AI Blog",  ("https://blogs.microsoft.com/ai/",)),
    SeedSource("ai_aws",        "AWS ML Blog",        ("https://aws.amazon.com/ko/blogs/machine-learning/",)),
    SeedSource("ai_hn",         "HackerNews AI",      ("https://hn.algolia.com/?q=AI+agent&tags=story",)),
)

# ── 창업·부업 소스 ────────────────────────────────────────────
STARTUP_SOURCES = (
    SeedSource("startup_kised",  "창업진흥원",         ("https://www.kised.or.kr/board.es?mid=a10305000000",)),
    SeedSource("startup_bizinfo","Bizinfo 창업",       ("https://www.bizinfo.go.kr/web/lay1/bbs/S1T122C128/AS/74/list.do",)),
    SeedSource("startup_semas",  "소상공인진흥공단",   ("https://www.semas.or.kr/web/main/index.kmdc",)),
)

# ── 정책·지원사업 소스 ────────────────────────────────────────
POLICY_SOURCES = (
    SeedSource("policy_briefing","정책브리핑",         ("https://www.korea.kr/briefing/pressReleaseList.do",)),
    SeedSource("policy_mss",     "중소벤처기업부",     ("https://www.mss.go.kr/site/smba/main.do",)),
    SeedSource("policy_moel",    "고용노동부",         ("https://www.moel.go.kr/news/enews/list.do",)),
    SeedSource("policy_work24",  "Work24",             ("https://www.work24.go.kr",)),
    SeedSource("policy_data",    "공공데이터포털",     ("https://www.data.go.kr",)),
)

# ── 현장 칼럼 소스 ────────────────────────────────────────────
COLUMN_SOURCES = (
    SeedSource("column_bizinfo", "Bizinfo 칼럼",       ("https://www.bizinfo.go.kr/web/lay1/bbs/S1T122C128/AS/74/list.do",)),
)

# ── 전체 기본 소스 (하위 호환) ────────────────────────────────
DEFAULT_SOURCES = AI_SOURCES + STARTUP_SOURCES + POLICY_SOURCES + COLUMN_SOURCES

# ── 카테고리별 소스 맵 ────────────────────────────────────────
CATEGORY_SOURCES = {
    "ai":      AI_SOURCES,
    "startup": STARTUP_SOURCES,
    "policy":  POLICY_SOURCES,
    "column":  COLUMN_SOURCES,
    "all":     DEFAULT_SOURCES,
}