import { describe, it, expect } from "vitest";
import {
  isWallpaperFolderPathValid,
  normalizeSolidColor,
  imageSource,
  sanitizeSolidColorMap,
  sanitizeRecentSolidColors,
  rememberRecentSolidColor,
  resolveMonitor,
} from "../../src/features/settings/components/tabs/WallpaperTabHelpers.js";

describe("isWallpaperFolderPathValid", () => {
  it("accepts absolute paths", () => {
    expect(isWallpaperFolderPathValid("/home/user/wallpapers")).toBe(true);
  });

  it("accepts ~ and ~/path", () => {
    expect(isWallpaperFolderPathValid("~")).toBe(true);
    expect(isWallpaperFolderPathValid("~/Pictures")).toBe(true);
  });

  it("rejects relative paths", () => {
    expect(isWallpaperFolderPathValid("wallpapers")).toBe(false);
  });

  it("rejects empty/null", () => {
    expect(isWallpaperFolderPathValid("")).toBe(false);
    expect(isWallpaperFolderPathValid(null)).toBe(false);
  });
});

describe("normalizeSolidColor", () => {
  it("normalizes 6-digit hex to 8-digit", () => {
    expect(normalizeSolidColor("#ff0000")).toBe("ff0000ff");
    expect(normalizeSolidColor("FF0000")).toBe("ff0000ff");
  });

  it("passes through valid 8-digit hex", () => {
    expect(normalizeSolidColor("#ff000080")).toBe("ff000080");
  });

  it("returns empty for invalid colors", () => {
    expect(normalizeSolidColor("not-a-color")).toBe("");
    expect(normalizeSolidColor("")).toBe("");
    expect(normalizeSolidColor("#fff")).toBe(""); // too short
  });
});

describe("imageSource", () => {
  it("prepends file:// protocol", () => {
    expect(imageSource("/home/user/photo.png", {})).toBe(
      "file:///home/user/photo.png"
    );
  });

  it("returns empty for unsupported paths", () => {
    const unsupported = { "/bad/path.webp": true };
    expect(imageSource("/bad/path.webp", unsupported)).toBe("");
  });

  it("returns empty for null path", () => {
    expect(imageSource(null, {})).toBe("");
  });
});

describe("sanitizeSolidColorMap", () => {
  it("normalizes all values in map", () => {
    const result = sanitizeSolidColorMap({
      "DP-1": "#ff0000",
      "DP-2": "invalid",
    });
    expect(result["DP-1"]).toBe("ff0000ff");
    expect(result["DP-2"]).toBeUndefined();
  });

  it("returns empty for null", () => {
    expect(sanitizeSolidColorMap(null)).toEqual({});
  });
});

describe("sanitizeRecentSolidColors", () => {
  it("normalizes and deduplicates", () => {
    const result = sanitizeRecentSolidColors(["#ff0000", "#FF0000", "#00ff00"]);
    expect(result).toEqual(["ff0000ff", "00ff00ff"]);
  });

  it("limits to 12 entries", () => {
    const colors = Array.from({ length: 20 }, (_, i) =>
      "#" + i.toString(16).padStart(6, "0")
    );
    expect(sanitizeRecentSolidColors(colors).length).toBeLessThanOrEqual(12);
  });
});

describe("rememberRecentSolidColor", () => {
  it("prepends new color and removes duplicate", () => {
    const result = rememberRecentSolidColor("#00ff00", ["00ff00ff", "ff0000ff"]);
    expect(result[0]).toBe("00ff00ff");
    expect(result).toHaveLength(2); // deduped
  });

  it("limits to 12 entries", () => {
    const existing = Array.from({ length: 12 }, (_, i) =>
      i.toString(16).padStart(6, "0") + "ff"
    );
    const result = rememberRecentSolidColor("#ffffff", existing);
    expect(result).toHaveLength(12);
    expect(result[0]).toBe("ffffffff");
  });

  it("returns current list for invalid color", () => {
    expect(rememberRecentSolidColor("bad", ["aabbccff"])).toEqual(["aabbccff"]);
  });
});

describe("resolveMonitor", () => {
  it('converts "__all__" to empty string', () => {
    expect(resolveMonitor("__all__")).toBe("");
  });

  it("passes through specific monitor names", () => {
    expect(resolveMonitor("DP-1")).toBe("DP-1");
  });
});
