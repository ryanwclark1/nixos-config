#!/usr/bin/env node
"use strict";

function parseArg(name, fallback) {
  const prefix = `--${name}=`;
  const found = process.argv.find(arg => arg.startsWith(prefix));
  if (!found) return fallback;
  const value = Number(found.slice(prefix.length));
  return Number.isFinite(value) ? value : fallback;
}

const appsCount = Math.max(1000, Math.floor(parseArg("apps", 30000)));
const historyCount = Math.max(50, Math.floor(parseArg("history", 500)));
const runs = Math.max(1, Math.floor(parseArg("runs", 60)));
const seed = Math.floor(parseArg("seed", 1337));
const recentLimit = 6;
const suggestionsLimit = 4;

function makePrng(initialSeed) {
  let state = initialSeed >>> 0;
  return function rand() {
    state = (state * 1664525 + 1013904223) >>> 0;
    return state / 0x100000000;
  };
}

function pick(max, rand) {
  return Math.floor(rand() * max);
}

const rand = makePrng(seed);

const apps = [];
for (let i = 0; i < appsCount; i += 1) {
  apps.push({
    exec: `app-${i}`,
    name: `App ${i}`,
    title: `Synthetic ${i}`
  });
}

const appFrequency = {};
for (let i = 0; i < appsCount; i += 1) {
  const use = Math.floor(rand() * 30);
  if (use > 0) appFrequency[`app-${i}`] = use;
}

const launchHistory = [];
for (let i = 0; i < historyCount; i += 1) {
  launchHistory.push({
    exec: `app-${pick(appsCount, rand)}`,
    timestamp: 1700000000000 + i * 1000
  });
}

function buildHomeLegacy() {
  let recent = [];
  const seen = {};
  for (let i = 0; i < launchHistory.length; i += 1) {
    const launch = launchHistory[i];
    for (let j = 0; j < apps.length; j += 1) {
      const app = apps[j];
      if (app.exec === launch.exec && !seen[app.exec]) {
        const matched = Object.assign({}, app);
        matched._recent = launch.timestamp || 0;
        recent.push(matched);
        seen[app.exec] = true;
        break;
      }
    }
  }
  if (recent.length < recentLimit) {
    const scored = [];
    for (let k = 0; k < apps.length; k += 1) {
      const ranked = apps[k];
      const count = appFrequency[ranked.exec] || 0;
      if (count > 0 && !seen[ranked.exec]) {
        const copy = Object.assign({}, ranked);
        copy._recent = count;
        scored.push(copy);
      }
    }
    scored.sort((a, b) => b._recent - a._recent);
    recent = recent.concat(scored);
  }
  const recentItems = recent.slice(0, recentLimit);

  const suggestions = [];
  for (let m = 0; m < apps.length; m += 1) {
    const candidate = apps[m];
    if (seen[candidate.exec]) continue;
    const usage = appFrequency[candidate.exec] || 0;
    if (usage > 0) {
      const suggested = Object.assign({}, candidate);
      suggested._usage = usage;
      suggestions.push(suggested);
    }
  }
  suggestions.sort((a, b) => (b._usage || 0) - (a._usage || 0));
  const suggestionItems = suggestions.slice(0, suggestionsLimit);

  return {
    checksum: recentItems.reduce((acc, r) => acc + (r._recent || 0), 0) + suggestionItems.reduce((acc, s) => acc + (s._usage || 0), 0),
    recentCount: recentItems.length,
    suggestionCount: suggestionItems.length
  };
}

function buildHomeOptimized() {
  const recent = [];
  const seen = {};
  const appsByExec = {};
  const usageRanked = [];

  for (let i = 0; i < apps.length; i += 1) {
    const app = apps[i];
    const execKey = String(app.exec || "");
    if (execKey !== "" && !appsByExec[execKey]) appsByExec[execKey] = app;
    const usage = appFrequency[execKey] || 0;
    if (usage > 0) {
      const rankedByUsage = Object.assign({}, app);
      rankedByUsage._usage = usage;
      usageRanked.push(rankedByUsage);
    }
  }

  for (let j = 0; j < launchHistory.length; j += 1) {
    const launch = launchHistory[j];
    const launchExec = String(launch.exec || "");
    const matchedApp = launchExec === "" ? null : appsByExec[launchExec];
    if (matchedApp && !seen[launchExec]) {
      const matched = Object.assign({}, matchedApp);
      matched._recent = launch.timestamp || 0;
      recent.push(matched);
      seen[launchExec] = true;
    }
  }

  usageRanked.sort((a, b) => (b._usage || 0) - (a._usage || 0));

  if (recent.length < recentLimit) {
    for (let k = 0; k < usageRanked.length; k += 1) {
      const fallback = usageRanked[k];
      const fallbackExec = String(fallback.exec || "");
      if (fallbackExec === "" || seen[fallbackExec]) continue;
      const promoted = Object.assign({}, fallback);
      promoted._recent = fallback._usage || 0;
      recent.push(promoted);
      seen[fallbackExec] = true;
      if (recent.length >= recentLimit) break;
    }
  }
  const recentItems = recent.slice(0, recentLimit);

  const suggestions = [];
  for (let m = 0; m < usageRanked.length; m += 1) {
    const candidate = usageRanked[m];
    const candidateExec = String(candidate.exec || "");
    if (candidateExec === "" || seen[candidateExec]) continue;
    suggestions.push(candidate);
  }
  const suggestionItems = suggestions.slice(0, suggestionsLimit);

  return {
    checksum: recentItems.reduce((acc, r) => acc + (r._recent || 0), 0) + suggestionItems.reduce((acc, s) => acc + (s._usage || 0), 0),
    recentCount: recentItems.length,
    suggestionCount: suggestionItems.length
  };
}

function measure(fn) {
  const t0 = process.hrtime.bigint();
  let checksum = 0;
  let count = 0;
  for (let i = 0; i < runs; i += 1) {
    const out = fn();
    checksum += out.checksum;
    count += out.recentCount + out.suggestionCount;
  }
  const t1 = process.hrtime.bigint();
  return {
    ms: Number(t1 - t0) / 1e6,
    checksum,
    count
  };
}

function median(values) {
  const sorted = values.slice().sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid];
}

const legacyTimes = [];
const optimizedTimes = [];
let lastLegacy = null;
let lastOptimized = null;
for (let i = 0; i < 5; i += 1) {
  lastLegacy = measure(buildHomeLegacy);
  lastOptimized = measure(buildHomeOptimized);
  legacyTimes.push(lastLegacy.ms);
  optimizedTimes.push(lastOptimized.ms);
}

const legacyMedian = median(legacyTimes);
const optimizedMedian = median(optimizedTimes);
const speedup = legacyMedian / Math.max(0.001, optimizedMedian);

console.log("Launcher Home Benchmark");
console.log(`apps=${appsCount} history=${historyCount} runs=${runs} seed=${seed}`);
console.log(`legacy median:    ${legacyMedian.toFixed(2)}ms`);
console.log(`optimized median: ${optimizedMedian.toFixed(2)}ms`);
console.log(`speedup:          ${speedup.toFixed(2)}x`);
console.log(`legacy checksum:  ${lastLegacy ? lastLegacy.checksum : 0} count=${lastLegacy ? lastLegacy.count : 0}`);
console.log(`opt checksum:     ${lastOptimized ? lastOptimized.checksum : 0} count=${lastOptimized ? lastOptimized.count : 0}`);
