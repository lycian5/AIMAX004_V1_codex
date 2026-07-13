const { getSupabase } = require('../lib/supabase');
const { assertCronAuth } = require('../lib/cronAuth');

module.exports = async (req, res) => {
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }
  try {
    assertCronAuth(req);
    const supabase = getSupabase();
    const limit = clamp(req.query?.limit, 1, 100, 30);
    let query = supabase
      .from('event_clusters')
      .select('id,category,representative_title,event_date,first_seen_at,last_seen_at,article_count,official_source_count,status')
      .order('last_seen_at', { ascending: false })
      .limit(limit);
    if (req.query?.category) query = query.eq('category', req.query.category);
    if (req.query?.status) query = query.eq('status', req.query.status);
    const { data: clusters, error } = await query;
    if (error) throw error;
    const ids = (clusters || []).map((item) => item.id);
    if (!ids.length) {
      res.status(200).json({ briefs: [] });
      return;
    }

    const [{ data: articles, error: articleError }, { data: facts, error: factError }] = await Promise.all([
      supabase
        .from('raw_articles')
        .select('id,event_cluster_id,title,url,summary,published_at,source_domain,source_type,quality_score,verification_status')
        .in('event_cluster_id', ids)
        .order('quality_score', { ascending: false }),
      supabase
        .from('article_facts')
        .select('id,event_cluster_id,raw_article_id,fact_text,fact_type,source_url,is_official,confidence,verified_at')
        .in('event_cluster_id', ids)
        .order('confidence', { ascending: false }),
    ]);
    if (articleError) throw articleError;
    if (factError) throw factError;

    res.status(200).json({
      briefs: clusters.map((cluster) => ({
        ...cluster,
        articles: (articles || []).filter((item) => item.event_cluster_id === cluster.id),
        facts: (facts || []).filter((item) => item.event_cluster_id === cluster.id),
      })),
    });
  } catch (err) {
    res.status(err.statusCode || 500).json({ error: err.message });
  }
};

function clamp(value, min, max, fallback) {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) ? Math.min(max, Math.max(min, parsed)) : fallback;
}
