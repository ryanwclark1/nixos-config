import { describe, it, expect } from "vitest";
import { fuzzyScore, filterByFuzzy } from "../../src/services/SearchUtils.js";

describe("fuzzyScore", () => {
  it("returns 0 for null/empty inputs", () => {
    expect(fuzzyScore("", "target")).toBe(0);
    expect(fuzzyScore("query", "")).toBe(0);
    expect(fuzzyScore(null, "target")).toBe(0);
  });

  it("gives highest score for exact substring at start", () => {
    const start = fuzzyScore("fire", "firefox browser");
    const middle = fuzzyScore("fox", "firefox browser");
    expect(start).toBeGreaterThan(1000);
    expect(middle).toBeGreaterThan(1000);
    // Start position bonus makes "fire" score higher
    expect(start).toBeGreaterThan(middle);
  });

  it("scores fuzzy matches lower than exact", () => {
    const exact = fuzzyScore("fire", "firefox");
    const fuzzy = fuzzyScore("frfx", "firefox");
    expect(exact).toBeGreaterThan(fuzzy);
  });

  it("returns 0 when not all chars match", () => {
    expect(fuzzyScore("xyz", "firefox")).toBe(0);
  });

  it("gives bonus for word-boundary matches over non-boundary fuzzy", () => {
    // "fb" in "file browser" is fuzzy (f...b at word boundary)
    // "fb" in "xfxbx" is also fuzzy but no boundary bonus
    const boundary = fuzzyScore("fb", "file browser");
    const nobound = fuzzyScore("fb", "xfxbx");
    expect(boundary).toBeGreaterThan(nobound);
  });

  it("respects minFuzzyLength option", () => {
    // Single-char query below min length → 0 (unless exact substring)
    expect(fuzzyScore("f", "firefox", { minFuzzyLength: 2 })).toBeGreaterThan(0); // exact substring
    expect(fuzzyScore("z", "firefox", { minFuzzyLength: 2 })).toBe(0); // no match
  });

  it("respects minFuzzyScore threshold", () => {
    // Very weak fuzzy match should be filtered out
    const weak = fuzzyScore("az", "abcdefghijklmnopqrstuvwxyz");
    expect(fuzzyScore("az", "abcdefghijklmnopqrstuvwxyz", { minFuzzyScore: 9999 })).toBe(0);
  });
});

describe("filterByFuzzy", () => {
  const items = [
    { name: "Firefox Browser" },
    { name: "Files Manager" },
    { name: "Terminal" },
    { name: "System Monitor" },
  ];
  const textFn = (item) => item.name.toLowerCase();

  it("returns all items for empty query", () => {
    expect(filterByFuzzy(items, "", textFn)).toEqual(items);
  });

  it("returns matched items sorted by score", () => {
    const result = filterByFuzzy(items, "fire", textFn);
    expect(result).toHaveLength(1);
    expect(result[0].name).toBe("Firefox Browser");
  });

  it("handles fuzzy matches", () => {
    const result = filterByFuzzy(items, "fm", textFn);
    // "Files Manager" and potentially "System Monitor" match f+m
    expect(result.length).toBeGreaterThan(0);
    expect(result[0].name).toBe("Files Manager"); // better match
  });

  it("returns empty for no matches", () => {
    expect(filterByFuzzy(items, "zzz", textFn)).toEqual([]);
  });
});
