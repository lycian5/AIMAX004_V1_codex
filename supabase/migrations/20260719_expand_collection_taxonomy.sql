-- Expand collection taxonomy while preserving all existing category values.
do $$
declare
  target_table text;
begin
  foreach target_table in array array['tracked_keywords', 'raw_articles', 'event_clusters'] loop
    execute format('alter table %I drop constraint if exists %I', target_table, target_table || '_category_check');
    execute format(
      'alter table %I add constraint %I check (category in (''ai_business'', ''startup'', ''policy'', ''small_business_economy'', ''local_commerce'', ''marketing_distribution'', ''field_issue''))',
      target_table,
      target_table || '_category_check'
    );
  end loop;
end $$;

alter table raw_articles add column if not exists query_stage text not null default 'explore'
  check (query_stage in ('explore', 'precision', 'verification'));
alter table raw_articles add column if not exists source_layer text not null default 'signal'
  check (source_layer in ('signal', 'official', 'data'));

create index if not exists raw_articles_query_stage_idx on raw_articles(query_stage);
create index if not exists raw_articles_source_layer_idx on raw_articles(source_layer);
