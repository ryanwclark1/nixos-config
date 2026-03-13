#!/usr/bin/env node
"use strict";

function parseArg(name, fallback) {
  const prefix = `--${name}=`;
  const found = process.argv.find(arg => arg.startsWith(prefix));
  if (!found) return fallback;
  const n = Number(found.slice(prefix.length));
  return Number.isFinite(n) ? n : fallback;
}

const linesCount = Math.max(1000, Math.floor(parseArg("lines", 120000)));
const runs = Math.max(1, Math.floor(parseArg("runs", 25)));
const seed = Math.floor(parseArg("seed", 1337));
const outputJson = process.argv.includes("--json");
const homeDir = "/home/administrator";

function makePrng(initialSeed) {
  let state = initialSeed >>> 0;
  return function rand() {
    state = (state * 1664525 + 1013904223) >>> 0;
    return state / 0x100000000;
  };
}

const rand = makePrng(seed);

function makeRaw() {
  const rows = new Array(linesCount);
  for (let i = 0; i < linesCount; i += 1) {
    const depth = 1 + Math.floor(rand() * 5);
    const segs = [];
    for (let j = 0; j < depth; j += 1) segs.push(`dir${Math.floor(rand() * 90)}`);
    const leaf = `file-${i}-${Math.floor(rand() * 9999)}.txt`;
    const rel = `${segs.join("/")}/${leaf}`;
    rows[i] = (i % 7 === 0) ? `${homeDir}/${rel}` : rel;
  }
  return `${rows.join("\n")}\n`;
}

const raw = makeRaw();

function parseLegacy(rawText, home) {
  const lines = rawText ? rawText.split("\n") : [];
  const items = [];
  for (let i = 0; i < lines.length; i += 1) {
    if (lines[i].trim() !== "") {
      const path = lines[i];
      const parts = path.split("/");
      const fullPath = path.startsWith("/") ? path : `${home}/${path}`;
      items.push({ name: parts[parts.length - 1] || path, title: fullPath, fullPath });
    }
  }
  return items;
}

function parseOptimized(rawText, home) {
  const lines = rawText ? rawText.split("\n") : [];
  const items = new Array(lines.length);
  let count = 0;
  for (let i = 0; i < lines.length; i += 1) {
    const path = String(lines[i] || "");
    if (path === "") continue;
    const fullPath = path.charCodeAt(0) === 47 ? path : `${home}/${path}`;
    const slash = fullPath.lastIndexOf("/");
    let name = slash >= 0 ? fullPath.substring(slash + 1) : fullPath;
    if (name === "") name = path;
    items[count] = { name, title: fullPath, fullPath };
    count += 1;
  }
  if (count < items.length) items.length = count;
  return items;
}

function run(fn) {
  const t0 = process.hrtime.bigint();
  let checksum = 0;
  let total = 0;
  for (let i = 0; i < runs; i += 1) {
    const out = fn(raw, homeDir);
    total += out.length;
    for (let j = 0; j < out.length; j += 1) checksum += out[j].name.length;
  }
  const t1 = process.hrtime.bigint();
  return { ms: Number(t1 - t0) / 1e6, checksum, total };
}

function median(vals) {
  const sorted = vals.slice().sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid];
}

// Warmup
run(parseLegacy);
run(parseOptimized);

const legacy = [];
const optimized = [];
let lastLegacy = null;
let lastOptimized = null;
for (let i = 0; i < 5; i += 1) {
  lastLegacy = run(parseLegacy);
  lastOptimized = run(parseOptimized);
  legacy.push(lastLegacy.ms);
  optimized.push(lastOptimized.ms);
}

const medLegacy = median(legacy);
const medOptimized = median(optimized);
const speedup = medLegacy / Math.max(0.001, medOptimized);

if (outputJson) {
  console.log(JSON.stringify({
    benchmark: "launcher-files-shaping",
    lines: linesCount,
    runs,
    seed,
    legacyMedianMs: medLegacy,
    optimizedMedianMs: medOptimized,
    speedup,
    legacyChecksum: lastLegacy ? lastLegacy.checksum : 0,
    optimizedChecksum: lastOptimized ? lastOptimized.checksum : 0,
    legacyTotal: lastLegacy ? lastLegacy.total : 0,
    optimizedTotal: lastOptimized ? lastOptimized.total : 0
  }));
  process.exit(0);
}

console.log("Launcher Files Shaping Benchmark");
console.log(`lines=${linesCount} runs=${runs} seed=${seed}`);
console.log(`legacy median:    ${medLegacy.toFixed(2)}ms`);
console.log(`optimized median: ${medOptimized.toFixed(2)}ms`);
console.log(`speedup:          ${speedup.toFixed(2)}x`);
console.log(`legacy checksum:  ${lastLegacy ? lastLegacy.checksum : 0} total=${lastLegacy ? lastLegacy.total : 0}`);
console.log(`opt checksum:     ${lastOptimized ? lastOptimized.checksum : 0} total=${lastOptimized ? lastOptimized.total : 0}`);
