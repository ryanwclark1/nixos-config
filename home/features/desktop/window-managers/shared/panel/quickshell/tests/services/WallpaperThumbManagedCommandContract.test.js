import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

describe("qs-wallpaper-thumb managed command contract", () => {
  it("DependencyService registers qs-wallpaper-thumb so WallpaperService can resolve it", () => {
    const dep = readFileSync(
      resolve(quickshellRoot, "src/services/DependencyService.qml"),
      "utf8"
    );
    expect(dep).toContain('"qs-wallpaper-thumb"');
    expect(dep).toMatch(/"qs-wallpaper-thumb"\s*:\s*\{[^}]*requires:\s*\[\s*\]/s);
  });

  it("default.nix packages qs-wallpaper-thumb into home.packages", () => {
    const nix = readFileSync(resolve(quickshellRoot, "default.nix"), "utf8");
    expect(nix).toContain('writeShellScriptBin "qs-wallpaper-thumb"');
    expect(nix).toContain("wallpaperThumbScript");
    expect(nix).toMatch(/home\.packages[\s\S]*wallpaperThumbScript/);
  });
});
