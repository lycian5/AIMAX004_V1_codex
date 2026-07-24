create table if not exists collection_schedules (
  key text primary key check (key = 'agent_reach'),
  enabled boolean not null default true,
  daily_time time not null default '06:30',
  timezone text not null default 'Asia/Seoul' check (timezone = 'Asia/Seoul'),
  updated_at timestamptz not null default now()
);

insert into collection_schedules (key, enabled, daily_time, timezone)
values ('agent_reach', true, '06:30', 'Asia/Seoul')
on conflict (key) do nothing;
