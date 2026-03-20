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
  it("delegates graphics session env to the shared helper instead of inline detection", () => {
    for (const scriptPath of [settingsResponsivePath, barWidgetsQaPath, runtimeWarningsPath]) {
      const source = readFileSync(scriptPath, "utf8");

      expect(source).toContain('source "${script_dir}/graphics-session-env.sh"');
      expect(source).toContain("build_repo_shell_env_array repo_shell_env");
      expect(source).toContain("populate_repo_shell_env");
      expect(source).not.toContain("local found_graphics_env=0");
    }
  });
});
