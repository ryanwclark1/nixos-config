import { describe, it, expect } from "vitest";
import { execSync } from "child_process";
import {
  md5Hex,
  canonicalFileUri,
  quickshellThumbKey,
  freedesktopLargeFileUrl,
} from "../../src/shared/WallpaperThumbnailCache.js";

describe("WallpaperThumbnailCache", () => {
  it("md5Hex matches known vectors", () => {
    expect(md5Hex("test")).toBe("098f6bcd4621d373cade4e832627b4f6");
    expect(md5Hex("")).toBe("d41d8cd98f00b204e9800998ecf8427e");
  });

  it("canonicalFileUri encodes segments", () => {
    expect(canonicalFileUri("/home/user/a b.png")).toBe(
      "file:///home/user/a%20b.png"
    );
    expect(canonicalFileUri("/tmp/x.png")).toBe("file:///tmp/x.png");
  });

  it("quickshellThumbKey matches newline-separated path and mtime", () => {
    const k = quickshellThumbKey("/pics/w.jpg", 1700000000);
    expect(k).toHaveLength(32);
    expect(k).toMatch(/^[0-9a-f]+$/);
    expect(quickshellThumbKey("/pics/w.jpg", 1700000001)).not.toBe(k);
  });

  it("quickshellThumbKey matches printf '%s\\n%s' | md5sum (qs-wallpaper-thumb contract)", () => {
    const path = "/pics/w.jpg";
    const mtime = 1700000000;
    const shell = execSync(
      `printf '%s\\n%s' '${path.replace(/'/g, "'\\''")}' '${mtime}' | md5sum | awk '{print $1}'`,
      { encoding: "utf8" }
    ).trim();
    expect(quickshellThumbKey(path, mtime)).toBe(shell);
  });

  it("freedesktopLargeFileUrl uses XDG cache and md5 of canonical URI", () => {
    const uri = canonicalFileUri("/foo/bar.png");
    const expectedName = md5Hex(uri) + ".png";
    const u = freedesktopLargeFileUrl("/foo/bar.png", "/var/cache", "/home/x");
    expect(u).toBe("file:///var/cache/thumbnails/large/" + expectedName);
  });
});
