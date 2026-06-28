from policy_article_collector.models import SeedSource

DEFAULT_SOURCES = (
    SeedSource("policy_briefing", "Policy Briefing", ("https://www.korea.kr/briefing/pressReleaseList.do",)),
    SeedSource("bizinfo", "Bizinfo", ("https://www.bizinfo.go.kr/web/lay1/bbs/S1T122C128/AS/74/list.do",)),
    SeedSource("work24", "Work24", ("https://www.work24.go.kr",)),
    SeedSource("public_data", "Public Data Portal", ("https://www.data.go.kr",)),
)