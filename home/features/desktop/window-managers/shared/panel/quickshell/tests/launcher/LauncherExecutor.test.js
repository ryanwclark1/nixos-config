import { describe, it, expect, vi } from "vitest";
import {
  itemActionLabel,
  itemProviderLabel,
  buildRecentEntry,
  normalizeKeybindItem,
  normalizeKeybindItems,
  executeEmptyPrimary,
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
    expect(itemActionLabel("settings", { name: "Search Debounce" })).toBe("Jump");
  });

  it("prefers entry-kind overrides for destination items", () => {
    expect(
      itemActionLabel("system", { name: "Control Center", entryKind: "destination" })
    ).toBe("Open");
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
// normalizeKeybindItem(s)
// ---------------------------------------------------------------------------

describe("normalizeKeybindItem", () => {
  it("promotes the action description to the primary label and keeps the chord as secondary metadata", () => {
    const item = normalizeKeybindItem({
      name: "SUPER + Return",
      desc: "Terminal",
      disp: "exec",
      args: "ghostty",
    });

    expect(item).toMatchObject({
      name: "Terminal",
      title: "SUPER + Return",
      description: "Terminal",
      body: "exec ghostty",
      icon: "keyboard.svg",
    });
  });

  it("falls back to the chord when the description is missing", () => {
    const item = normalizeKeybindItem({
      name: "SUPER + Shift + C",
      disp: "close-window",
    });

    expect(item.name).toBe("SUPER + Shift + C");
    expect(item.title).toBe("");
    expect(item.body).toBe("close-window");
  });
});

describe("normalizeKeybindItems", () => {
  it("maps every raw keybind record into launcher display fields", () => {
    const items = normalizeKeybindItems([
      { name: "SUPER + B", desc: "Web browser", disp: "exec", args: "google-chrome" },
      { name: "SUPER + N", desc: "File manager", disp: "exec", args: "nautilus" },
    ]);

    expect(items).toHaveLength(2);
    expect(items.map((item) => item.name)).toEqual(["Web browser", "File manager"]);
    expect(items.map((item) => item.title)).toEqual(["SUPER + B", "SUPER + N"]);
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

  it("builds settings mode recent entry", () => {
    const entry = buildRecentEntry("settings", {
      name: "Search Debounce",
      breadcrumb: "Launcher > Search",
      icon: "󰒓",
    });
    expect(entry).toMatchObject({
      name: "Search Debounce",
      title: "Launcher > Search",
      openMode: "settings",
    });
  });
});

describe("executeEmptyPrimary", () => {
  it("opens full Settings when settings mode has no result", () => {
    const actions = {
      openSettings: vi.fn(),
      close: vi.fn(),
    };
    executeEmptyPrimary("settings", "", "", actions);
    expect(actions.openSettings).toHaveBeenCalledTimes(1);
    expect(actions.close).toHaveBeenCalledTimes(1);
  });
});
