#!/usr/bin/env node
"use strict";

function parseArg(name, fallback) {
  const prefix = `--${name}=`;
  const hit = process.argv.find(arg => arg.startsWith(prefix));
  if (!hit) return fallback;
  const raw = hit.slice(prefix.length);
  const asNumber = Number(raw);
  return Number.isFinite(asNumber) ? asNumber : fallback;
}

const itemCount = Math.max(1000, Math.floor(parseArg("items", 30000)));
const runs = Math.max(1, Math.floor(parseArg("runs", 40)));
const seed = Math.floor(parseArg("seed", 1337));
const outputJson = process.argv.includes("--json");

const modePrefixes = ["=", ">", ":", "?", "!", "@", "/"];
const scoreWeights = {
  name: 1.0,
  title: 0.92,
  exec: 0.88,
  body: 0.75,
  category: 0.7
};

function stripModePrefix(text) {
  const value = String(text || "");
  if (value.length > 0 && modePrefixes.includes(value[0])) return value.slice(1).trim();
  return value;
}

function makePrng(initialSeed) {
  let state = initialSeed >>> 0;
  return function rand() {
    state = (state * 1664525 + 1013904223) >>> 0;
    return state / 0x100000000;
  };
}

function pick(arr, rand) {
  return arr[Math.floor(rand() * arr.length)];
}

const WORDS = [
  "terminal", "browser", "editor", "music", "system", "network", "files", "display", "audio", "bluetooth",
  "calendar", "notes", "workspace", "panel", "quickshell", "nixos", "git", "window", "launcher", "search",
  "package", "clipboard", "emoji", "calc", "render", "theme", "dock", "control", "settings", "media"
];

function makeItems(count, rand) {
  const out = [];
  for (let i = 0; i < count; i += 1) {
    const a = pick(WORDS, rand);
    const b = pick(WORDS, rand);
    const c = pick(WORDS, rand);
    out.push({
      name: `${a}-${i}`,
      title: `${b} ${c} helper`,
      exec: `${a}-${b}`,
      class: `${a}.${b}.${c}`,
      body: `${a} ${b} ${c} workflow tooling`,
      category: `${a} ${b}`,
      keywords: `${a};${b};${c};launcher;menu`
    });
  }
  return out;
}

function fuzzyMatchLegacy(str, pattern) {
  if (!pattern) return 100;
  if (!str) return 0;
  const s = String(str).toLowerCase();
  const p = stripModePrefix(pattern).toLowerCase();
  if (!p) return 100;
  if (s.startsWith(p)) return 100 + (p.length / s.length);
  if (s.indexOf(p) !== -1) return 50 + (p.length / s.length);
  let pIdx = 0;
  let sIdx = 0;
  while (sIdx < s.length && pIdx < p.length) {
    if (s[sIdx] === p[pIdx]) pIdx += 1;
    sIdx += 1;
  }
  if (pIdx === p.length) return 10 + (p.length / s.length);
  return 0;
}

function fuzzyMatchLower(s, p) {
  if (!p) return 100;
  if (!s) return 0;
  if (s.startsWith(p)) return 100 + (p.length / s.length);
  if (s.indexOf(p) !== -1) return 50 + (p.length / s.length);
  let pIdx = 0;
  let sIdx = 0;
  while (sIdx < s.length && pIdx < p.length) {
    if (s[sIdx] === p[pIdx]) pIdx += 1;
    sIdx += 1;
  }
  if (pIdx === p.length) return 10 + (p.length / s.length);
  return 0;
}

function rankLegacy(item, query) {
  const clean = stripModePrefix(query);
  if (clean === "") return 1;
  const categoryKeywords = `${item.category || ""} ${item.keywords || ""}`.trim();
  const best = Math.max(
    fuzzyMatchLegacy(item.name || "", clean) * scoreWeights.name,
    fuzzyMatchLegacy(item.title || "", clean) * scoreWeights.title,
    fuzzyMatchLegacy(item.exec || item.class || "", clean) * scoreWeights.exec,
    fuzzyMatchLegacy(item.body || "", clean) * scoreWeights.body,
    fuzzyMatchLegacy(categoryKeywords, clean) * scoreWeights.category
  );
  return best;
}

function rankOptimized(item, clean, cleanLower) {
  if (clean === "") return 1;
  if (!item._rankCacheReady) {
    item._nameLower = item.name ? String(item.name).toLowerCase() : "";
    item._titleLower = item.title ? String(item.title).toLowerCase() : "";
    item._execLower = item.exec ? String(item.exec).toLowerCase() : (item.class ? String(item.class).toLowerCase() : "");
    item._bodyLower = item.body ? String(item.body).toLowerCase() : "";
    const category = item.category ? String(item.category).toLowerCase() : "";
    const keywords = item.keywords ? String(item.keywords).toLowerCase() : "";
    item._categoryKeywordsLower = `${category} ${keywords}`.trim();
    item._rankCacheReady = true;
  }
  const best = Math.max(
    fuzzyMatchLower(item._nameLower, cleanLower) * scoreWeights.name,
    fuzzyMatchLower(item._titleLower, cleanLower) * scoreWeights.title,
    fuzzyMatchLower(item._execLower, cleanLower) * scoreWeights.exec,
    fuzzyMatchLower(item._bodyLower, cleanLower) * scoreWeights.body,
    fuzzyMatchLower(item._categoryKeywordsLower, cleanLower) * scoreWeights.category
  );
  return best;
}

function bench(items, queries, fn) {
  const t0 = process.hrtime.bigint();
  let matched = 0;
  let sum = 0;
  for (let q = 0; q < queries.length; q += 1) {
    const query = queries[q];
    for (let i = 0; i < items.length; i += 1) {
      const score = fn(items[i], query);
      if (score > 0) matched += 1;
      sum += score;
    }
  }
  const t1 = process.hrtime.bigint();
  return {
    ms: Number(t1 - t0) / 1e6,
    matched,
    checksum: Math.round(sum)
  };
}

function benchOptimized(items, queries) {
  const t0 = process.hrtime.bigint();
  let matched = 0;
  let sum = 0;
  for (let q = 0; q < queries.length; q += 1) {
    const clean = stripModePrefix(queries[q]);
    const cleanLower = clean.toLowerCase();
    for (let i = 0; i < items.length; i += 1) {
      const score = rankOptimized(items[i], clean, cleanLower);
      if (score > 0) matched += 1;
      sum += score;
    }
  }
  const t1 = process.hrtime.bigint();
  return {
    ms: Number(t1 - t0) / 1e6,
    matched,
    checksum: Math.round(sum)
  };
}

function formatMs(ms) {
  return `${ms.toFixed(2)}ms`;
}

function median(values) {
  const sorted = values.slice().sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid];
}

const rand = makePrng(seed);
const items = makeItems(itemCount, rand);
const queryPool = ["ter", "sys", "net", "quick", "file", "edit", ">git", "?nix", ":smile", "dock"];
const queries = [];
for (let i = 0; i < runs; i += 1) queries.push(pick(queryPool, rand));

const warmLegacy = bench(items, queries.slice(0, 4), rankLegacy);
const warmOptimized = benchOptimized(items, queries.slice(0, 4));
void warmLegacy;
void warmOptimized;

const legacySamples = [];
const optimizedSamples = [];
for (let i = 0; i < 5; i += 1) {
  legacySamples.push(bench(items, queries, rankLegacy));
  optimizedSamples.push(benchOptimized(items, queries));
}

const legacyMs = legacySamples.map(s => s.ms);
const optimizedMs = optimizedSamples.map(s => s.ms);
const legacyMedian = median(legacyMs);
const optimizedMedian = median(optimizedMs);
const speedup = legacyMedian / Math.max(0.001, optimizedMedian);

const lastLegacy = legacySamples[legacySamples.length - 1];
const lastOptimized = optimizedSamples[optimizedSamples.length - 1];

if (outputJson) {
  console.log(JSON.stringify({
    benchmark: "launcher-filter",
    items: itemCount,
    runs,
    seed,
    legacyMedianMs: legacyMedian,
    optimizedMedianMs: optimizedMedian,
    speedup,
    legacyChecksum: lastLegacy.checksum,
    optimizedChecksum: lastOptimized.checksum,
    legacyMatched: lastLegacy.matched,
    optimizedMatched: lastOptimized.matched
  }));
  process.exit(0);
}

console.log("Launcher Filter Benchmark");
console.log(`items=${itemCount} runs=${runs} seed=${seed}`);
console.log(`legacy median:    ${formatMs(legacyMedian)}`);
console.log(`optimized median: ${formatMs(optimizedMedian)}`);
console.log(`speedup:          ${speedup.toFixed(2)}x`);
console.log(`legacy checksum:  ${lastLegacy.checksum} matched=${lastLegacy.matched}`);
console.log(`opt checksum:     ${lastOptimized.checksum} matched=${lastOptimized.matched}`);
