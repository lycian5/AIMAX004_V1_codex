const assert = require('node:assert/strict');

const source = require('node:fs').readFileSync(require.resolve('../api/cron/agent-reach'), 'utf8');
assert.match(source, /sanitizeOptions/);
assert.match(source, /allowedSources/);
assert.match(source, /limitKeywords/);
assert.match(source, /async: req\.method === 'POST'/);
assert.doesNotMatch(source, /\.\.\.req\.body/);
process.stdout.write('Agent Reach option forwarding checks passed.\n');
