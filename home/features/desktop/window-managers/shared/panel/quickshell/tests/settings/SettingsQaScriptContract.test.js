import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const settingsQaScriptPath = resolve(quickshellRoot, "scripts/check-settings-qa.sh");
const settingsGuardrailsScriptPath = resolve(quickshellRoot, "scripts/check-settings-guardrails.sh");

describe("settings QA script contract", () => {
  it("keeps duplicate runtime capture out of the settings-focused QA stack", () => {
    const source = readFileSync(settingsQaScriptPath, "utf8");

    expect(source).toContain('check-settings-guardrails.sh" --skip-responsive --skip-runtime-capture --skip-launcher --skip-settings-deep');
  });

  it("treats output-dir as the preserved bundle root for first-open review artifacts", () => {
    const source = readFileSync(settingsQaScriptPath, "utf8");

    expect(source).toContain('first_open_args+=(--output-dir "${output_dir}/bar-widgets-first-open")');
    expect(source).not.toContain('guardrail_args+=(--runtime-output-dir "${output_dir}/panel-qa-matrix")');
  });

  it("allows callers to skip runtime artifact capture when the smoke path already covered settings", () => {
    const source = readFileSync(settingsGuardrailsScriptPath, "utf8");

    expect(source).toContain("--skip-runtime-capture)");
    expect(source).toContain("if (( skip_runtime_capture == 1 )); then");
  });
});
