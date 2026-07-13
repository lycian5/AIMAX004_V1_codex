'use strict';

function selectHybridKeywords(keywords, options = {}) {
  const limit = Math.max(0, Number.parseInt(options.limitKeywords, 10) || 0);
  if (!limit || !keywords.length) return [];

  const coreCount = Math.min(
    Math.max(0, Number.parseInt(options.coreKeywordCount, 10) || 0),
    limit,
    keywords.length
  );
  const core = keywords.slice(0, coreCount);
  const pool = keywords.slice(coreCount);
  const rotatingCount = Math.min(
    Math.max(0, Number.parseInt(options.rotatingKeywordCount, 10) || 0),
    Math.max(0, limit - core.length),
    pool.length
  );
  if (!rotatingCount) return core;

  const date = options.date instanceof Date ? options.date : new Date(options.date || Date.now());
  const day = Math.floor(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()) / 86400000);
  const start = (day * rotatingCount) % pool.length;
  const rotating = Array.from({ length: rotatingCount }, (_, index) => pool[(start + index) % pool.length]);
  return [...core, ...rotating];
}

module.exports = { selectHybridKeywords };
