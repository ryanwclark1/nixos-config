import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const settingsResponsivePath = resolve(quickshellRoot, "scripts/check-settings-responsive.sh");
const barWidgetsQaPath = resolve(quickshellRoot, "scripts/check-bar-widgets-first-open.sh");
const runtimeWarningsPath = resolve(quickshellRoot, "scripts/check-runtime-warning-regressions.sh");

describe("repo-shell environment contracts", () => {
  it("does not mistake the notification-disable flag for a discovered session environment", () => {
    for (const scriptPath of [settingsResponsivePath, barWidgetsQaPath, runtimeWarningsPath]) {
      const source = readFileSync(scriptPath, "utf8");

      expect(source).toContain("local found_graphics_env=0");
      expect(source).toContain("found_graphics_env=1");
      expect(source).toContain("if (( found_graphics_env == 1 )); then");
      expect(source).toContain('repo_shell_env+=("QT_QPA_PLATFORM=wayland")');
      expect(source).toContain("HYPRLAND_INSTANCE_SIGNATURE|WAYLAND_DISPLAY|NIRI_SOCKET|DISPLAY");
    }
  });
});
