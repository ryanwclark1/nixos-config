import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const barWidgetsQaPath = resolve(quickshellRoot, "scripts/check-bar-widgets-first-open.sh");

describe("Bar Widgets QA contract", () => {
  it("reuses the live repo-shell pid for the nested settings smoke", () => {
    const source = readFileSync(barWidgetsQaPath, "utf8");

    expect(source).toContain('bash "${script_dir}/check-settings-responsive.sh" --pid "${repo_shell_pid}" --skip-reload');
    expect(source).not.toContain('bash "${script_dir}/check-settings-responsive.sh" --id "${instance_id}" --skip-reload');
  });

  it("keeps the OCR score tolerant of the current Left Section glyph output", () => {
    const source = readFileSync(barWidgetsQaPath, "utf8");

    expect(source).toContain("L.{0,2}ft[[:space:]]+Section");
    expect(source).not.toContain("Left[[:space:]]+Section");
  });

  it("keeps the widget-row OCR tolerant of the current Workspace Switcher and Running Apps glyph output", () => {
    const source = readFileSync(barWidgetsQaPath, "utf8");

    expect(source).toContain("W.{0,4}ks?.{0,4}pace[[:space:]]+Switcher");
    expect(source).toContain("Runn.{0,2}ing[[:space:]]+Apps");
    expect(source).not.toContain("Workspace[[:space:]]+Switcher");
    expect(source).not.toContain("Running Apps");
  });

  it("tolerates the current OCR punctuation join in the Bar Widgets heading", () => {
    const source = readFileSync(barWidgetsQaPath, "utf8");

    expect(source).toContain("Bar[[:space:].]+Widgets");
    expect(source).not.toContain("Bar[[:space:]]+Widgets");
  });

  it("captures the Bar Widgets tab with a deep scroll so the first section stays in frame", () => {
    const source = readFileSync(barWidgetsQaPath, "utf8");

    expect(source).toContain('capture_scroll_y="520"');
    expect(source).toContain('--scroll-y "${capture_scroll_y}"');
  });
});
