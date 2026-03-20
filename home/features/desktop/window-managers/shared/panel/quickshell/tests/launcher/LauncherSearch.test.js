import { describe, it, expect } from "vitest";
import {
  fuzzyMatchLower,
  safeCalcEval,
  stripSearchPrefix,
  browseFileItems,
  compareByScoreThenUsage,
  compareByScoreOnly,
  highlightMatch,
  ensureItemRankCache,
  compareLauncherItemsAlpha,
  cycleSelection,
  moveSelectionRelative,
  jumpSelectionBoundary,
  pageSelection,
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
// browseFileItems
// ---------------------------------------------------------------------------

describe("browseFileItems", () => {
  it("returns top-level entries only, with directories before files", () => {
    const items = [
      { name: "src", relativePath: "src", fileKind: "dir", pathDepth: 0, _fileUsageBoost: 0 },
      { name: "notes.md", relativePath: "notes.md", fileKind: "file", pathDepth: 0, _fileUsageBoost: 20 },
      { name: "nested.txt", relativePath: "src/nested.txt", fileKind: "file", pathDepth: 1, _fileUsageBoost: 999 },
      { name: "Downloads", relativePath: "Downloads", fileKind: "dir", pathDepth: 0, _fileUsageBoost: 5 },
    ];

    expect(browseFileItems(items, 10).map((item) => item.relativePath)).toEqual([
      "Downloads",
      "src",
      "notes.md",
    ]);
  });

  it("respects the result limit", () => {
    const items = [
      { relativePath: "a", fileKind: "dir", pathDepth: 0 },
      { relativePath: "b", fileKind: "dir", pathDepth: 0 },
      { relativePath: "c", fileKind: "file", pathDepth: 0 },
    ];

    expect(browseFileItems(items, 2)).toHaveLength(2);
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

// ---------------------------------------------------------------------------
// cycleSelection
// ---------------------------------------------------------------------------

describe("cycleSelection", () => {
  it("moves forward and wraps around at end", () => {
    // count=5, index=4, step=+1 → wraps to 0
    expect(cycleSelection(5, 4, 1)).toBe(0);
  });

  it("moves backward and wraps at beginning", () => {
    // count=5, index=0, step=-1 → wraps to 4
    expect(cycleSelection(5, 0, -1)).toBe(4);
  });

  it("advances by positive step without wrapping", () => {
    expect(cycleSelection(10, 3, 2)).toBe(5);
  });

  it("wraps when step exceeds count", () => {
    expect(cycleSelection(3, 2, 2)).toBe(1);
  });

  it("returns current index unchanged when count is 0", () => {
    expect(cycleSelection(0, 0, 1)).toBe(0);
  });

  it("returns current index unchanged when count is negative", () => {
    expect(cycleSelection(-1, 2, 1)).toBe(2);
  });

  it("handles step of 0 (no movement)", () => {
    expect(cycleSelection(5, 3, 0)).toBe(3);
  });
});

// ---------------------------------------------------------------------------
// moveSelectionRelative
// ---------------------------------------------------------------------------

describe("moveSelectionRelative", () => {
  it("moves forward within bounds", () => {
    expect(moveSelectionRelative(10, 3, 2)).toBe(5);
  });

  it("clamps at the last item (count - 1)", () => {
    expect(moveSelectionRelative(5, 3, 10)).toBe(4);
  });

  it("clamps at 0 when stepping backward past the start", () => {
    expect(moveSelectionRelative(5, 1, -5)).toBe(0);
  });

  it("stays at current index when step is 0", () => {
    expect(moveSelectionRelative(5, 2, 0)).toBe(2);
  });

  it("returns current index unchanged when count is 0", () => {
    expect(moveSelectionRelative(0, 0, 1)).toBe(0);
  });

  it("moves backward by 1", () => {
    expect(moveSelectionRelative(10, 5, -1)).toBe(4);
  });

  it("does not go below 0", () => {
    expect(moveSelectionRelative(10, 0, -1)).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// jumpSelectionBoundary
// ---------------------------------------------------------------------------

describe("jumpSelectionBoundary", () => {
  it("jumps to the last item when toEnd is true", () => {
    expect(jumpSelectionBoundary(10, true)).toBe(9);
  });

  it("jumps to the first item (0) when toEnd is false", () => {
    expect(jumpSelectionBoundary(10, false)).toBe(0);
  });

  it("returns 0 for empty list with toEnd true", () => {
    expect(jumpSelectionBoundary(0, true)).toBe(0);
  });

  it("returns 0 for empty list with toEnd false", () => {
    expect(jumpSelectionBoundary(0, false)).toBe(0);
  });

  it("returns 0 for single-item list at end", () => {
    expect(jumpSelectionBoundary(1, true)).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// pageSelection
// ---------------------------------------------------------------------------

describe("pageSelection", () => {
  it("pages forward by computed page size", () => {
    // hudHeight=360 → pageSize = round(360/72)=5 → index 0+5=5
    expect(pageSelection(20, 0, 1, 360)).toBe(5);
  });

  it("pages backward by computed page size", () => {
    // hudHeight=360 → pageSize=5 → index 10-5=5
    expect(pageSelection(20, 10, -1, 360)).toBe(5);
  });

  it("clamps at the last item when paging beyond end", () => {
    // hudHeight=360 → pageSize=5; index 18 + 5 = 23, clamped to 19
    expect(pageSelection(20, 18, 1, 360)).toBe(19);
  });

  it("clamps at 0 when paging backward beyond start", () => {
    expect(pageSelection(20, 2, -1, 360)).toBe(0);
  });

  it("uses minimum page size of 5 for very small hudHeight", () => {
    // hudHeight=10 → round(10/72)=0, clamp to min 5 → index 0+5=5
    expect(pageSelection(20, 0, 1, 10)).toBe(5);
  });

  it("uses maximum page size of 12 for very large hudHeight", () => {
    // hudHeight=2000 → round(2000/72)=28, clamp to max 12 → index 0+12=12
    expect(pageSelection(20, 0, 1, 2000)).toBe(12);
  });

  it("returns current index unchanged when count is 0", () => {
    expect(pageSelection(0, 3, 1, 360)).toBe(3);
  });
});
