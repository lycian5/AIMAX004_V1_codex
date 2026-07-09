const { assertCronAuth } = require('../lib/cronAuth');

module.exports = async (req, res) => {
  try {
    assertCronAuth(req);
  } catch (err) {
    res.status(err.statusCode || 401).json({ error: err.message });
    return;
  }

  const webhookUrl = process.env.AGENT_REACH_WEBHOOK_URL;
  if (!webhookUrl) {
    res.status(200).json({
      skipped: true,
      reason: 'AGENT_REACH_WEBHOOK_URL is not configured',
    });
    return;
  }

  const headers = { 'Content-Type': 'application/json' };
  if (process.env.AGENT_REACH_WEBHOOK_SECRET) {
    headers.Authorization = `Bearer ${process.env.AGENT_REACH_WEBHOOK_SECRET}`;
    headers['X-Agent-Reach-Secret'] = process.env.AGENT_REACH_WEBHOOK_SECRET;
  }

  try {
    const upstream = await fetch(webhookUrl, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        source: 'vercel-cron',
        requested_at: new Date().toISOString(),
      }),
    });
    const text = await upstream.text();
    let body = text;
    try {
      body = text ? JSON.parse(text) : null;
    } catch (_) {
      body = text.slice(0, 2000);
    }

    res.status(upstream.ok ? 200 : 502).json({
      ok: upstream.ok,
      upstreamStatus: upstream.status,
      body,
    });
  } catch (err) {
    res.status(502).json({ ok: false, error: err.message });
  }
};
