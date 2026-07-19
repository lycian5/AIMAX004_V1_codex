const assert = require('node:assert/strict');
const fs = require('node:fs');

const api = fs.readFileSync(require.resolve('../api/editorial/drafts'), 'utf8');
const page = fs.readFileSync(require.resolve('../docs/research-briefs.html'), 'utf8');
assert.match(api, /assertCronAuth/);
assert.match(api, /event_clusters/);
assert.match(api, /article_facts/);
assert.match(api, /raw_articles/);
assert.match(api, /view === 'briefs'/);
assert.match(page, /AI 초안 생성/);
assert.match(page, /coa_news_draft_seed/);
assert.match(page, /CoaAuth\.request/);
assert.doesNotMatch(page, /CRON_SECRET/);
process.stdout.write('Research briefs checks passed.\n');
