import { describe, it, expect } from "vitest";
import { buildDrunHome } from "../../src/launcher/LauncherHomeBuilder.js";

// This file exercises the cross-import:
// LauncherHomeBuilder.js .import "LauncherSearch.js" as Search

const mkApp = (name, exec) => ({ name, exec, category: "Utility" });

const mkConfig = (overrides = {}) => ({
  recentAppsLimit: 4,
  suggestionsLimit: 2,
  itemMatchesDrunCategory: () => true,
  ...overrides,
});

const mkTracker = (scores = {}) => ({
  getUsageScore: (exec) => scores[exec] || 0,
});

describe("buildDrunHome", () => {
  it("builds recent items from launch history", () => {
    const apps = [mkApp("Firefox", "firefox"), mkApp("Files", "nautilus")];
    const history = [
      { exec: "firefox", timestamp: 2 },
      { exec: "nautilus", timestamp: 1 },
    ];
    const result = buildDrunHome(apps, history, "", mkTracker(), mkConfig());
    expect(result.recentItems).toHaveLength(2);
    expect(result.recentItems[0].name).toBe("Firefox"); // higher timestamp
  });

  it("fills recent with usage-ranked apps when history is short", () => {
    const apps = [
      mkApp("Firefox", "firefox"),
      mkApp("Files", "nautilus"),
      mkApp("Terminal", "term"),
    ];
    const history = [{ exec: "firefox", timestamp: 1 }];
    const tracker = mkTracker({ nautilus: 10, term: 5 });
    const result = buildDrunHome(apps, history, "", tracker, mkConfig());
    // Firefox from history + nautilus and term from usage
    expect(result.recentItems.length).toBeGreaterThan(1);
  });

  it("returns suggestions from usage-ranked apps not in recents", () => {
    const apps = [
      mkApp("Firefox", "firefox"),
      mkApp("Files", "nautilus"),
      mkApp("Code", "code"),
    ];
    const history = [{ exec: "firefox", timestamp: 1 }];
    const tracker = mkTracker({ code: 8, nautilus: 5 });
    const config = mkConfig({ recentAppsLimit: 1, suggestionsLimit: 2 });
    // Firefox fills the 1 recent slot; usage fills rest
    const result = buildDrunHome(apps, history, "", tracker, config);
    // Suggestions should be apps not in recent
    expect(result.suggestionItems.length).toBeGreaterThan(0);
  });

  it("filters by category when filter is set", () => {
    const apps = [
      mkApp("Firefox", "firefox"),
      mkApp("Files", "nautilus"),
    ];
    const history = [
      { exec: "firefox", timestamp: 2 },
      { exec: "nautilus", timestamp: 1 },
    ];
    const config = mkConfig({
      itemMatchesDrunCategory: (item, cat) => cat === "" || item.name === "Firefox",
    });
    const result = buildDrunHome(apps, history, "network", mkTracker(), config);
    expect(result.recentItems.every((i) => i.name === "Firefox")).toBe(true);
  });

  it("returns empty for no apps", () => {
    const result = buildDrunHome([], [], "", mkTracker(), mkConfig());
    expect(result.recentItems).toEqual([]);
    expect(result.suggestionItems).toEqual([]);
  });

  it("skips history entries with no matching app", () => {
    const apps = [mkApp("Firefox", "firefox")];
    const history = [
      { exec: "deleted-app", timestamp: 2 },
      { exec: "firefox", timestamp: 1 },
    ];
    const result = buildDrunHome(apps, history, "", mkTracker(), mkConfig());
    expect(result.recentItems).toHaveLength(1);
    expect(result.recentItems[0].name).toBe("Firefox");
  });
});
