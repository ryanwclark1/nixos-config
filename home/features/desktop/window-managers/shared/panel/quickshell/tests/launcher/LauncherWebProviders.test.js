import { describe, it, expect } from "vitest";
import {
  primaryProvider,
  secondaryProvider,
  providerByKey,
  preferredProviderKey,
  buildWebTarget,
  buildWebRecent,
  deriveHomepage,
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
