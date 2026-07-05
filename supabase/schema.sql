-- 코아뉴스 키워드 전략 기획서 4.4절 스키마 (Postgres/Supabase)
-- Supabase 대시보드 → SQL Editor 에서 전체를 한 번 실행하세요.

create table if not exists tracked_keywords (
  id bigint generated always as identity primary key,
  keyword text not null,
  category text not null check (category in ('ai_business', 'startup', 'policy')),
  tier text not null default 'seed' check (tier in ('seed', 'expanded', 'issue')),
  status text not null default 'active' check (status in ('active', 'retired')),
  datalab_priority int not null default 3,
  last_article_at timestamptz,
  added_by text not null default 'manual' check (added_by in ('manual', 'auto_weekly', 'auto_rising')),
  created_at timestamptz not null default now(),
  unique (keyword, category)
);

create table if not exists raw_articles (
  id bigint generated always as identity primary key,
  keyword_id bigint references tracked_keywords(id) on delete set null,
  category text not null check (category in ('ai_business', 'startup', 'policy')),
  source text not null,
  title text not null,
  url text not null unique,
  summary text,
  published_at timestamptz,
  collected_at timestamptz not null default now()
);

create index if not exists raw_articles_keyword_id_idx on raw_articles(keyword_id);
create index if not exists raw_articles_collected_at_idx on raw_articles(collected_at);
create index if not exists raw_articles_category_idx on raw_articles(category);

create table if not exists topic_suggestions (
  id bigint generated always as identity primary key,
  suggested_date date not null default current_date,
  category text not null,
  format text not null check (format in ('article', 'column', 'interview')),
  title text not null,
  angle text,
  keywords text[],
  reference_headlines text[],
  quadrant text,
  interviewee text,
  created_at timestamptz not null default now()
);

create index if not exists topic_suggestions_date_idx on topic_suggestions(suggested_date);

create index if not exists tracked_keywords_category_status_idx on tracked_keywords(category, status);

-- ── 시드 키워드 54개 (docs/index.html의 QUICK_KEYWORDS와 동일) ──────────────
insert into tracked_keywords (keyword, category, tier, status, datalab_priority, added_by) values
  ('생성형 AI', 'ai_business', 'seed', 'active', 1, 'manual'),
  ('AI 에이전트', 'ai_business', 'seed', 'active', 1, 'manual'),
  ('챗GPT', 'ai_business', 'seed', 'active', 1, 'manual'),
  ('클로드(Claude)', 'ai_business', 'seed', 'active', 1, 'manual'),
  ('제미나이', 'ai_business', 'seed', 'active', 1, 'manual'),
  ('AI 자동화', 'ai_business', 'seed', 'active', 1, 'manual'),
  ('업무 자동화', 'ai_business', 'seed', 'active', 1, 'manual'),
  ('AI 도입 사례', 'ai_business', 'seed', 'active', 1, 'manual'),
  ('AI 생산성', 'ai_business', 'seed', 'active', 1, 'manual'),
  ('LLM', 'ai_business', 'seed', 'active', 1, 'manual'),
  ('AI 스타트업', 'ai_business', 'seed', 'active', 1, 'manual'),
  ('AI 마케팅', 'ai_business', 'seed', 'active', 1, 'manual'),
  ('AI 챗봇', 'ai_business', 'seed', 'active', 1, 'manual'),
  ('노코드', 'ai_business', 'seed', 'active', 1, 'manual'),
  ('RPA', 'ai_business', 'seed', 'active', 1, 'manual'),
  ('AI 반도체', 'ai_business', 'seed', 'active', 1, 'manual'),
  ('온디바이스 AI', 'ai_business', 'seed', 'active', 1, 'manual'),
  ('AI 규제', 'ai_business', 'seed', 'active', 1, 'manual'),

  ('창업', 'startup', 'seed', 'active', 2, 'manual'),
  ('부업', 'startup', 'seed', 'active', 2, 'manual'),
  ('N잡', 'startup', 'seed', 'active', 2, 'manual'),
  ('사이드잡', 'startup', 'seed', 'active', 2, 'manual'),
  ('온라인 수익화', 'startup', 'seed', 'active', 2, 'manual'),
  ('스마트스토어', 'startup', 'seed', 'active', 2, 'manual'),
  ('1인 기업', 'startup', 'seed', 'active', 2, 'manual'),
  ('무자본 창업', 'startup', 'seed', 'active', 2, 'manual'),
  ('프랜차이즈 창업', 'startup', 'seed', 'active', 2, 'manual'),
  ('배달 창업', 'startup', 'seed', 'active', 2, 'manual'),
  ('유튜브 수익', 'startup', 'seed', 'active', 2, 'manual'),
  ('블로그 수익', 'startup', 'seed', 'active', 2, 'manual'),
  ('전자책 판매', 'startup', 'seed', 'active', 2, 'manual'),
  ('구매대행', 'startup', 'seed', 'active', 2, 'manual'),
  ('해외구매대행', 'startup', 'seed', 'active', 2, 'manual'),
  ('공유오피스', 'startup', 'seed', 'active', 2, 'manual'),
  ('폐업', 'startup', 'seed', 'active', 2, 'manual'),
  ('재창업', 'startup', 'seed', 'active', 2, 'manual'),

  ('정부지원사업', 'policy', 'seed', 'active', 1, 'manual'),
  ('소상공인 지원', 'policy', 'seed', 'active', 1, 'manual'),
  ('창업지원금', 'policy', 'seed', 'active', 1, 'manual'),
  ('중소기업 지원', 'policy', 'seed', 'active', 1, 'manual'),
  ('예비창업패키지', 'policy', 'seed', 'active', 1, 'manual'),
  ('초기창업패키지', 'policy', 'seed', 'active', 1, 'manual'),
  ('청년창업', 'policy', 'seed', 'active', 1, 'manual'),
  ('청년정책', 'policy', 'seed', 'active', 1, 'manual'),
  ('고용지원금', 'policy', 'seed', 'active', 1, 'manual'),
  ('바우처 사업', 'policy', 'seed', 'active', 1, 'manual'),
  ('K-스타트업', 'policy', 'seed', 'active', 1, 'manual'),
  ('기업마당', 'policy', 'seed', 'active', 1, 'manual'),
  ('정책자금', 'policy', 'seed', 'active', 1, 'manual'),
  ('소상공인 대출', 'policy', 'seed', 'active', 1, 'manual'),
  ('재난지원', 'policy', 'seed', 'active', 1, 'manual'),
  ('세제 혜택', 'policy', 'seed', 'active', 1, 'manual'),
  ('중소벤처기업부', 'policy', 'seed', 'active', 1, 'manual'),
  ('고용노동부', 'policy', 'seed', 'active', 1, 'manual')
on conflict (keyword, category) do nothing;
