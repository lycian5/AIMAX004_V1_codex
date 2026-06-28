# aimax004_v1_codex

독립형 정책 기사 수집기입니다. 기존 SaaS 프로젝트와 분리해서 사용할 수 있도록 Python 패키지, CLI, FastAPI 기반 미니 UI를 포함합니다.

## 기능

- 정책브리핑, 기업마당, 고용24, 공공데이터포털 수집
- 목록 페이지에서 기사 후보 URL 자동 발견
- `direct -> mobile user-agent -> Jina Reader` 순서의 단계적 fetch 전략
- 본문 추출 및 중복 해시 생성
- JSON, JSONL, Markdown 내보내기
- 브라우저에서 실행 가능한 간단한 수집 UI

## 설치

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -e .
```

## CLI 사용

```bash
policy-collector collect --max-pages 5 --format json --output exports/latest.json
policy-collector collect --source policy_briefing --format md --output exports/policy.md
```

## UI 실행

```bash
uvicorn policy_article_collector.app:app --reload --host 127.0.0.1 --port 8080
```

브라우저에서 `http://127.0.0.1:8080`을 엽니다.

## Python 사용

```python
import asyncio
from policy_article_collector import ArticleCollector

async def main():
    collector = ArticleCollector(max_pages_per_source=5)
    report = await collector.collect()
    print(len(report.articles), report.skipped_duplicates)

asyncio.run(main())
```

## 보안

GitHub 토큰, API 키 등 비밀값은 코드나 `.env`에 커밋하지 마세요. 이 프로젝트는 수집기 자체만 포함합니다.