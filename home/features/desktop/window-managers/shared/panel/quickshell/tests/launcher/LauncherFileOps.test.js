import { describe, it, expect } from "vitest";
import {
  parseGitIndex,
  tagFileItemsGit,
  fileItemParentPath,
  fileContextMenuModel,
} from "../../src/launcher/LauncherFileOps.js";

// ---------------------------------------------------------------------------
// parseGitIndex
// ---------------------------------------------------------------------------

describe("parseGitIndex", () => {
  it("parses newline-separated paths into a set object", () => {
    const raw = "src/main.js\nsrc/utils.js\nREADME.md";
    const set = parseGitIndex(raw);
    expect(set["src/main.js"]).toBe(true);
    expect(set["src/utils.js"]).toBe(true);
    expect(set["README.md"]).toBe(true);
  });

  it("ignores empty lines", () => {
    const raw = "src/main.js\n\nsrc/utils.js\n";
    const set = parseGitIndex(raw);
    expect(Object.keys(set)).toHaveLength(2);
    expect(set["src/main.js"]).toBe(true);
  });

  it("returns empty object for empty string", () => {
    expect(parseGitIndex("")).toEqual({});
  });

  it("returns empty object for null", () => {
    expect(parseGitIndex(null)).toEqual({});
  });

  it("returns empty object for undefined", () => {
    expect(parseGitIndex(undefined)).toEqual({});
  });

  it("handles a single path with no trailing newline", () => {
    const set = parseGitIndex("only/file.txt");
    expect(set["only/file.txt"]).toBe(true);
    expect(Object.keys(set)).toHaveLength(1);
  });

  it("keys are not looked up as true for absent paths", () => {
    const set = parseGitIndex("src/main.js");
    expect(set["src/other.js"]).toBeUndefined();
  });
});

// ---------------------------------------------------------------------------
// tagFileItemsGit
// ---------------------------------------------------------------------------

describe("tagFileItemsGit", () => {
  it("stamps _isGitTracked true for items whose relativePath is in the set", () => {
    const items = [
      { relativePath: "src/main.js" },
      { relativePath: "src/utils.js" },
    ];
    const set = { "src/main.js": true };
    tagFileItemsGit(items, set);
    expect(items[0]._isGitTracked).toBe(true);
    expect(items[1]._isGitTracked).toBe(false);
  });

  it("stamps _isGitTracked false when relativePath is not in the set", () => {
    const items = [{ relativePath: "untracked.txt" }];
    tagFileItemsGit(items, {});
    expect(items[0]._isGitTracked).toBe(false);
  });

  it("stamps _isGitTracked false for items with empty relativePath", () => {
    const items = [{ relativePath: "" }];
    tagFileItemsGit(items, { "": true });
    expect(items[0]._isGitTracked).toBe(false);
  });

  it("stamps _isGitTracked false for items with no relativePath property", () => {
    const items = [{ fullPath: "/home/user/file.txt" }];
    tagFileItemsGit(items, {});
    expect(items[0]._isGitTracked).toBe(false);
  });

  it("handles empty items array without throwing", () => {
    expect(() => tagFileItemsGit([], { "src/main.js": true })).not.toThrow();
  });

  it("tags all items in a large set correctly", () => {
    const set = { "a.js": true, "b.js": true, "c.js": true };
    const items = [
      { relativePath: "a.js" },
      { relativePath: "b.js" },
      { relativePath: "d.js" },
    ];
    tagFileItemsGit(items, set);
    expect(items[0]._isGitTracked).toBe(true);
    expect(items[1]._isGitTracked).toBe(true);
    expect(items[2]._isGitTracked).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// fileItemParentPath
// ---------------------------------------------------------------------------

describe("fileItemParentPath", () => {
  const root = "/home/user/projects";

  it("returns parent directory of a file path", () => {
    const item = { fullPath: "/home/user/projects/src/main.js" };
    expect(fileItemParentPath(item, root)).toBe("/home/user/projects/src");
  });

  it("returns root when file is directly under root (single slash segment)", () => {
    const item = { fullPath: "/home/user/projects/file.txt" };
    expect(fileItemParentPath(item, root)).toBe("/home/user/projects");
  });

  it("returns fileSearchRootResolved when item is null", () => {
    expect(fileItemParentPath(null, root)).toBe(root);
  });

  it("returns fileSearchRootResolved when item has no fullPath", () => {
    expect(fileItemParentPath({ name: "orphan" }, root)).toBe(root);
  });

  it("returns fileSearchRootResolved when slash is at index 0", () => {
    // e.g. fullPath = "/file.txt" — lastIndexOf('/') = 0
    const item = { fullPath: "/file.txt" };
    expect(fileItemParentPath(item, root)).toBe(root);
  });

  it("handles deeply nested path", () => {
    const item = { fullPath: "/a/b/c/d/e.txt" };
    expect(fileItemParentPath(item, root)).toBe("/a/b/c/d");
  });
});

// ---------------------------------------------------------------------------
// fileContextMenuModel
// ---------------------------------------------------------------------------

describe("fileContextMenuModel", () => {
  function makeCtx() {
    const calls = { exec: [], notices: [], clipboard: [], closes: 0 };
    return {
      fileOpenerCommand: "xdg-open",
      fileSearchRootResolved: "/home/user",
      execDetached: (args) => calls.exec.push(args),
      showTransientNotice: (msg, ms) => calls.notices.push({ msg, ms }),
      copyToClipboard: (text) => calls.clipboard.push(text),
      close: () => calls.closes++,
      _calls: calls,
    };
  }

  it("returns an empty array when item is null", () => {
    expect(fileContextMenuModel(null, makeCtx())).toEqual([]);
  });

  it("returns an empty array when item has no fullPath", () => {
    expect(fileContextMenuModel({ name: "orphan" }, makeCtx())).toEqual([]);
  });

  it("returns 5 entries (4 actions + 1 separator) for a valid file item", () => {
    const item = { name: "main.js", fullPath: "/home/user/src/main.js" };
    const model = fileContextMenuModel(item, makeCtx());
    expect(model).toHaveLength(5);
  });

  it("first entry has label 'Open' and an icon", () => {
    const item = { name: "main.js", fullPath: "/home/user/src/main.js" };
    const model = fileContextMenuModel(item, makeCtx());
    expect(model[0].label).toBe("Open");
    expect(typeof model[0].icon).toBe("string");
    expect(model[0].icon.length).toBeGreaterThan(0);
  });

  it("entry at index 3 is a separator", () => {
    const item = { name: "main.js", fullPath: "/home/user/src/main.js" };
    const model = fileContextMenuModel(item, makeCtx());
    expect(model[3].separator).toBe(true);
  });

  it("last entry has label 'Copy Full Path'", () => {
    const item = { name: "main.js", fullPath: "/home/user/src/main.js" };
    const model = fileContextMenuModel(item, makeCtx());
    expect(model[4].label).toBe("Copy Full Path");
  });

  it("all non-separator entries have an action function", () => {
    const item = { name: "main.js", fullPath: "/home/user/src/main.js" };
    const model = fileContextMenuModel(item, makeCtx());
    for (const entry of model) {
      if (!entry.separator) {
        expect(typeof entry.action).toBe("function");
      }
    }
  });

  it("'Copy Full Path' action copies item.fullPath to clipboard", () => {
    const item = { name: "main.js", fullPath: "/home/user/src/main.js" };
    const ctx = makeCtx();
    const model = fileContextMenuModel(item, ctx);
    model[4].action();
    expect(ctx._calls.clipboard).toContain("/home/user/src/main.js");
  });
});
