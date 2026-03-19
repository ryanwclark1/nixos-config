import { describe, it, expect } from "vitest";
import {
  itemActionLabel,
  itemProviderLabel,
  buildRecentEntry,
} from "../../src/launcher/LauncherExecutor.js";

// ---------------------------------------------------------------------------
// itemActionLabel
// ---------------------------------------------------------------------------

describe("itemActionLabel", () => {
  it("returns mode-specific labels", () => {
    expect(itemActionLabel("drun", { name: "App" })).toBe("Run");
    expect(itemActionLabel("clip", { name: "X" })).toBe("Copy");
    expect(itemActionLabel("web", { name: "Y" })).toBe("Open");
    expect(itemActionLabel("ssh", { name: "Z" })).toBe("Connect");
    expect(itemActionLabel("window", { name: "W" })).toBe("Focus");
  });

  it("returns empty for hint items", () => {
    expect(itemActionLabel("drun", { name: "App", isHint: true })).toBe("");
  });

  it("returns empty for null item", () => {
    expect(itemActionLabel("drun", null)).toBe("");
  });

  it("returns empty for unknown mode", () => {
    expect(itemActionLabel("unknown", { name: "X" })).toBe("");
  });
});

// ---------------------------------------------------------------------------
// itemProviderLabel
// ---------------------------------------------------------------------------

describe("itemProviderLabel", () => {
  it("returns item name for web mode", () => {
    expect(itemProviderLabel("web", { name: "Google" })).toBe("Google");
  });

  it("extracts domain for bookmarks mode", () => {
    expect(
      itemProviderLabel("bookmarks", { exec: "https://github.com/user/repo" })
    ).toBe("github.com");
  });

  it("returns empty for non-web/bookmark modes", () => {
    expect(itemProviderLabel("drun", { name: "Firefox" })).toBe("");
  });

  it("returns empty for hint items", () => {
    expect(itemProviderLabel("web", { name: "G", isHint: true })).toBe("");
  });
});

// ---------------------------------------------------------------------------
// buildRecentEntry
// ---------------------------------------------------------------------------

describe("buildRecentEntry", () => {
  it("builds run mode recent entry", () => {
    const entry = buildRecentEntry("run", { name: "ls", exec: "ls -la" });
    expect(entry).toMatchObject({
      name: "ls",
      title: "ls -la",
      icon: "󰆍",
      exec: "ls -la",
    });
  });

  it("builds window mode recent entry", () => {
    const entry = buildRecentEntry("window", {
      name: "Firefox",
      title: "My Tab",
      appId: "firefox",
    });
    expect(entry.openMode).toBe("window");
    expect(entry.appId).toBe("firefox");
  });

  it("builds web/bookmarks mode recent entry", () => {
    const entry = buildRecentEntry("web", {
      name: "Google",
      exec: "https://google.com/search?q=test",
      icon: "G",
    });
    expect(entry.name).toBe("Google");
    expect(entry.exec).toBe("https://google.com/search?q=test");
  });

  it("builds files mode recent entry", () => {
    const entry = buildRecentEntry("files", {
      name: "readme.md",
      fullPath: "/home/user/readme.md",
    });
    expect(entry.fullPath).toBe("/home/user/readme.md");
  });

  it("returns null for files hint item", () => {
    expect(buildRecentEntry("files", { isHint: true })).toBeNull();
  });

  it("returns null for unsupported modes", () => {
    expect(buildRecentEntry("calc", { name: "42" })).toBeNull();
    expect(buildRecentEntry("emoji", { name: "😀" })).toBeNull();
  });

  it("builds system/nixos mode recent entry", () => {
    const entry = buildRecentEntry("system", {
      name: "Reboot",
      category: "Power",
      icon: "⏻",
    });
    expect(entry.name).toBe("Reboot");
    expect(entry.title).toBe("Power");
  });
});
