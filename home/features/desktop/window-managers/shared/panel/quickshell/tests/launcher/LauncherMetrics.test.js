import { describe, it, expect } from "vitest";
import {
  freshMetrics,
  modeMetric,
  recordFilesBackendLoad,
  recordFilesBackendResolveMetric,
  recordFilterMetric,
  recordLoadMetric,
} from "../../src/launcher/LauncherMetrics.js";

describe("freshMetrics", () => {
  it("returns zeroed metrics", () => {
    const m = freshMetrics();
    expect(m.opens).toBe(0);
    expect(m.filterRuns).toBe(0);
    expect(m.perMode).toEqual({});
  });
});

describe("modeMetric", () => {
  it("returns zeroed default for absent mode", () => {
    const m = modeMetric(freshMetrics(), "drun");
    expect(m.loads).toBe(0);
    expect(m.avgLoadMs).toBe(0);
  });
});

describe("immutability", () => {
  it("does not mutate top-level scalar properties", () => {
    const original = freshMetrics();
    const next = recordFilterMetric(original, 10);
    expect(original.filterRuns).toBe(0);
    expect(next.filterRuns).toBe(1);
  });

  it("returns new object from each record call", () => {
    const m1 = freshMetrics();
    const m2 = recordFilterMetric(m1, 10);
    expect(m1).not.toBe(m2);
  });

  // Note: perMode uses shallow Object.assign, so nested objects may be shared.
  // This is a known limitation — QML always reassigns the whole metrics object.
});

describe("recordFilterMetric", () => {
  it("increments filter run count and computes average", () => {
    let m = freshMetrics();
    m = recordFilterMetric(m, 10);
    expect(m.filterRuns).toBe(1);
    expect(m.lastFilterMs).toBe(10);
    expect(m.avgFilterMs).toBe(10);

    m = recordFilterMetric(m, 30);
    expect(m.filterRuns).toBe(2);
    expect(m.lastFilterMs).toBe(30);
    expect(m.avgFilterMs).toBe(20); // (10+30)/2
  });
});

describe("recordFilesBackendLoad", () => {
  it("tracks fd backend separately from find", () => {
    let m = freshMetrics();
    m = recordFilesBackendLoad(m, "fd", 100);
    m = recordFilesBackendLoad(m, "find", 200);
    expect(m.filesFdLoads).toBe(1);
    expect(m.filesFdLastMs).toBe(100);
    expect(m.filesFindLoads).toBe(1);
    expect(m.filesFindLastMs).toBe(200);
  });
});

describe("recordFilesBackendResolveMetric", () => {
  it("tracks resolve passes", () => {
    let m = freshMetrics();
    m = recordFilesBackendResolveMetric(m, 15);
    m = recordFilesBackendResolveMetric(m, 25);
    expect(m.filesResolveRuns).toBe(2);
    expect(m.filesResolveLastMs).toBe(25);
    expect(m.filesResolveAvgMs).toBe(20);
  });
});

describe("recordLoadMetric", () => {
  it("tracks cache hits, misses, and failures per mode", () => {
    let m = freshMetrics();
    m = recordLoadMetric(m, "drun", 50, true, true);
    m = recordLoadMetric(m, "drun", 100, false, true);
    m = recordLoadMetric(m, "drun", 200, false, false);

    expect(m.cacheHits).toBe(1);
    expect(m.cacheMisses).toBe(2);
    expect(m.commandFailures).toBe(1);

    const dm = modeMetric(m, "drun");
    expect(dm.loads).toBe(3);
    expect(dm.cacheHits).toBe(1);
    expect(dm.cacheMisses).toBe(2);
    expect(dm.failures).toBe(1);
    expect(dm.lastLoadMs).toBe(200);
  });
});
