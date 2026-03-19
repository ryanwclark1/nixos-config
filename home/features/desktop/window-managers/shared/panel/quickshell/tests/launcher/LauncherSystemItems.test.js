import { describe, it, expect } from "vitest";
import {
  buildSystemItems,
  parseAdHocTarget,
  buildSshItems,
  buildAdHocSshItem,
  resultSectionLabel,
} from "../../src/launcher/LauncherSystemItems.js";

describe("buildSystemItems", () => {
  it("keeps system mode focused on destinations and session actions", () => {
    const items = buildSystemItems({
      sessionActions: [
        { id: "lock", category: "Power", name: "Lock Screen", title: "", icon: "󰌾" },
      ],
      makeConfirmedSystemAction: () => () => {},
      makeDetachedSystemAction: () => () => {},
      openDashboard: () => {},
      openSettings: () => {},
      openNotifications: () => {},
      openControlCenter: () => {},
      openScreenshotMenu: () => {},
      openPowerMenu: () => {},
    });

    expect(items.map((item) => item.name)).toContain("Dashboard");
    expect(items.map((item) => item.name)).toContain("Settings");
    expect(items.map((item) => item.name)).toContain("Lock Screen");
    expect(items.map((item) => item.name)).not.toContain("Open Audio Controls");
  });
});

// ---------------------------------------------------------------------------
// parseAdHocTarget
// ---------------------------------------------------------------------------

describe("parseAdHocTarget", () => {
  it("returns null for null/empty/whitespace input", () => {
    expect(parseAdHocTarget(null)).toBeNull();
    expect(parseAdHocTarget("")).toBeNull();
    expect(parseAdHocTarget("   ")).toBeNull();
    expect(parseAdHocTarget(undefined)).toBeNull();
  });

  it("parses bare hostname", () => {
    expect(parseAdHocTarget("myhost")).toEqual({
      user: "",
      host: "myhost",
      port: 22,
    });
  });

  it("parses user@host", () => {
    expect(parseAdHocTarget("root@server")).toEqual({
      user: "root",
      host: "server",
      port: 22,
    });
  });

  it("parses user@host:port", () => {
    expect(parseAdHocTarget("admin@box:2222")).toEqual({
      user: "admin",
      host: "box",
      port: 2222,
    });
  });

  it("strips leading ; (ssh mode prefix)", () => {
    expect(parseAdHocTarget(";myhost")).toEqual({
      user: "",
      host: "myhost",
      port: 22,
    });
    expect(parseAdHocTarget("; root@server")).toEqual({
      user: "root",
      host: "server",
      port: 22,
    });
  });

  it("accepts boundary ports 1 and 65535", () => {
    expect(parseAdHocTarget("host:1")).toEqual({
      user: "",
      host: "host",
      port: 1,
    });
    expect(parseAdHocTarget("host:65535")).toEqual({
      user: "",
      host: "host",
      port: 65535,
    });
  });

  it("treats port 0 as part of hostname (out of range)", () => {
    // Port 0 fails the >= 1 check, so colon+0 stays in the host
    expect(parseAdHocTarget("host:0")).toEqual({
      user: "",
      host: "host:0",
      port: 22,
    });
  });

  it("treats port 99999 as part of hostname (out of range)", () => {
    expect(parseAdHocTarget("host:99999")).toEqual({
      user: "",
      host: "host:99999",
      port: 22,
    });
  });

  it("treats non-numeric port as part of hostname", () => {
    expect(parseAdHocTarget("host:abc")).toEqual({
      user: "",
      host: "host:abc",
      port: 22,
    });
  });

  it("returns null when host portion is empty", () => {
    // user@ with nothing after → host is empty
    expect(parseAdHocTarget("user@")).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// buildSshItems
// ---------------------------------------------------------------------------

describe("buildSshItems", () => {
  const makeActions = (overrides = {}) => ({
    mergedHosts: [],
    recentIds: [],
    sshCommand: "ssh",
    buildDisplayCommand: (h) => "ssh " + (h.host || ""),
    connectHost: () => {},
    close: () => {},
    ...overrides,
  });

  it("returns empty array for empty hosts", () => {
    expect(buildSshItems(makeActions())).toEqual([]);
  });

  it("builds items with correct categories", () => {
    const hosts = [
      { id: "1", source: "imported", host: "srv1", label: "Server 1" },
      { id: "2", source: "manual", group: "Work", host: "srv2", label: "Server 2" },
      { id: "3", source: "manual", group: "", host: "srv3", label: "Server 3" },
    ];
    const items = buildSshItems(makeActions({ mergedHosts: hosts }));
    expect(items).toHaveLength(3);
    expect(items[0].category).toBe("Imported");
    expect(items[1].category).toBe("Work");
    expect(items[2].category).toBe("Manual");
  });

  it("applies recent boost correctly", () => {
    const hosts = [
      { id: "a", source: "manual", host: "h1", label: "H1" },
      { id: "b", source: "manual", host: "h2", label: "H2" },
      { id: "c", source: "manual", host: "h3", label: "H3" },
    ];
    const items = buildSshItems(
      makeActions({ mergedHosts: hosts, recentIds: ["b", "c"] })
    );
    // "b" is at index 0 in recentIds → boost 100, "c" at index 1 → boost 99
    expect(items.find((i) => i.name === "H2")._recentBoost).toBe(100);
    expect(items.find((i) => i.name === "H3")._recentBoost).toBe(99);
    expect(items.find((i) => i.name === "H1")._recentBoost).toBe(0);
  });

  it("uses label, then alias, then host for name", () => {
    const hosts = [
      { id: "1", source: "manual", host: "h1", label: "My Label" },
      { id: "2", source: "manual", host: "h2", alias: "myalias" },
      { id: "3", source: "manual", host: "bare-host" },
    ];
    const items = buildSshItems(makeActions({ mergedHosts: hosts }));
    expect(items[0].name).toBe("My Label");
    expect(items[1].name).toBe("myalias");
    expect(items[2].name).toBe("bare-host");
  });
});

// ---------------------------------------------------------------------------
// buildAdHocSshItem
// ---------------------------------------------------------------------------

describe("buildAdHocSshItem", () => {
  it("returns null for empty query", () => {
    expect(buildAdHocSshItem("", "ssh")).toBeNull();
    expect(buildAdHocSshItem("   ", "ssh")).toBeNull();
  });

  it("builds item for simple host", () => {
    const item = buildAdHocSshItem("myhost", "ssh");
    expect(item).toMatchObject({
      category: "Ad-hoc",
      name: "myhost",
      title: "ssh myhost",
    });
  });

  it("includes -p flag for non-default port", () => {
    const item = buildAdHocSshItem("user@box:2222", "ssh");
    expect(item.title).toBe("ssh -p 2222 user@box");
    expect(item.name).toBe("user@box");
  });

  it("uses custom sshCommand", () => {
    const item = buildAdHocSshItem("host", "kitten ssh");
    expect(item.title).toBe("kitten ssh host");
  });

  it("sets _recentBoost to -1 for ad-hoc items", () => {
    const item = buildAdHocSshItem("host", "ssh");
    expect(item._recentBoost).toBe(-1);
  });
});

// ---------------------------------------------------------------------------
// resultSectionLabel
// ---------------------------------------------------------------------------

describe("resultSectionLabel", () => {
  const baseOpts = {
    drunCategoryFiltersEnabled: false,
    drunCategoryFilter: "",
    formatDrunCategoryLabel: (key) => key.charAt(0).toUpperCase() + key.slice(1),
    ensureItemRankCache: () => {},
    modeInfoFn: () => ({ label: "Results" }),
  };

  it('returns "Applications" for drun without category filter', () => {
    expect(resultSectionLabel("drun", { name: "Firefox" }, baseOpts)).toBe(
      "Applications"
    );
  });

  it("returns formatted category label for drun with filter enabled", () => {
    const item = { name: "Firefox", _primaryCategoryKey: "network" };
    const opts = {
      ...baseOpts,
      drunCategoryFiltersEnabled: true,
      ensureItemRankCache: (i) => {
        i._rankCacheReady = true;
      },
    };
    expect(resultSectionLabel("drun", item, opts)).toBe("Network");
  });

  it("returns static labels for known modes", () => {
    expect(resultSectionLabel("files", {}, baseOpts)).toBe("Files");
    expect(resultSectionLabel("run", {}, baseOpts)).toBe("Commands");
    expect(resultSectionLabel("clip", {}, baseOpts)).toBe("Clipboard");
    expect(resultSectionLabel("bookmarks", {}, baseOpts)).toBe("Bookmarks");
  });

  it("returns item category for SSH/system modes", () => {
    expect(
      resultSectionLabel("ssh", { category: "Imported" }, baseOpts)
    ).toBe("Imported");
  });

  it("falls back to mode label when item has no category", () => {
    const opts = {
      ...baseOpts,
      modeInfoFn: () => ({ label: "SSH Hosts" }),
    };
    expect(resultSectionLabel("ssh", { name: "foo" }, opts)).toBe("SSH Hosts");
  });

  it('returns "" for null item', () => {
    expect(resultSectionLabel("drun", null, baseOpts)).toBe("");
  });
});
