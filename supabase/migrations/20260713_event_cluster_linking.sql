-- Link collected articles to conservative date/title-based event clusters.
alter table event_clusters add column if not exists event_date date;

alter table raw_articles
  add column if not exists event_cluster_id bigint references event_clusters(id) on delete set null;

create index if not exists raw_articles_event_cluster_idx on raw_articles(event_cluster_id);
create index if not exists event_clusters_event_date_idx on event_clusters(category, event_date desc);

notify pgrst, 'reload schema';

select table_name, column_name
from information_schema.columns
where table_schema = 'public'
  and (
    (table_name = 'raw_articles' and column_name = 'event_cluster_id')
    or (table_name = 'event_clusters' and column_name = 'event_date')
  )
order by table_name, column_name;
