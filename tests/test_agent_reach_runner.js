const assert = require('node:assert/strict');
const fs = require('node:fs');

const source = fs.readFileSync(require.resolve('../scripts/agent-reach-runner'), 'utf8');
const workflow = JSON.parse(fs.readFileSync(require.resolve('../n8n/workflow_agent_reach_collect.json'), 'utf8'));
assert.match(source, /body\?\.async === true/);
assert.match(source, /accepted: true/);
assert.match(source, /activeRun\.finally/);
const prepareNode = workflow.nodes.find((node) => node.id === 'prepare-runner');
const callNode = workflow.nodes.find((node) => node.id === 'call-runner');
const summaryNode = workflow.nodes.find((node) => node.id === 'format-summary');
assert.match(prepareNode.parameters.jsCode, /request,/);
assert.match(callNode.parameters.jsonBody, /async: true/);
assert.match(callNode.parameters.jsonBody, /\.\.\.\$json\.request/);
assert.match(summaryNode.parameters.jsCode, /accepted/);
process.stdout.write('Agent Reach async runner checks passed.\n');
