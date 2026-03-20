import { describe, it, expect } from "vitest";
import {
  buildFileItemsFromRaw,
  processParseChunk,
  fileQueryLooksLikePath,
} from "../../src/launcher/LauncherFileParser.js";

const HOME = "/home/user";

describe("buildFileItemsFromRaw", () => {
  it("builds items from newline-separated paths", () => {
    const raw = "Documents/readme.md\nPictures/photo.jpg";
    const items = buildFileItemsFromRaw(raw, HOME);
    expect(items).toHaveLength(2);
    expect(items[0].name).toBe("readme.md");
    expect(items[0].fullPath).toBe(HOME + "/Documents/readme.md");
    expect(items[0].extension).toBe("md");
    expect(items[0].parentPath).toBe("Documents");
    expect(items[0].displayPath).toBe("~/Documents");
    expect(items[0].pathDepth).toBe(1);
    expect(items[0].icon).toBe("scan-text.svg");
    expect(items[1].icon).toBe("image.svg");
  });

  it("handles absolute paths", () => {
    const raw = "/home/user/test.txt";
    const items = buildFileItemsFromRaw(raw, HOME);
    expect(items).toHaveLength(1);
    expect(items[0].name).toBe("test.txt");
    expect(items[0].relativePath).toBe("test.txt");
    expect(items[0].displayPath).toBe("~");
  });

  it("skips empty lines", () => {
    const raw = "a.txt\n\n\nb.txt\n";
    const items = buildFileItemsFromRaw(raw, HOME);
    expect(items).toHaveLength(2);
  });

  it("returns empty array for null/empty", () => {
    expect(buildFileItemsFromRaw("", HOME)).toEqual([]);
    expect(buildFileItemsFromRaw(null, HOME)).toEqual([]);
  });

  it("handles nested paths with correct depth", () => {
    const raw = "a/b/c/deep.txt";
    const items = buildFileItemsFromRaw(raw, HOME);
    expect(items[0].pathDepth).toBe(3);
    expect(items[0].parentPath).toBe("a/b/c");
    expect(items[0].icon).toBe("text-t.svg");
  });

  it("handles files without extension", () => {
    const items = buildFileItemsFromRaw("Makefile", HOME);
    expect(items[0].extension).toBe("");
    expect(items[0].icon).toBe("code.svg");
  });

  it("handles dotfiles (no extension — extIndex is 0, fails > 0 check)", () => {
    const items = buildFileItemsFromRaw(".bashrc", HOME);
    expect(items[0].name).toBe(".bashrc");
    expect(items[0].extension).toBe(""); // leading dot at index 0 is not treated as extension separator
    expect(items[0].icon).toBe("document.svg");
  });

  it("uses folder svg for directory entries", () => {
    const items = buildFileItemsFromRaw("d\tProjects/\n", HOME);
    expect(items[0].fileKind).toBe("dir");
    expect(items[0].icon).toBe("folder.svg");
  });
});

describe("processParseChunk", () => {
  it("processes lines in chunks", () => {
    const state = {
      lines: ["a.txt", "b.txt", "c.txt", "d.txt"],
      idx: 0,
      count: 0,
      items: new Array(4),
      homeDir: HOME,
      homePrefix: HOME + "/",
    };

    const r1 = processParseChunk(state, 2);
    expect(r1.done).toBe(false);
    expect(state.idx).toBe(2);
    expect(state.count).toBe(2);

    const r2 = processParseChunk(state, 2);
    expect(r2.done).toBe(true);
    expect(r2.items).toHaveLength(4);
  });
});

describe("fileQueryLooksLikePath", () => {
  it("returns true for absolute paths", () => {
    expect(fileQueryLooksLikePath("/etc")).toBe(true);
  });

  it("returns true for home-relative paths", () => {
    expect(fileQueryLooksLikePath("~/docs")).toBe(true);
  });

  it("returns true for paths containing /", () => {
    expect(fileQueryLooksLikePath("src/main")).toBe(true);
  });

  it("returns false for plain filenames", () => {
    expect(fileQueryLooksLikePath("readme")).toBe(false);
  });

  it("returns false for empty input", () => {
    expect(fileQueryLooksLikePath("")).toBe(false);
  });
});
