import { describe, it, expect, vi } from "vitest";
import {
  primaryProvider,
  secondaryProvider,
  providerByKey,
  preferredProviderKey,
  buildWebTarget,
  buildWebRecent,
  deriveHomepage,
  selectWebProviderByKey,
  webProviderSlotFromKey,
  selectWebProviderBySlot,
  executeBangSearch,
} from "../../src/launcher/LauncherWebProviders.js";

const testProviders = [
  { key: "google", name: "Google", exec: "https://google.com/search?q=", home: "https://google.com/", icon: "G" },
  { key: "ddg", name: "DDG", exec: "https://ddg.gg/?q=", home: "https://ddg.gg/", icon: "D" },
];

describe("primaryProvider / secondaryProvider", () => {
  it("returns first/second provider", () => {
    expect(primaryProvider(testProviders).key).toBe("google");
    expect(secondaryProvider(testProviders).key).toBe("ddg");
  });

  it("returns null for empty/short lists", () => {
    expect(primaryProvider([])).toBeNull();
    expect(secondaryProvider([testProviders[0]])).toBeNull();
  });
});

describe("providerByKey", () => {
  it("finds provider by key", () => {
    expect(providerByKey(testProviders, "ddg").name).toBe("DDG");
  });

  it("returns null for missing key", () => {
    expect(providerByKey(testProviders, "bing")).toBeNull();
    expect(providerByKey(testProviders, "")).toBeNull();
  });
});

describe("preferredProviderKey", () => {
  it("returns persisted key when remember is enabled", () => {
    expect(preferredProviderKey(true, "google", "ddg")).toBe("google");
  });

  it("returns session key when remember is disabled", () => {
    expect(preferredProviderKey(false, "google", "ddg")).toBe("ddg");
  });

  it("falls back to session key when persisted is empty", () => {
    expect(preferredProviderKey(true, "", "ddg")).toBe("ddg");
  });
});

describe("buildWebTarget", () => {
  it("appends encoded query to exec URL", () => {
    const url = buildWebTarget(testProviders[0], "hello world");
    expect(url).toBe("https://google.com/search?q=hello%20world");
  });

  it("replaces %s placeholder", () => {
    const provider = { exec: "https://search.me/q=%s&lang=en", home: "" };
    expect(buildWebTarget(provider, "test")).toBe(
      "https://search.me/q=test&lang=en"
    );
  });

  it("returns home URL when query is empty", () => {
    expect(buildWebTarget(testProviders[0], "")).toBe("https://google.com/");
  });

  it("returns empty for null provider", () => {
    expect(buildWebTarget(null, "test")).toBe("");
  });
});

describe("buildWebRecent", () => {
  it("builds recent entry with provider metadata", () => {
    const recent = buildWebRecent(testProviders[0], "https://google.com/search?q=foo");
    expect(recent.name).toBe("Google");
    expect(recent.title).toBe("https://google.com/search?q=foo");
    expect(recent.icon).toBe("G");
  });
});

describe("deriveHomepage", () => {
  it("returns home field when available", () => {
    expect(deriveHomepage({ home: "https://example.com/", exec: "https://example.com/search?q=" }))
      .toBe("https://example.com/");
  });

  it("derives from exec URL when home is empty (strips query, adds trailing /)", () => {
    expect(deriveHomepage({ home: "", exec: "https://example.com/search?q=" }))
      .toBe("https://example.com/search/");
  });

  it("appends trailing slash when needed", () => {
    expect(deriveHomepage({ home: "", exec: "https://example.com" }))
      .toBe("https://example.com/");
  });
});

// ---------------------------------------------------------------------------
// selectWebProviderByKey
// ---------------------------------------------------------------------------

describe("selectWebProviderByKey", () => {
  function makeCtx(items, overrides) {
    return Object.assign({
      mode: "web",
      filteredItems: items,
      selectedIndex: -1,
    }, overrides);
  }

  it("sets selectedIndex when provider key is found", () => {
    const items = [
      { key: "google" },
      { key: "ddg" },
    ];
    const ctx = makeCtx(items);
    selectWebProviderByKey("ddg", ctx);
    expect(ctx.selectedIndex).toBe(1);
  });

  it("sets selectedIndex to 0 for the first item", () => {
    const items = [{ key: "google" }, { key: "ddg" }];
    const ctx = makeCtx(items);
    selectWebProviderByKey("google", ctx);
    expect(ctx.selectedIndex).toBe(0);
  });

  it("does not change selectedIndex when key is not found", () => {
    const items = [{ key: "google" }];
    const ctx = makeCtx(items, { selectedIndex: 0 });
    selectWebProviderByKey("bing", ctx);
    expect(ctx.selectedIndex).toBe(0);
  });

  it("does nothing when mode is not web", () => {
    const ctx = makeCtx([{ key: "google" }], { mode: "drun", selectedIndex: 0 });
    selectWebProviderByKey("google", ctx);
    expect(ctx.selectedIndex).toBe(0);
  });

  it("does nothing when providerKey is empty string", () => {
    const ctx = makeCtx([{ key: "google" }], { selectedIndex: 0 });
    selectWebProviderByKey("", ctx);
    expect(ctx.selectedIndex).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// webProviderSlotFromKey
// ---------------------------------------------------------------------------

describe("webProviderSlotFromKey", () => {
  it("maps Qt.Key_1 (49) through Qt.Key_9 (57) to slots 1–9", () => {
    expect(webProviderSlotFromKey(49)).toBe(1);
    expect(webProviderSlotFromKey(50)).toBe(2);
    expect(webProviderSlotFromKey(57)).toBe(9);
  });

  it("returns 0 for Qt.Key_0 (48) — zero is not a valid slot", () => {
    expect(webProviderSlotFromKey(48)).toBe(0);
  });

  it("returns 0 for keys outside the digit range", () => {
    expect(webProviderSlotFromKey(65)).toBe(0);  // 'A'
    expect(webProviderSlotFromKey(32)).toBe(0);  // space
    expect(webProviderSlotFromKey(0)).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// selectWebProviderBySlot
// ---------------------------------------------------------------------------

describe("selectWebProviderBySlot", () => {
  const providers = [
    { key: "google", name: "Google" },
    { key: "ddg", name: "DDG" },
    { key: "brave", name: "Brave" },
  ];

  function makeCtx(overrides) {
    return Object.assign({
      mode: "web",
      filteredItems: providers,
      selectedIndex: -1,
      configuredWebProviders: () => providers,
    }, overrides);
  }

  it("returns true and selects the provider at the given 1-based slot", () => {
    const ctx = makeCtx();
    const result = selectWebProviderBySlot(2, ctx);
    expect(result).toBe(true);
    expect(ctx.selectedIndex).toBe(1); // ddg is at index 1 in filteredItems
  });

  it("selects slot 1 (first provider)", () => {
    const ctx = makeCtx();
    expect(selectWebProviderBySlot(1, ctx)).toBe(true);
    expect(ctx.selectedIndex).toBe(0);
  });

  it("returns false when slot exceeds provider count", () => {
    const ctx = makeCtx();
    expect(selectWebProviderBySlot(10, ctx)).toBe(false);
  });

  it("returns false for slot < 1", () => {
    const ctx = makeCtx();
    expect(selectWebProviderBySlot(0, ctx)).toBe(false);
  });

  it("returns false when mode is not web", () => {
    const ctx = makeCtx({ mode: "drun" });
    expect(selectWebProviderBySlot(1, ctx)).toBe(false);
  });

  it("returns false when provider has no key", () => {
    const ctx = makeCtx({ configuredWebProviders: () => [{ name: "No Key" }] });
    expect(selectWebProviderBySlot(1, ctx)).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// executeBangSearch
// ---------------------------------------------------------------------------

describe("executeBangSearch", () => {
  function makeCtx() {
    const calls = { exec: [], close: 0 };
    const ctx = {
      execDetached: (args) => { calls.exec.push(args); },
      close: () => { calls.close++; },
      _calls: calls,
    };
    return ctx;
  }

  it("expands {{{s}}} placeholder with encoded query", () => {
    const ctx = makeCtx();
    executeBangSearch("https://example.com/?q={{{s}}}", "hello world", ctx);
    expect(ctx._calls.exec[0]).toEqual(["xdg-open", "https://example.com/?q=hello%20world"]);
  });

  it("expands %s placeholder with encoded query", () => {
    const ctx = makeCtx();
    executeBangSearch("https://search.me/q=%s", "test query", ctx);
    expect(ctx._calls.exec[0]).toEqual(["xdg-open", "https://search.me/q=test%20query"]);
  });

  it("appends encoded query when no placeholder present (fallback)", () => {
    const ctx = makeCtx();
    executeBangSearch("https://example.com/search?q=", "foo bar", ctx);
    expect(ctx._calls.exec[0]).toEqual(["xdg-open", "https://example.com/search?q=foo%20bar"]);
  });

  it("prefers {{{s}}} over %s when both appear", () => {
    const ctx = makeCtx();
    executeBangSearch("https://example.com/{{{s}}}?fallback=%s", "test", ctx);
    // {{{s}}} is replaced with encoded query; %s in the remainder is left intact
    const url = ctx._calls.exec[0][1];
    expect(url).toContain("test");
    expect(url).not.toContain("{{{s}}}");
    expect(url).toContain("%s");
  });

  it("calls close() after dispatching", () => {
    const ctx = makeCtx();
    executeBangSearch("https://example.com/?q={{{s}}}", "x", ctx);
    expect(ctx._calls.close).toBe(1);
  });

  it("handles empty query by appending nothing meaningful", () => {
    const ctx = makeCtx();
    executeBangSearch("https://example.com/?q={{{s}}}", "", ctx);
    expect(ctx._calls.exec[0][1]).toBe("https://example.com/?q=");
  });
});
