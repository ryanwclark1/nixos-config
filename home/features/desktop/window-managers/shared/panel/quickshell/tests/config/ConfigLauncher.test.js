import { describe, it, expect } from "vitest";
import {
  toInt,
  toReal,
  clampInt,
  clampReal,
  asBool,
  normalizeModeList,
  normalizePrimaryModeList,
  normalizeWebProviderOrder,
  normalizeWebAliases,
  normalizeCustomEngines,
  normalizeCharacterTrigger,
  applyLauncherConfig,
} from "../../src/services/config/ConfigLauncher.js";

// ---------------------------------------------------------------------------
// Primitive converters
// ---------------------------------------------------------------------------

describe("toInt", () => {
  it("parses valid integers", () => {
    expect(toInt("42", 0)).toBe(42);
    expect(toInt(100, 0)).toBe(100);
  });

  it("returns fallback for non-numeric", () => {
    expect(toInt("abc", 10)).toBe(10);
    expect(toInt(undefined, 5)).toBe(5);
    expect(toInt(null, 7)).toBe(7);
  });
});

describe("toReal", () => {
  it("parses decimals", () => {
    expect(toReal("3.14", 0)).toBeCloseTo(3.14);
  });

  it("returns fallback for NaN", () => {
    expect(toReal("not-a-number", 1.0)).toBe(1.0);
  });
});

describe("clampInt", () => {
  it("clamps below minimum", () => {
    expect(clampInt(-5, 0, 100, 50)).toBe(0);
  });

  it("clamps above maximum", () => {
    expect(clampInt(200, 0, 100, 50)).toBe(100);
  });

  it("passes through valid values", () => {
    expect(clampInt(42, 0, 100, 50)).toBe(42);
  });

  it("uses fallback for invalid input", () => {
    expect(clampInt("bad", 0, 100, 50)).toBe(50);
  });
});

describe("clampReal", () => {
  it("clamps within range", () => {
    expect(clampReal(0.05, 0.1, 4.0, 1.0)).toBe(0.1);
    expect(clampReal(5.0, 0.1, 4.0, 1.0)).toBe(4.0);
    expect(clampReal(2.5, 0.1, 4.0, 1.0)).toBe(2.5);
  });
});

describe("asBool", () => {
  it("passes through boolean values", () => {
    expect(asBool(true, false)).toBe(true);
    expect(asBool(false, true)).toBe(false);
  });

  it("parses string booleans", () => {
    expect(asBool("true", false)).toBe(true);
    expect(asBool("false", true)).toBe(false);
  });

  it("returns fallback for other values", () => {
    expect(asBool("yes", true)).toBe(true);
    expect(asBool(42, false)).toBe(false);
    expect(asBool(null, true)).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// normalizeModeList
// ---------------------------------------------------------------------------

describe("normalizeModeList", () => {
  const fallback = ["drun", "files", "web"];

  it("filters to allowed modes and deduplicates", () => {
    const result = normalizeModeList(
      ["drun", "drun", "files", "bogus"],
      fallback
    );
    expect(result).toEqual(["drun", "files"]);
  });

  it("returns fallback when input is empty or not array", () => {
    expect(normalizeModeList(null, fallback)).toEqual(fallback);
    expect(normalizeModeList([], fallback)).toEqual(fallback);
  });

  it("returns fallback when all modes are invalid", () => {
    expect(normalizeModeList(["x", "y"], fallback)).toEqual(fallback);
  });

  it("accepts all valid mode keys", () => {
    const valid = ["drun", "window", "files", "ai", "clip", "emoji", "calc", "web",
      "plugins", "run", "system", "keybinds", "media", "nixos", "wallpapers", "bookmarks",
      "settings", "devops", "orchestrator", "ssh"];
    expect(normalizeModeList(valid, fallback)).toEqual(valid);
  });
});

// ---------------------------------------------------------------------------
// normalizePrimaryModeList
// ---------------------------------------------------------------------------

describe("normalizePrimaryModeList", () => {
  const fallback = ["drun", "window", "files", "ai", "system"];

  it("filters primary modes to enabled modes", () => {
    expect(
      normalizePrimaryModeList(
        ["drun", "settings", "web"],
        ["drun", "web", "ssh"],
        fallback
      )
    ).toEqual(["drun", "web"]);
  });

  it("falls back to supported defaults when primaries are invalid", () => {
    expect(
      normalizePrimaryModeList(["bogus"], ["files", "ssh"], fallback)
    ).toEqual(["files"]);
  });
});

// ---------------------------------------------------------------------------
// normalizeWebProviderOrder
// ---------------------------------------------------------------------------

describe("normalizeWebProviderOrder", () => {
  const fallback = ["duckduckgo", "google"];
  const catalogKeys = ["duckduckgo", "google", "youtube", "brave"];

  it("filters to catalog keys", () => {
    expect(
      normalizeWebProviderOrder(["google", "fake", "youtube"], fallback, catalogKeys)
    ).toEqual(["google", "youtube"]);
  });

  it("deduplicates", () => {
    expect(
      normalizeWebProviderOrder(["google", "google"], fallback, catalogKeys)
    ).toEqual(["google"]);
  });

  it("returns fallback for empty/null input", () => {
    expect(normalizeWebProviderOrder(null, fallback, catalogKeys)).toEqual(fallback);
  });
});

// ---------------------------------------------------------------------------
// normalizeWebAliases
// ---------------------------------------------------------------------------

describe("normalizeWebAliases", () => {
  const fallbackMap = { google: ["g"], ddg: ["d", "duck"] };
  const catalogKeys = ["google", "ddg"];

  it("uses provided aliases", () => {
    const result = normalizeWebAliases(
      { google: ["goo"], ddg: ["dd"] },
      fallbackMap,
      catalogKeys
    );
    expect(result.google).toEqual(["goo"]);
    expect(result.ddg).toEqual(["dd"]);
  });

  it("falls back to defaults when provider has no custom aliases", () => {
    const result = normalizeWebAliases({}, fallbackMap, catalogKeys);
    expect(result.google).toEqual(["g"]);
    expect(result.ddg).toEqual(["d", "duck"]);
  });

  it("rejects invalid alias tokens", () => {
    const result = normalizeWebAliases(
      { google: ["g", "!!!invalid", ""] },
      fallbackMap,
      catalogKeys
    );
    expect(result.google).toEqual(["g"]);
  });

  it("prevents duplicate aliases across providers", () => {
    const result = normalizeWebAliases(
      { google: ["g"], ddg: ["g", "d"] },
      fallbackMap,
      catalogKeys
    );
    expect(result.google).toEqual(["g"]);
    // "g" already taken by google, so ddg only gets "d"
    expect(result.ddg).toEqual(["d"]);
  });

  it("skips alias that matches its own provider key", () => {
    const result = normalizeWebAliases(
      { google: ["google", "g"] },
      fallbackMap,
      catalogKeys
    );
    expect(result.google).toEqual(["g"]);
  });

  it("parses comma/space-separated strings", () => {
    const result = normalizeWebAliases(
      { google: "goo, ggl" },
      fallbackMap,
      catalogKeys
    );
    expect(result.google).toEqual(["goo", "ggl"]);
  });
});

// ---------------------------------------------------------------------------
// normalizeCustomEngines
// ---------------------------------------------------------------------------

describe("normalizeCustomEngines", () => {
  it("returns valid engines", () => {
    const result = normalizeCustomEngines([
      { key: "my-search", name: "My Search", exec: "https://search.me/?q=" },
    ]);
    expect(result).toHaveLength(1);
    expect(result[0]).toMatchObject({
      key: "my-search",
      name: "My Search",
      exec: "https://search.me/?q=",
      icon: "globe-search.svg",
    });
  });

  it("strips invalid characters from keys", () => {
    const result = normalizeCustomEngines([
      { key: "My Search!", name: "X", exec: "https://x.com" },
    ]);
    expect(result[0].key).toBe("mysearch");
  });

  it("rejects entries without name or exec", () => {
    expect(normalizeCustomEngines([{ key: "a", name: "", exec: "x" }])).toEqual([]);
    expect(normalizeCustomEngines([{ key: "a", name: "A", exec: "" }])).toEqual([]);
  });

  it("deduplicates by key", () => {
    const result = normalizeCustomEngines([
      { key: "foo", name: "Foo1", exec: "https://1" },
      { key: "foo", name: "Foo2", exec: "https://2" },
    ]);
    expect(result).toHaveLength(1);
    expect(result[0].name).toBe("Foo1");
  });

  it("limits to 50 entries", () => {
    const many = Array.from({ length: 60 }, (_, i) => ({
      key: "e" + i,
      name: "E" + i,
      exec: "https://e" + i,
    }));
    expect(normalizeCustomEngines(many)).toHaveLength(50);
  });

  it("returns empty array for non-array input", () => {
    expect(normalizeCustomEngines(null)).toEqual([]);
    expect(normalizeCustomEngines("string")).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// normalizeCharacterTrigger
// ---------------------------------------------------------------------------

describe("normalizeCharacterTrigger", () => {
  it('defaults to ":" for empty/null', () => {
    expect(normalizeCharacterTrigger("")).toBe(":");
    expect(normalizeCharacterTrigger(null)).toBe(":");
  });

  it("preserves valid triggers", () => {
    expect(normalizeCharacterTrigger(":")).toBe(":");
    expect(normalizeCharacterTrigger("::")).toBe("::");
    expect(normalizeCharacterTrigger("e:")).toBe("e:");
  });

  it("truncates to 4 characters", () => {
    expect(normalizeCharacterTrigger("abcde")).toBe("abcd");
  });

  it('rejects triggers containing whitespace (returns ":")', () => {
    expect(normalizeCharacterTrigger("a b")).toBe(":");
  });
});

// ---------------------------------------------------------------------------
// applyLauncherConfig (integration)
// ---------------------------------------------------------------------------

describe("applyLauncherConfig", () => {
  it("populates config with defaults when data is empty", () => {
    const config = {};
    applyLauncherConfig(config, {});
    expect(config.launcherDefaultMode).toBe("drun");
    expect(config.launcherMaxResults).toBe(80);
    expect(config.launcherFileMinQueryLength).toBe(1);
    expect(config.launcherFileSearchRoot).toBe("~");
    expect(config.launcherShowModeHints).toBe(true);
    expect(config.launcherTabBehavior).toBe("contextual");
    expect(config.launcherScoreNameWeight).toBe(1.0);
  });

  it("applies overrides from data", () => {
    const config = {};
    applyLauncherConfig(config, {
      launcher: {
        maxResults: 200,
        showModeHints: false,
        defaultMode: "files",
        enabledModes: ["drun", "files", "web"],
        primaryModes: ["drun", "web", "settings"],
      },
    });
    expect(config.launcherMaxResults).toBe(200);
    expect(config.launcherShowModeHints).toBe(false);
    expect(config.launcherDefaultMode).toBe("files");
    expect(config.launcherPrimaryModes).toEqual(["drun", "web"]);
  });

  it("clamps out-of-range values", () => {
    const config = {};
    applyLauncherConfig(config, {
      launcher: { maxResults: 9999, fileMinQueryLength: 0, searchDebounceMs: -5 },
    });
    expect(config.launcherMaxResults).toBe(400);
    expect(config.launcherFileMinQueryLength).toBe(1);
    expect(config.launcherSearchDebounceMs).toBe(0);
  });

  it("falls back defaultMode when not in enabledModes", () => {
    const config = {};
    applyLauncherConfig(config, {
      launcher: { defaultMode: "nixos", enabledModes: ["drun", "web"] },
    });
    expect(config.launcherDefaultMode).toBe("drun");
  });
});
