-- Additive research metadata for source tracing, event clustering, and verification.
alter table raw_articles add column if not exists canonical_url text;
alter table raw_articles add column if not exists source_domain text;
alter table raw_articles add column if not exists source_type text not null default 'media'
  check (source_type in ('official', 'media', 'community', 'video', 'repository', 'unknown'));
alter table raw_articles add column if not exists authority_score smallint not null default 40
  check (authority_score between 0 and 100);
alter table raw_articles add column if not exists evidence_score smallint not null default 0
  check (evidence_score between 0 and 100);
alter table raw_articles add column if not exists quality_score smallint not null default 0
  check (quality_score between 0 and 100);
alter table raw_articles add column if not exists verification_status text not null default 'unverified'
  check (verification_status in ('unverified', 'needs_verification', 'verified', 'rejected'));
alter table raw_articles add column if not exists event_fingerprint text;
alter table raw_articles add column if not exists last_checked_at timestamptz not null default now();

create index if not exists raw_articles_canonical_url_idx on raw_articles(canonical_url);
create index if not exists raw_articles_event_fingerprint_idx on raw_articles(event_fingerprint);
create index if not exists raw_articles_quality_score_idx on raw_articles(quality_score desc);
create index if not exists raw_articles_verification_status_idx on raw_articles(verification_status);

create table if not exists event_clusters (
  id bigint generated always as identity primary key,
  fingerprint text not null unique,
  category text not null check (category in ('ai_business', 'startup', 'policy')),
  representative_title text not null,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  article_count int not null default 1,
  official_source_count int not null default 0,
  status text not null default 'developing'
    check (status in ('developing', 'ready', 'archived'))
);

create table if not exists article_facts (
  id bigint generated always as identity primary key,
  event_cluster_id bigint references event_clusters(id) on delete cascade,
  raw_article_id bigint references raw_articles(id) on delete cascade,
  fact_text text not null,
  fact_type text not null default 'claim'
    check (fact_type in ('claim', 'date', 'person', 'organization', 'location', 'number', 'quote')),
  source_url text not null,
  is_official boolean not null default false,
  confidence numeric(4,3) not null default 0.500 check (confidence between 0 and 1),
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  unique (raw_article_id, fact_text)
);

create index if not exists article_facts_cluster_idx on article_facts(event_cluster_id);
create index if not exists article_facts_article_idx on article_facts(raw_article_id);
