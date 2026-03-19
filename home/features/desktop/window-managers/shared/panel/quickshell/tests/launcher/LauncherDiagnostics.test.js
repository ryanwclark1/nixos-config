import { describe, it, expect } from "vitest";
import {
  filesBackendStatusObject,
  drunCategoryStateObject,
  escapeActionStateObject,
  launcherStateObject,
} from "../../src/launcher/LauncherDiagnostics.js";

describe("filesBackendStatusObject", () => {
  it("structures file backend metrics", () => {
    const result = filesBackendStatusObject({
      filesBackendLabel: "fd",
      fileSearchBackend: "fd",
      fileIndexReady: true,
      fileIndexBuilding: false,
      fileIndexItemsLength: 5000,
      filesCacheStatsLabel: "80% hit rate",
      launcherMetrics: { filesFdLoads: 3, filesFdAvgMs: 42 },
      modeMetricFn: () => ({ cacheHits: 10, cacheMisses: 2 }),
    });
    expect(result.backend).toBe("fd");
    expect(result.indexReady).toBe(true);
    expect(result.indexSize).toBe(5000);
    expect(result.metrics.filesFdLoads).toBe(3);
    expect(result.cache.hits).toBe(10);
    expect(result.cache.hitRateLabel).toBe("80% hit rate");
  });
});

describe("drunCategoryStateObject", () => {
  it("builds category state with selected option", () => {
    const result = drunCategoryStateObject({
      drunCategoryOptions: [
        { key: "", label: "All", count: 100 },
        { key: "network", label: "Internet", count: 15 },
      ],
      drunCategoryFilter: "network",
      drunCategoryFiltersEnabled: true,
      mode: "drun",
      showLauncherHome: true,
      formatLabelFn: (k) => k,
    });
    expect(result.visible).toBe(true);
    expect(result.activeKey).toBe("network");
    expect(result.activeLabel).toBe("Internet");
    expect(result.activeCount).toBe(15);
    expect(result.totalCount).toBe(100);
  });

  it("falls back to first option when filter not found", () => {
    const result = drunCategoryStateObject({
      drunCategoryOptions: [{ key: "", label: "All", count: 50 }],
      drunCategoryFilter: "bogus",
      drunCategoryFiltersEnabled: true,
      mode: "drun",
      showLauncherHome: true,
      formatLabelFn: (k) => k,
    });
    expect(result.activeKey).toBe("");
    expect(result.activeLabel).toBe("All");
  });

  it("is not visible when disabled or wrong mode", () => {
    const result = drunCategoryStateObject({
      drunCategoryOptions: [{ key: "", count: 10 }],
      drunCategoryFilter: "",
      drunCategoryFiltersEnabled: false,
      mode: "drun",
      showLauncherHome: true,
      formatLabelFn: (k) => k,
    });
    expect(result.visible).toBe(false);
  });
});

describe("escapeActionStateObject", () => {
  it('returns "close" for default state', () => {
    const result = escapeActionStateObject({
      showingConfirm: false,
      searchText: "",
      drunCategoryFiltersEnabled: false,
      mode: "drun",
      drunCategoryFilter: "",
      drunCategorySectionExpanded: false,
    });
    expect(result.action).toBe("close");
  });

  it('returns "cancelConfirm" when showing confirm', () => {
    const result = escapeActionStateObject({
      showingConfirm: true,
      searchText: "",
      drunCategoryFiltersEnabled: false,
      mode: "drun",
      drunCategoryFilter: "",
    });
    expect(result.action).toBe("cancelConfirm");
  });

  it('returns "resetQuery" when there is search text', () => {
    const result = escapeActionStateObject({
      showingConfirm: false,
      searchText: "hello",
      drunCategoryFiltersEnabled: false,
      mode: "drun",
      drunCategoryFilter: "",
    });
    expect(result.action).toBe("resetQuery");
  });

  it('returns "resetCategory" for active drun category filter', () => {
    const result = escapeActionStateObject({
      showingConfirm: false,
      searchText: "",
      drunCategoryFiltersEnabled: true,
      mode: "drun",
      drunCategoryFilter: "network",
      drunCategorySectionExpanded: false,
    });
    expect(result.action).toBe("resetCategory");
  });

  it('returns "collapseCategorySummary" when section expanded', () => {
    const result = escapeActionStateObject({
      showingConfirm: false,
      searchText: "",
      drunCategoryFiltersEnabled: true,
      mode: "drun",
      drunCategoryFilter: "",
      drunCategorySectionExpanded: true,
    });
    expect(result.action).toBe("collapseCategorySummary");
  });
});

describe("launcherStateObject", () => {
  it("structures launcher viewport state", () => {
    const result = launcherStateObject({
      launcherOpacity: 1,
      mode: "drun",
      searchText: "fire",
      showLauncherHome: false,
      filteredItemsLength: 5,
      allItemsLength: 100,
      selectedIndex: 0,
      width: 800,
      height: 600,
    });
    expect(result.visible).toBe(true);
    expect(result.mode).toBe("drun");
    expect(result.hasResults).toBe(true);
    expect(result.filteredItemCount).toBe(5);
  });

  it("reports invisible when opacity is 0", () => {
    const result = launcherStateObject({ launcherOpacity: 0 });
    expect(result.visible).toBe(false);
  });
});
