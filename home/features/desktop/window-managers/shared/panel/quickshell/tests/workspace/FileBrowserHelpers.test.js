import { describe, it, expect } from "vitest";
import {
  parseStatOutput,
  sortEntries,
  applyFilters,
  buildBreadcrumbs,
  formatSize,
  formatDate,
  fileIcon,
} from "../../src/features/workspace/FileBrowserHelpers.js";

// ---------------------------------------------------------------------------
// parseStatOutput
// ---------------------------------------------------------------------------

describe("parseStatOutput", () => {
  it("parses tab-separated stat output", () => {
    const raw = [
      "/home/user/docs/\tdirectory\t4096\t1700000000",
      "/home/user/readme.md\tregular\t1024\t1700000001",
    ].join("\n");
    const entries = parseStatOutput(raw);
    expect(entries).toHaveLength(2);
    expect(entries[0]).toMatchObject({
      name: "docs",
      isDir: true,
      extension: "",
    });
    expect(entries[1]).toMatchObject({
      name: "readme.md",
      isDir: false,
      extension: "md",
      size: 1024,
    });
  });

  it("skips . and .. entries", () => {
    const raw = "./\tdirectory\t4096\t0\n../\tdirectory\t4096\t0";
    expect(parseStatOutput(raw)).toEqual([]);
  });

  it("detects image files", () => {
    const raw = "/photo.png\tregular\t5000\t1700000000";
    const entries = parseStatOutput(raw);
    expect(entries[0].isImage).toBe(true);
  });

  it("returns empty for empty input", () => {
    expect(parseStatOutput("")).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// sortEntries
// ---------------------------------------------------------------------------

describe("sortEntries", () => {
  const entries = [
    { name: "beta.txt", isDir: false, size: 200, mtime: 2, extension: "txt" },
    { name: "alpha", isDir: true, size: 4096, mtime: 1, extension: "" },
    { name: "gamma.js", isDir: false, size: 100, mtime: 3, extension: "js" },
  ];

  it("sorts directories before files", () => {
    const result = sortEntries(entries, "name", true);
    expect(result[0].isDir).toBe(true);
  });

  it("sorts by name ascending", () => {
    const result = sortEntries(entries, "name", true);
    expect(result[1].name).toBe("beta.txt");
    expect(result[2].name).toBe("gamma.js");
  });

  it("sorts by size descending", () => {
    const result = sortEntries(entries, "size", false);
    // Dirs first, then files by size desc
    expect(result[1].name).toBe("beta.txt"); // 200
    expect(result[2].name).toBe("gamma.js"); // 100
  });

  it("sorts by date", () => {
    const result = sortEntries(entries, "date", false);
    expect(result[1].name).toBe("gamma.js"); // mtime 3 first (desc)
  });
});

// ---------------------------------------------------------------------------
// applyFilters
// ---------------------------------------------------------------------------

describe("applyFilters", () => {
  const entries = [
    { name: "dir", isDir: true, extension: "" },
    { name: "file.js", isDir: false, extension: "js" },
    { name: "file.py", isDir: false, extension: "py" },
  ];

  it("filters to matching extensions (dirs always pass)", () => {
    const filters = [{ extensions: ["js"] }];
    const result = applyFilters(entries, filters, 0);
    expect(result).toHaveLength(2); // dir + .js
    expect(result.map((e) => e.name)).toEqual(["dir", "file.js"]);
  });

  it("returns all entries when no filters", () => {
    expect(applyFilters(entries, [], 0)).toEqual(entries);
  });
});

// ---------------------------------------------------------------------------
// buildBreadcrumbs
// ---------------------------------------------------------------------------

describe("buildBreadcrumbs", () => {
  it("builds breadcrumb trail from path", () => {
    const crumbs = buildBreadcrumbs("/home/user/docs");
    expect(crumbs).toEqual([
      { label: "/", path: "/" },
      { label: "home", path: "/home" },
      { label: "user", path: "/home/user" },
      { label: "docs", path: "/home/user/docs" },
    ]);
  });

  it("handles root path", () => {
    const crumbs = buildBreadcrumbs("/");
    expect(crumbs).toEqual([{ label: "/", path: "/" }]);
  });
});

// ---------------------------------------------------------------------------
// formatSize
// ---------------------------------------------------------------------------

describe("formatSize", () => {
  it("formats bytes", () => expect(formatSize(500)).toBe("500 B"));
  it("formats KB", () => expect(formatSize(2048)).toBe("2.0 KB"));
  it("formats MB", () => expect(formatSize(5 * 1048576)).toBe("5.0 MB"));
  it("formats GB", () => expect(formatSize(2 * 1073741824)).toBe("2.0 GB"));
});

// ---------------------------------------------------------------------------
// formatDate
// ---------------------------------------------------------------------------

describe("formatDate", () => {
  it("formats unix timestamp to YYYY-MM-DD", () => {
    // 2024-01-15 in UTC
    const ts = Math.floor(new Date("2024-01-15T12:00:00Z").getTime() / 1000);
    const result = formatDate(ts);
    expect(result).toMatch(/^2024-01-1[45]$/); // timezone may shift the day
  });
});

// ---------------------------------------------------------------------------
// fileIcon
// ---------------------------------------------------------------------------

describe("fileIcon", () => {
  it("returns folder icon for directories", () => {
    expect(fileIcon({ isDir: true, extension: "" })).toBe("󰉋");
  });

  it("returns image icon for image files", () => {
    expect(fileIcon({ isDir: false, extension: "png" })).toBe("󰋩");
  });

  it("returns code icon for source files", () => {
    expect(fileIcon({ isDir: false, extension: "js" })).toBe("󰴭");
    expect(fileIcon({ isDir: false, extension: "rs" })).toBe("󰴭");
  });

  it("returns nix icon for .nix files", () => {
    expect(fileIcon({ isDir: false, extension: "nix" })).toBe("󱄅");
  });

  it("returns default icon for unknown types", () => {
    expect(fileIcon({ isDir: false, extension: "xyz" })).toBe("󰈔");
  });
});
