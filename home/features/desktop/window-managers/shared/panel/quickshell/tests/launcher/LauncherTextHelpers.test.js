import { describe, it, expect } from "vitest";
import {
  fileModeHint,
  emptyStateTitle,
  emptyStateSubtitle,
  emptyPrimaryCta,
  emptySecondaryCta,
  emptyPrimaryHintIcon,
  emptySecondaryHintIcon,
  categoryFilterLabel,
  categoryFilterSummary,
  webAliasHint,
} from "../../src/launcher/LauncherTextHelpers.js";

// This file exercises the plugin's cross-import resolution:
// LauncherTextHelpers.js uses `.import "LauncherFileParser.js" as FileParser`
// If the plugin's resolveId fails, the import will break at load time.

// ---------------------------------------------------------------------------
// fileModeHint
// ---------------------------------------------------------------------------

describe("fileModeHint", () => {
  it("uses home wording for the default root", () => {
    expect(fileModeHint("~")).toBe("Search home with /");
    expect(fileModeHint("")).toBe("Search home with /");
  });

  it("uses the configured directory label for custom roots", () => {
    expect(fileModeHint("~/Projects")).toBe("Search ~/Projects with /");
  });
});

// ---------------------------------------------------------------------------
// emptyStateTitle
// ---------------------------------------------------------------------------

describe("emptyStateTitle", () => {
  it("shows file min-query hint when query is too short", () => {
    expect(emptyStateTitle("files", "ab", 3)).toBe(
      "Start typing to search Home"
    );
  });

  it("shows no-match message when file query is long enough", () => {
    expect(emptyStateTitle("files", "foobar", 3)).toBe(
      "No files match 'foobar'"
    );
  });

  it("returns mode-specific titles", () => {
    expect(emptyStateTitle("ai", "", 3)).toBe(
      "Describe what you want and press Enter"
    );
    expect(emptyStateTitle("clip", "", 3)).toBe("Clipboard history is empty");
    expect(emptyStateTitle("ssh", "", 3)).toBe("No SSH hosts found");
    expect(emptyStateTitle("window", "", 3)).toBe("No open windows found");
  });

  it("returns generic fallback for unknown mode", () => {
    expect(emptyStateTitle("unknown", "", 3)).toBe("No results");
  });
});

// ---------------------------------------------------------------------------
// emptySecondaryCta — exercises the cross-import (FileParser.fileQueryLooksLikePath)
// ---------------------------------------------------------------------------

describe("emptySecondaryCta", () => {
  it('returns "Open Folder" for path-like file query', () => {
    // fileQueryLooksLikePath returns true for strings starting with / or ~/
    expect(emptySecondaryCta("files", "/etc/nixos", "/etc/nixos", "")).toBe(
      "Open Folder"
    );
    expect(emptySecondaryCta("files", "~/docs", "~/docs", "")).toBe(
      "Open Folder"
    );
  });

  it('returns "Clear Query" for non-path file query', () => {
    expect(emptySecondaryCta("files", "readme", "readme", "")).toBe(
      "Clear Query"
    );
  });

  it("returns empty string for files with empty searchText and non-path query", () => {
    expect(emptySecondaryCta("files", "readme", "", "")).toBe("");
  });

  it("returns mode-specific CTAs for non-file modes", () => {
    expect(emptySecondaryCta("run", "ls", "ls", "")).toBe("Run In Terminal");
    expect(emptySecondaryCta("ssh", "", "", "")).toBe("Refresh Import");
    expect(emptySecondaryCta("system", "", "", "")).toBe("Open Controls");
  });
});

// ---------------------------------------------------------------------------
// categoryFilterLabel
// ---------------------------------------------------------------------------

describe("categoryFilterLabel", () => {
  const options = [
    { key: "", label: "All Apps" },
    { key: "network", label: "Internet" },
    { key: "utility", label: "Utilities" },
  ];

  it("returns matching label for known filter", () => {
    expect(categoryFilterLabel(options, "network")).toBe("Internet");
  });

  it('returns "All" for unmatched filter', () => {
    expect(categoryFilterLabel(options, "bogus")).toBe("All");
  });

  it('returns "All" for empty filter matching the first option', () => {
    expect(categoryFilterLabel(options, "")).toBe("All Apps");
  });
});

// ---------------------------------------------------------------------------
// categoryFilterSummary
// ---------------------------------------------------------------------------

describe("categoryFilterSummary", () => {
  const options = [
    { key: "", count: 120 },
    { key: "network", count: 15 },
  ];

  it('returns "N apps ready" for empty filter', () => {
    expect(categoryFilterSummary(options, "")).toBe("120 apps ready");
  });

  it('returns "N of T apps" for specific filter', () => {
    expect(categoryFilterSummary(options, "network")).toBe("15 of 120 apps");
  });

  it("handles empty options", () => {
    expect(categoryFilterSummary([], "")).toBe("0 apps ready");
  });
});

// ---------------------------------------------------------------------------
// webAliasHint
// ---------------------------------------------------------------------------

describe("webAliasHint", () => {
  it("builds alias hint from providers", () => {
    const aliases = { google: ["g", "ggl"], ddg: ["d"] };
    const providers = [{ key: "google" }, { key: "ddg" }];
    expect(webAliasHint(aliases, providers, false)).toBe("Alias: ?g ?d");
  });

  it("uses compact prefix", () => {
    const aliases = { google: ["g"] };
    const providers = [{ key: "google" }];
    expect(webAliasHint(aliases, providers, true)).toBe("Aliases: ?g");
  });

  it("returns fallback when no aliases match", () => {
    expect(webAliasHint({}, [{ key: "x" }], false)).toBe(
      "Alias: provider key"
    );
  });
});

describe("empty state hint icons", () => {
  it("returns svg-backed primary icons by mode", () => {
    expect(emptyPrimaryHintIcon("window")).toBe("window-multiple.svg");
    expect(emptyPrimaryHintIcon("files")).toBe("folder.svg");
  });

  it("returns svg-backed secondary icons by mode and query", () => {
    expect(emptySecondaryHintIcon("files", "")).toBe("folder-open.svg");
    expect(emptySecondaryHintIcon("settings", "query")).toBe("dismiss.svg");
    expect(emptySecondaryHintIcon("ssh", "")).toBe("arrow-clockwise.svg");
  });
});
