.pragma library

// Pure metric/telemetry helpers for Launcher.qml.
// All functions are immutable: they accept `metrics` as the first argument and
// return a NEW metrics object. The QML bridge is responsible for the assignment:
//   launcherMetrics = Metrics.recordFilterMetric(launcherMetrics, durationMs)

// Returns a zeroed-out metrics object. Use this to initialise or reset metrics.
function freshMetrics() {
    return {
        opens: 0,
        cacheHits: 0,
        cacheMisses: 0,
        commandFailures: 0,
        filterRuns: 0,
        lastFilterMs: 0,
        avgFilterMs: 0,
        filesFdLoads: 0,
        filesFindLoads: 0,
        filesFdLastMs: 0,
        filesFindLastMs: 0,
        filesFdAvgMs: 0,
        filesFindAvgMs: 0,
        filesResolveRuns: 0,
        filesResolveLastMs: 0,
        filesResolveAvgMs: 0,
        perMode: {}
    };
}

// Returns the per-mode stat object for `modeKey`, or a zeroed default when the
// key is absent. Does NOT mutate `metrics`.
function modeMetric(metrics, modeKey) {
    var perMode = (metrics && metrics.perMode) || {};
    return perMode[modeKey] || {
        loads: 0,
        cacheHits: 0,
        cacheMisses: 0,
        failures: 0,
        lastLoadMs: 0,
        avgLoadMs: 0
    };
}

// Records a completed file-index build for the given `backend` ("fd" or "find").
// Returns a new metrics object with the appropriate fd/find counters updated.
function recordFilesBackendLoad(metrics, backend, durationMs) {
    var next = Object.assign({}, metrics);
    var took = Math.max(0, Math.round(durationMs || 0));
    if (backend === "fd") {
        var fdLoads = (next.filesFdLoads || 0) + 1;
        next.filesFdLoads = fdLoads;
        next.filesFdLastMs = took;
        next.filesFdAvgMs = Math.round((((next.filesFdAvgMs || 0) * (fdLoads - 1)) + took) / fdLoads);
    } else if (backend === "find") {
        var findLoads = (next.filesFindLoads || 0) + 1;
        next.filesFindLoads = findLoads;
        next.filesFindLastMs = took;
        next.filesFindAvgMs = Math.round((((next.filesFindAvgMs || 0) * (findLoads - 1)) + took) / findLoads);
    }
    return next;
}

// Records the duration of a single file-path resolve pass.
// Returns a new metrics object with filesResolve* counters updated.
function recordFilesBackendResolveMetric(metrics, durationMs) {
    var next = Object.assign({}, metrics);
    var runs = (next.filesResolveRuns || 0) + 1;
    var took = Math.max(0, Math.round(durationMs || 0));
    next.filesResolveRuns = runs;
    next.filesResolveLastMs = took;
    next.filesResolveAvgMs = Math.round((((next.filesResolveAvgMs || 0) * (runs - 1)) + took) / runs);
    return next;
}

// Records the duration of a single filter pass.
// Returns a new metrics object with filterRuns/lastFilterMs/avgFilterMs updated.
function recordFilterMetric(metrics, durationMs) {
    var next = Object.assign({}, metrics);
    var runs = Math.max(0, Math.round(next.filterRuns || 0)) + 1;
    var last = Math.max(0, Math.round(durationMs || 0));
    var avg = Math.round((((next.avgFilterMs || 0) * (runs - 1)) + last) / runs);
    next.filterRuns = runs;
    next.lastFilterMs = last;
    next.avgFilterMs = avg;
    return next;
}

// Records the outcome of a mode load (cache hit/miss, success/failure, duration).
// Updates both the top-level aggregate counters and the per-mode entry for `modeKey`.
// Returns a new metrics object.
function recordLoadMetric(metrics, modeKey, durationMs, cacheHit, success) {
    var next = Object.assign({}, metrics);
    if (!next.perMode)
        next.perMode = {};
    var current = Object.assign({
        loads: 0,
        cacheHits: 0,
        cacheMisses: 0,
        failures: 0,
        lastLoadMs: 0,
        avgLoadMs: 0
    }, next.perMode[modeKey] || {});

    current.loads += 1;
    if (cacheHit) {
        current.cacheHits += 1;
        next.cacheHits = (next.cacheHits || 0) + 1;
    } else {
        current.cacheMisses += 1;
        next.cacheMisses = (next.cacheMisses || 0) + 1;
    }
    if (!success) {
        current.failures += 1;
        next.commandFailures = (next.commandFailures || 0) + 1;
    }

    var clampedDuration = Math.max(0, Math.round(durationMs || 0));
    current.lastLoadMs = clampedDuration;
    current.avgLoadMs = Math.round((((current.avgLoadMs || 0) * (current.loads - 1)) + clampedDuration) / current.loads);
    next.perMode[modeKey] = current;
    return next;
}
