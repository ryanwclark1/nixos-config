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

    expect(source).toContain('check-settings-guardrails.sh" --skip-responsive --skip-launcher');
  });
});
