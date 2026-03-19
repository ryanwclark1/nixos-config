import { describe, it, expect } from "vitest";
import {
  buildCategoryOptions,
  validateCategoryFilter,
} from "../../src/launcher/LauncherCategoryHelpers.js";

// This file also exercises the cross-import:
// LauncherCategoryHelpers.js .import "LauncherSearch.js" as Search

describe("buildCategoryOptions", () => {
  const formatLabel = (key) => key.charAt(0).toUpperCase() + key.slice(1);

  it("builds category options from app list", () => {
    const apps = [
      { name: "Firefox", category: "Network" },
      { name: "Chrome", category: "Network" },
      { name: "Files", category: "Utility" },
    ];
    const options = buildCategoryOptions(apps, formatLabel);
    // First entry is always "All"
    expect(options[0]).toMatchObject({ key: "", label: "All", count: 3 });
    // Subsequent entries sorted by count desc
    expect(options[1].key).toBe("network"); // 2 apps
    expect(options[1].count).toBe(2);
    expect(options[2].key).toBe("utility"); // 1 app
  });

  it('assigns hotkeys "0" through "9"', () => {
    const apps = [
      { name: "A", category: "Cat1" },
      { name: "B", category: "Cat2" },
    ];
    const options = buildCategoryOptions(apps, formatLabel);
    expect(options[0].hotkey).toBe("0");
    expect(options[1].hotkey).toBe("1");
    expect(options[2].hotkey).toBe("2");
  });

  it("limits to 9 categories + All", () => {
    const apps = [];
    for (let i = 0; i < 20; i++) {
      apps.push({ name: "App" + i, category: "Cat" + i });
    }
    const options = buildCategoryOptions(apps, formatLabel);
    expect(options.length).toBeLessThanOrEqual(10);
  });

  it("returns just All for empty apps", () => {
    const options = buildCategoryOptions([], formatLabel);
    expect(options).toHaveLength(1);
    expect(options[0].key).toBe("");
  });
});

describe("validateCategoryFilter", () => {
  const options = [
    { key: "", label: "All" },
    { key: "network", label: "Internet" },
  ];

  it("returns filter if it exists in options", () => {
    expect(validateCategoryFilter("network", options)).toBe("network");
  });

  it('returns "" for non-existent filter', () => {
    expect(validateCategoryFilter("bogus", options)).toBe("");
  });
});
