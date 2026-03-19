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
});
