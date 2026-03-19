import { describe, it, expect } from "vitest";
import {
  defaultWebAliasesCopy,
  webProviderMeta,
  parseAliasTokens,
  webAliasString,
  setWebAliasString,
  isLauncherModeSupported,
  supportedLauncherModeKeys,
  toggleLauncherMode,
  applyModePreset,
  launcherModeMeta,
  orderedEnabledModes,
  moveMode,
  toggleHiddenListValue,
  resetLauncherDefaults,
  _targetIndexFromMappedY,
} from "../../src/features/settings/components/tabs/ShellCoreHelpers.js";

// Mock CompositorAdapter
const fullAdapter = { supportsWindowListing: true, supportsHotkeysListing: true };
const limitedAdapter = { supportsWindowListing: false, supportsHotkeysListing: false };

// Mock launcher modes metadata
const launcherModes = [
  { key: "drun", label: "Apps", icon: "A" },
  { key: "window", label: "Windows", icon: "W" },
  { key: "files", label: "Files", icon: "F" },
  { key: "keybinds", label: "Keybinds", icon: "K" },
  { key: "ssh", label: "SSH", icon: "S" },
];

// ---------------------------------------------------------------------------
// Web alias helpers
// ---------------------------------------------------------------------------

describe("defaultWebAliasesCopy", () => {
  it("creates a deep copy", () => {
    const original = { google: ["g"], ddg: ["d"] };
    const copy = defaultWebAliasesCopy(original);
    expect(copy).toEqual(original);
    copy.google.push("ggl");
    expect(original.google).toHaveLength(1);
  });
});

describe("webProviderMeta", () => {
  const providers = [
    { key: "google", name: "Google", icon: "G" },
    { key: "ddg", name: "DDG", icon: "D" },
  ];

  it("finds existing provider", () => {
    expect(webProviderMeta(providers, "google").name).toBe("Google");
  });

  it("returns fallback for unknown provider", () => {
    const meta = webProviderMeta(providers, "bing");
    expect(meta.key).toBe("bing");
    expect(meta.icon).toBe("󰖟");
  });
});

describe("parseAliasTokens", () => {
  it("parses comma/space-separated tokens", () => {
    expect(parseAliasTokens("g, ggl goo", "google")).toEqual(["g", "ggl", "goo"]);
  });

  it("rejects invalid tokens", () => {
    expect(parseAliasTokens("g, !!!, @bad", "google")).toEqual(["g"]);
  });

  it("rejects token matching provider key", () => {
    expect(parseAliasTokens("google, g", "google")).toEqual(["g"]);
  });

  it("deduplicates", () => {
    expect(parseAliasTokens("g, g, g", "google")).toEqual(["g"]);
  });
});

describe("webAliasString / setWebAliasString", () => {
  it("converts alias array to comma-separated string", () => {
    const config = { launcherWebAliases: { google: ["g", "ggl"] } };
    expect(webAliasString(config, "google")).toBe("g, ggl");
  });

  it("returns empty for missing provider", () => {
    expect(webAliasString({}, "google")).toBe("");
  });

  it("sets parsed aliases on config", () => {
    const config = { launcherWebAliases: {} };
    setWebAliasString(config, "google", "g, ggl");
    expect(config.launcherWebAliases.google).toEqual(["g", "ggl"]);
  });
});

// ---------------------------------------------------------------------------
// Launcher mode helpers
// ---------------------------------------------------------------------------

describe("isLauncherModeSupported", () => {
  it("blocks window mode without window listing support", () => {
    expect(isLauncherModeSupported(limitedAdapter, "window")).toBe(false);
  });

  it("blocks keybinds mode without hotkeys listing support", () => {
    expect(isLauncherModeSupported(limitedAdapter, "keybinds")).toBe(false);
  });

  it("allows all other modes regardless", () => {
    expect(isLauncherModeSupported(limitedAdapter, "drun")).toBe(true);
    expect(isLauncherModeSupported(limitedAdapter, "ssh")).toBe(true);
  });
});

describe("supportedLauncherModeKeys", () => {
  it("filters to supported modes only", () => {
    const keys = supportedLauncherModeKeys(launcherModes, limitedAdapter);
    expect(keys).toContain("drun");
    expect(keys).toContain("files");
    expect(keys).not.toContain("window");
    expect(keys).not.toContain("keybinds");
  });
});

describe("toggleLauncherMode", () => {
  it("adds a mode when not present", () => {
    const config = {
      launcherEnabledModes: ["drun", "files"],
      launcherModeOrder: ["drun", "files"],
      launcherDefaultMode: "drun",
    };
    toggleLauncherMode(config, fullAdapter, launcherModes, "ssh");
    expect(config.launcherEnabledModes).toContain("ssh");
  });

  it("removes a mode when present", () => {
    const config = {
      launcherEnabledModes: ["drun", "files", "ssh"],
      launcherModeOrder: ["drun", "files", "ssh"],
      launcherDefaultMode: "drun",
    };
    toggleLauncherMode(config, fullAdapter, launcherModes, "ssh");
    expect(config.launcherEnabledModes).not.toContain("ssh");
  });
});

describe("applyModePreset", () => {
  it("applies minimal preset (filtered by available modes)", () => {
    const config = {
      launcherEnabledModes: [],
      launcherModeOrder: [],
      launcherDefaultMode: "drun",
    };
    // minimal preset is ["drun", "window", "files", "run", "system", "media"]
    // but setEnabledModes filters against supportedLauncherModeKeys,
    // so only modes present in our mock launcherModes survive
    applyModePreset(config, fullAdapter, launcherModes, "minimal");
    expect(config.launcherEnabledModes).toContain("drun");
    expect(config.launcherEnabledModes).toContain("window");
    expect(config.launcherEnabledModes).toContain("files");
    // "run", "system", "media" not in mock launcherModes, so filtered out
    expect(config.launcherEnabledModes).not.toContain("ssh");
  });

  it("applies full preset (all supported modes)", () => {
    const config = {
      launcherEnabledModes: [],
      launcherModeOrder: [],
      launcherDefaultMode: "drun",
    };
    applyModePreset(config, fullAdapter, launcherModes, "full");
    expect(config.launcherEnabledModes.length).toBe(launcherModes.length);
  });
});

describe("launcherModeMeta", () => {
  it("returns metadata for known mode", () => {
    expect(launcherModeMeta(launcherModes, "ssh")).toMatchObject({
      key: "ssh",
      label: "SSH",
    });
  });

  it("returns fallback for unknown mode", () => {
    const meta = launcherModeMeta(launcherModes, "unknown");
    expect(meta.key).toBe("unknown");
    expect(meta.icon).toBe("•");
  });
});

describe("orderedEnabledModes", () => {
  it("follows modeOrder then fills from enabledModes", () => {
    const config = {
      launcherEnabledModes: ["drun", "files", "ssh"],
      launcherModeOrder: ["ssh", "drun"],
    };
    const result = orderedEnabledModes(config, fullAdapter, launcherModes);
    expect(result[0]).toBe("ssh");
    expect(result[1]).toBe("drun");
    expect(result[2]).toBe("files");
  });

  it("skips unsupported modes", () => {
    const config = {
      launcherEnabledModes: ["drun", "window"],
      launcherModeOrder: ["drun", "window"],
    };
    const result = orderedEnabledModes(config, limitedAdapter, launcherModes);
    expect(result).toEqual(["drun"]);
  });
});

describe("moveMode", () => {
  it("moves a mode forward by delta", () => {
    const config = {
      launcherEnabledModes: ["drun", "files", "ssh"],
      launcherModeOrder: ["drun", "files", "ssh"],
    };
    moveMode(config, fullAdapter, launcherModes, "ssh", -2);
    expect(config.launcherModeOrder[0]).toBe("ssh");
  });

  it("does nothing when already at boundary", () => {
    const config = {
      launcherEnabledModes: ["drun", "files"],
      launcherModeOrder: ["drun", "files"],
    };
    moveMode(config, fullAdapter, launcherModes, "drun", -1);
    expect(config.launcherModeOrder[0]).toBe("drun");
  });
});

// ---------------------------------------------------------------------------
// Utility helpers
// ---------------------------------------------------------------------------

describe("toggleHiddenListValue", () => {
  it("adds value when not present", () => {
    const config = { hiddenToggles: ["a", "b"] };
    toggleHiddenListValue(config, "hiddenToggles", "c");
    expect(config.hiddenToggles).toEqual(["a", "b", "c"]);
  });

  it("removes value when present", () => {
    const config = { hiddenToggles: ["a", "b", "c"] };
    toggleHiddenListValue(config, "hiddenToggles", "b");
    expect(config.hiddenToggles).toEqual(["a", "c"]);
  });
});

describe("_targetIndexFromMappedY", () => {
  it("computes correct drop index", () => {
    // 5 items of height 40 + spacing 4
    expect(_targetIndexFromMappedY(0, 40, 4, 5)).toBe(0);
    expect(_targetIndexFromMappedY(44, 40, 4, 5)).toBe(1);
    expect(_targetIndexFromMappedY(220, 40, 4, 5)).toBe(5);
  });

  it("clamps to 0 and count", () => {
    expect(_targetIndexFromMappedY(-100, 40, 4, 5)).toBe(0);
    expect(_targetIndexFromMappedY(9999, 40, 4, 5)).toBe(5);
  });
});

describe("resetLauncherDefaults", () => {
  it("resets all launcher config to defaults", () => {
    const config = {
      launcherMaxResults: 999,
      launcherDefaultMode: "ssh",
      launcherEnabledModes: [],
      launcherModeOrder: [],
    };
    const defaults = { google: ["g"] };
    const defaultOrder = ["duckduckgo", "google"];
    const defaultModes = ["drun", "files", "window"];
    resetLauncherDefaults(config, defaults, defaultOrder, defaultModes, fullAdapter, launcherModes);
    expect(config.launcherDefaultMode).toBe("drun");
    expect(config.launcherMaxResults).toBe(80);
    expect(config.launcherEnabledModes).toContain("drun");
    expect(config.launcherWebProviderOrder).toEqual(defaultOrder);
  });
});
