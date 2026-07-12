const assert = require('node:assert/strict');
const fs = require('node:fs');

const source = fs.readFileSync(require.resolve('../scripts/agent-reach-runner'), 'utf8');
assert.match(source, /body\?\.async === true/);
assert.match(source, /accepted: true/);
assert.match(source, /activeRun\.finally/);
process.stdout.write('Agent Reach async runner checks passed.\n');
