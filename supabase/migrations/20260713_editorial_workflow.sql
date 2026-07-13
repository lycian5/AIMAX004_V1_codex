create table if not exists editorial_drafts (
  id bigint generated always as identity primary key,
  event_cluster_id bigint not null references event_clusters(id) on delete cascade,
  title text not null,
  subtitle text,
  summary text,
  body_html text not null,
  tags text[] not null default '{}',
  status text not null default 'draft'
    check (status in ('draft', 'pending_editor_approval', 'approved', 'rejected')),
  model text,
  editorial_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  submitted_at timestamptz,
  decided_at timestamptz
);

create index if not exists editorial_drafts_status_idx on editorial_drafts(status, updated_at desc);
create index if not exists editorial_drafts_cluster_idx on editorial_drafts(event_cluster_id, created_at desc);

notify pgrst, 'reload schema';

select table_name, column_name
from information_schema.columns
where table_schema = 'public' and table_name = 'editorial_drafts'
order by ordinal_position;
