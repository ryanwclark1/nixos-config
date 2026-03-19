import { describe, it, expect } from "vitest";
import {
  fuzzyMatchLower,
  safeCalcEval,
  stripSearchPrefix,
  compareByScoreThenUsage,
  compareByScoreOnly,
  highlightMatch,
  ensureItemRankCache,
  compareLauncherItemsAlpha,
} from "../../src/launcher/LauncherSearch.js";

// ---------------------------------------------------------------------------
// fuzzyMatchLower
// ---------------------------------------------------------------------------

describe("fuzzyMatchLower", () => {
  it("returns 100 for empty pattern", () => {
    expect(fuzzyMatchLower("anything", "")).toBe(100);
    expect(fuzzyMatchLower("anything", null)).toBe(100);
  });

  it("returns 0 for empty string with non-empty pattern", () => {
    expect(fuzzyMatchLower("", "abc")).toBe(0);
    expect(fuzzyMatchLower(null, "abc")).toBe(0);
  });

  it("scores prefix match > substring match > fuzzy match", () => {
    const prefix = fuzzyMatchLower("firefox", "fire");
    const substring = fuzzyMatchLower("pale-firefox", "fire");
    const fuzzy = fuzzyMatchLower("fbigreox", "fire");

    expect(prefix).toBeGreaterThan(substring);
    expect(substring).toBeGreaterThan(fuzzy);
  });

  it("gives highest score for exact prefix match", () => {
    // Prefix: 100 + len/len = 101
    expect(fuzzyMatchLower("abc", "abc")).toBeGreaterThan(100);
  });

  it("returns 0 when fuzzy match fails entirely", () => {
    expect(fuzzyMatchLower("abc", "xyz")).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// safeCalcEval
// ---------------------------------------------------------------------------

describe("safeCalcEval", () => {
  it("evaluates basic arithmetic", () => {
    expect(safeCalcEval("2+3")).toBe(5);
    expect(safeCalcEval("10-4")).toBe(6);
    expect(safeCalcEval("3*7")).toBe(21);
    expect(safeCalcEval("20/4")).toBe(5);
  });

  it("respects parentheses and operator precedence", () => {
    expect(safeCalcEval("(2+3)*4")).toBe(20);
    expect(safeCalcEval("2+3*4")).toBe(14);
  });

  it("handles decimals", () => {
    expect(safeCalcEval("3.5+1.5")).toBe(5);
    expect(safeCalcEval("0.1+0.2")).toBeCloseTo(0.3);
  });

  it("handles negative numbers", () => {
    expect(safeCalcEval("-5+3")).toBe(-2);
    expect(safeCalcEval("(-3)*(-2)")).toBe(6);
  });

  it("returns NaN for pure non-math input", () => {
    expect(safeCalcEval("hello")).toBeNaN();
    expect(safeCalcEval("abc+def")).toBeNaN();
  });

  it("sanitizes letters but evaluates remaining math", () => {
    // "alert(1)" → strip letters → "(1)" → 1
    expect(safeCalcEval("alert(1)")).toBe(1);
  });

  it("returns NaN for empty input", () => {
    expect(safeCalcEval("")).toBeNaN();
  });
});

// ---------------------------------------------------------------------------
// stripSearchPrefix
// ---------------------------------------------------------------------------

describe("stripSearchPrefix", () => {
  it("strips > for run mode", () => {
    expect(stripSearchPrefix("run", ">ls -la")).toBe("ls -la");
  });

  it("strips ; for ssh mode", () => {
    expect(stripSearchPrefix("ssh", ";myhost")).toBe("myhost");
  });

  it("strips : for emoji mode", () => {
    expect(stripSearchPrefix("emoji", ":smile")).toBe("smile");
  });

  it("strips / for files mode", () => {
    expect(stripSearchPrefix("files", "/config")).toBe("config");
  });

  it("strips @ for bookmarks mode", () => {
    expect(stripSearchPrefix("bookmarks", "@github")).toBe("github");
  });

  it("returns unmodified text for drun (no prefix)", () => {
    expect(stripSearchPrefix("drun", "firefox")).toBe("firefox");
  });

  it("returns unmodified text when prefix doesn't match", () => {
    expect(stripSearchPrefix("run", "firefox")).toBe("firefox");
  });
});

// ---------------------------------------------------------------------------
// Comparators
// ---------------------------------------------------------------------------

describe("compareByScoreThenUsage", () => {
  it("sorts by score descending", () => {
    const a = { name: "A", _score: 80 };
    const b = { name: "B", _score: 100 };
    expect(compareByScoreThenUsage(a, b)).toBeGreaterThan(0);
  });

  it("uses usage as tiebreaker when scores equal", () => {
    const a = { name: "A", _score: 50, _usageScore: 10 };
    const b = { name: "B", _score: 50, _usageScore: 20 };
    expect(compareByScoreThenUsage(a, b)).toBeGreaterThan(0);
  });

  it("falls back to alphabetical when score and usage match", () => {
    const a = { name: "Banana", _score: 50, _usageScore: 5 };
    const b = { name: "Apple", _score: 50, _usageScore: 5 };
    expect(compareByScoreThenUsage(a, b)).toBeGreaterThan(0); // B > A alphabetically
  });
});

describe("compareByScoreOnly", () => {
  it("sorts by score descending", () => {
    const a = { _score: 80 };
    const b = { _score: 100 };
    expect(compareByScoreOnly(a, b)).toBeGreaterThan(0);
  });

  it("returns 0 for equal scores", () => {
    expect(compareByScoreOnly({ _score: 50 }, { _score: 50 })).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// highlightMatch
// ---------------------------------------------------------------------------

describe("highlightMatch", () => {
  it("returns original text for empty query", () => {
    expect(highlightMatch("Firefox", "")).toBe("Firefox");
    expect(highlightMatch("Firefox", null)).toBe("Firefox");
  });

  it("wraps direct substring match in bold", () => {
    expect(highlightMatch("Firefox", "fire")).toBe("<b>Fire</b>fox");
  });

  it("handles fuzzy match with non-contiguous chars", () => {
    const result = highlightMatch("Firefox", "frx");
    expect(result).toContain("<b>");
    // Each matched char should be bolded
    expect(result).toMatch(/<b>F<\/b>/);
  });
});

// ---------------------------------------------------------------------------
// ensureItemRankCache
// ---------------------------------------------------------------------------

describe("ensureItemRankCache", () => {
  it("populates cache fields on first call", () => {
    const item = { name: "Firefox", title: "Web Browser", category: "Network" };
    ensureItemRankCache(item);

    expect(item._rankCacheReady).toBe(true);
    expect(item._nameLower).toBe("firefox");
    expect(item._titleLower).toBe("web browser");
    expect(item._primaryCategoryKey).toBe("network");
  });

  it("skips if already cached", () => {
    const item = { name: "Firefox", _rankCacheReady: true, _nameLower: "custom" };
    ensureItemRankCache(item);
    expect(item._nameLower).toBe("custom"); // unchanged
  });

  it("handles null/undefined gracefully", () => {
    expect(() => ensureItemRankCache(null)).not.toThrow();
    expect(() => ensureItemRankCache(undefined)).not.toThrow();
  });
});

// ---------------------------------------------------------------------------
// compareLauncherItemsAlpha
// ---------------------------------------------------------------------------

describe("compareLauncherItemsAlpha", () => {
  it("sorts by name alphabetically", () => {
    expect(compareLauncherItemsAlpha({ name: "Apple" }, { name: "Banana" })).toBeLessThan(0);
    expect(compareLauncherItemsAlpha({ name: "Banana" }, { name: "Apple" })).toBeGreaterThan(0);
  });

  it("falls back to exec then title on name tie", () => {
    const a = { name: "App", exec: "app-a", title: "" };
    const b = { name: "App", exec: "app-b", title: "" };
    expect(compareLauncherItemsAlpha(a, b)).toBeLessThan(0);
  });
});
