const assert = require('node:assert/strict');
const {
  classifySource,
  eventFingerprint,
  normalizeUrl,
  scoreEvidence,
  scoreQuality,
} = require('../scripts/agent-reach-collect');

assert.equal(normalizeUrl('HTTPS://Example.com/a?utm_source=x&id=1#top'), 'https://example.com/a?id=1');
assert.deepEqual(classifySource('rss', 'https://www.korea.go.kr/news'), { type: 'official', authority: 95 });
assert.equal(classifySource('agent_reach_youtube', 'https://youtube.com/watch?v=1').type, 'video');
assert.ok(scoreEvidence('정부 지원사업 공고', '지원금 3억원, 2026년 조사 자료') >= 70);
assert.ok(scoreQuality(95, 80, new Date().toISOString()) > scoreQuality(25, 10, null));
assert.equal(
  eventFingerprint('AI 기업 투자 발표', '2026-07-12T01:00:00Z', 'ai_business'),
  eventFingerprint('발표, 투자 AI 기업', '2026-07-12T22:00:00Z', 'ai_business')
);

process.stdout.write('Research metadata tests passed.\n');
