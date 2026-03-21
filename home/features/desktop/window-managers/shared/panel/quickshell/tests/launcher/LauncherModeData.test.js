import { describe, it, expect } from "vitest";
import {
  modeInfo,
  modeDependencies,
  missingDependencyMessage,
  sanitizeModeList,
  shellQuote,
  stripModePrefix,
  parseWebQuery,
  configuredWebProviders,
  webAliasToProviderKey,
  webProviderKeys,
  allKnownModes,
  defaultModeOrder,
  defaultPrimaryModes,
  modePrefixes,
} from "../../src/launcher/LauncherModeData.js";

// ---------------------------------------------------------------------------
// modeInfo
// ---------------------------------------------------------------------------

describe("modeInfo", () => {
  it("returns metadata for known modes", () => {
    expect(modeInfo("drun")).toMatchObject({ label: "Apps", prefix: "" });
    expect(modeInfo("ssh")).toMatchObject({ label: "SSH", prefix: ";" });
    expect(modeInfo("web")).toMatchObject({ label: "Web", prefix: "?" });
  });

  it("returns fallback for unknown modes", () => {
    const info = modeInfo("nonexistent");
    expect(info.label).toBe("NONEXISTENT");
    expect(info.prefix).toBe("");
  });
});

// ---------------------------------------------------------------------------
// modeDependencies
// ---------------------------------------------------------------------------

describe("modeDependencies", () => {
  it("returns dependencies for modes that have them", () => {
    expect(modeDependencies("clip")).toContain("cliphist");
    expect(modeDependencies("run")).toContain("qs-run");
  });

  it("returns empty array for modes with no dependencies", () => {
    expect(modeDependencies("drun")).toEqual([]);
    expect(modeDependencies("window")).toEqual([]);
    expect(modeDependencies("wallpapers")).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// missingDependencyMessage
// ---------------------------------------------------------------------------

describe("missingDependencyMessage", () => {
  it("uses special message for files mode", () => {
    expect(missingDependencyMessage("files", "fd")).toBe(
      "Required command missing: fd"
    );
  });

  it("uses generic message for other modes", () => {
    const msg = missingDependencyMessage("clip", "cliphist");
    expect(msg).toContain("cliphist");
    expect(msg).toContain("Clipboard");
  });
});

// ---------------------------------------------------------------------------
// sanitizeModeList
// ---------------------------------------------------------------------------

describe("sanitizeModeList", () => {
  const allowed = ["drun", "files", "web", "ssh"];
  const fallback = ["drun", "files"];

  it("filters to allowed list", () => {
    expect(sanitizeModeList(["drun", "bogus", "ssh"], fallback, allowed)).toEqual([
      "drun",
      "ssh",
    ]);
  });

  it("deduplicates", () => {
    expect(sanitizeModeList(["drun", "drun"], fallback, allowed)).toEqual(["drun"]);
  });

  it("uses fallback for empty/null source", () => {
    expect(sanitizeModeList(null, fallback, allowed)).toEqual(fallback);
    expect(sanitizeModeList([], fallback, allowed)).toEqual(fallback);
  });

  it("uses fallback when all entries invalid", () => {
    expect(sanitizeModeList(["x", "y"], fallback, allowed)).toEqual(fallback);
  });
});

// ---------------------------------------------------------------------------
// shellQuote
// ---------------------------------------------------------------------------

describe("shellQuote", () => {
  it("wraps in single quotes", () => {
    expect(shellQuote("hello")).toBe("'hello'");
  });

  it("escapes internal single quotes", () => {
    expect(shellQuote("it's")).toBe("'it'\\''s'");
  });

  it("handles empty/null input", () => {
    expect(shellQuote("")).toBe("''");
    expect(shellQuote(null)).toBe("''");
  });
});

// ---------------------------------------------------------------------------
// stripModePrefix
// ---------------------------------------------------------------------------

describe("stripModePrefix", () => {
  it("strips known prefixes", () => {
    expect(stripModePrefix("!hello")).toBe("hello");
    expect(stripModePrefix("/path")).toBe("path");
    expect(stripModePrefix("?query")).toBe("query");
    expect(stripModePrefix(">cmd")).toBe("cmd");
    expect(stripModePrefix(":emoji")).toBe("emoji");
    expect(stripModePrefix(";ssh")).toBe("ssh");
    expect(stripModePrefix(",settings")).toBe("settings");
    expect(stripModePrefix("@bookmark")).toBe("bookmark");
    expect(stripModePrefix("=2+3")).toBe("2+3");
  });

  it("returns unmodified text without prefix", () => {
    expect(stripModePrefix("firefox")).toBe("firefox");
    expect(stripModePrefix("")).toBe("");
  });
});

// ---------------------------------------------------------------------------
// parseWebQuery
// ---------------------------------------------------------------------------

describe("parseWebQuery", () => {
  const providers = [
    { key: "google", name: "Google" },
    { key: "youtube", name: "YouTube" },
  ];
  const aliases = { google: ["g"], youtube: ["yt"] };

  it("detects alias as first token", () => {
    const result = parseWebQuery("?g hello world", providers, aliases);
    expect(result.providerKey).toBe("google");
    expect(result.query).toBe("hello world");
  });

  it("detects full provider key", () => {
    const result = parseWebQuery("?youtube cats", providers, aliases);
    expect(result.providerKey).toBe("youtube");
    expect(result.query).toBe("cats");
  });

  it("returns empty providerKey when no alias match", () => {
    const result = parseWebQuery("?nix stuff", providers, aliases);
    expect(result.providerKey).toBe("");
    expect(result.query).toBe("nix stuff");
  });

  it("handles alias-only query (no search terms)", () => {
    const result = parseWebQuery("?g", providers, aliases);
    expect(result.providerKey).toBe("google");
    expect(result.query).toBe("");
  });

  it("strips mode prefix before processing", () => {
    const result = parseWebQuery("?yt music", providers, aliases);
    expect(result.providerKey).toBe("youtube");
    expect(result.query).toBe("music");
  });
});

// ---------------------------------------------------------------------------
// configuredWebProviders
// ---------------------------------------------------------------------------

describe("configuredWebProviders", () => {
  it("returns providers in specified order", () => {
    const result = configuredWebProviders(["youtube", "google"]);
    expect(result).toHaveLength(2);
    expect(result[0].key).toBe("youtube");
    expect(result[1].key).toBe("google");
  });

  it("skips unknown keys", () => {
    const result = configuredWebProviders(["google", "nonexistent"]);
    expect(result).toHaveLength(1);
    expect(result[0].key).toBe("google");
  });

  it("falls back to defaults for empty array", () => {
    const result = configuredWebProviders([]);
    expect(result.length).toBeGreaterThan(0);
    expect(result[0].key).toBe("duckduckgo");
  });
});

// ---------------------------------------------------------------------------
// Data exports
// ---------------------------------------------------------------------------

describe("data exports", () => {
  it("allKnownModes includes core modes", () => {
    expect(allKnownModes).toContain("drun");
    expect(allKnownModes).toContain("ssh");
    expect(allKnownModes).toContain("web");
  });

  it("defaultModeOrder matches allKnownModes", () => {
    for (const mode of defaultModeOrder) {
      expect(allKnownModes).toContain(mode);
    }
  });

  it("defaultPrimaryModes stays on the focused sidebar set", () => {
    expect(defaultPrimaryModes).toEqual(["drun", "window", "files", "ai", "system"]);
  });

  it("modePrefixes contains all known prefix chars", () => {
    expect(modePrefixes).toContain("!");
    expect(modePrefixes).toContain(">");
    expect(modePrefixes).toContain(";");
    expect(modePrefixes).toContain(":");
    expect(modePrefixes).toContain(",");
  });

  it("webProviderKeys returns catalog keys", () => {
    const keys = webProviderKeys();
    expect(keys).toContain("google");
    expect(keys).toContain("duckduckgo");
    expect(keys).toContain("youtube");
    expect(keys.length).toBeGreaterThan(20);
  });
});
