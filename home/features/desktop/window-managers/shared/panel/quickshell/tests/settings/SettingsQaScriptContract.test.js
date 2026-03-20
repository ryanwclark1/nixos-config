import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const settingsQaScriptPath = resolve(quickshellRoot, "scripts/check-settings-qa.sh");

describe("settings QA script contract", () => {
  it("keeps launcher runtime capture out of the settings-focused QA stack", () => {
    const source = readFileSync(settingsQaScriptPath, "utf8");

    expect(source).toContain('check-settings-guardrails.sh" --skip-responsive --skip-launcher --skip-settings-deep');
  });

  it("treats output-dir as the preserved bundle root for both first-open and matrix artifacts", () => {
    const source = readFileSync(settingsQaScriptPath, "utf8");

    expect(source).toContain('first_open_args+=(--output-dir "${output_dir}/bar-widgets-first-open")');
    expect(source).toContain('guardrail_args+=(--runtime-output-dir "${output_dir}/panel-qa-matrix")');
  });
});
