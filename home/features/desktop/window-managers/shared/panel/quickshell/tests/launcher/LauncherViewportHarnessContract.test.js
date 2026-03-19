import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const launcherViewportScriptPath = resolve(quickshellRoot, "scripts/capture-launcher-viewport.sh");

describe("launcher viewport harness contract", () => {
  it("accepts both launcher landing-state variants for the empty-query home capture", () => {
    const source = readFileSync(launcherViewportScriptPath, "utf8");

    expect(source).toContain('if [[ "${expect_home}" == "either" || "${current_home}" == "${expect_home}" ]]; then');
    expect(source).toContain('expect_home="either"');
  });

  it("uses the numeric capture workspace flow shared by the passing QA harnesses", () => {
    const source = readFileSync(launcherViewportScriptPath, "utf8");

    expect(source).toContain('for candidate in $(seq 9101 9199); do');
    expect(source).toContain('hypr dispatch workspace "${target}" >/dev/null');
    expect(source).not.toContain('hypr dispatch workspace "name:${target}" >/dev/null');
    expect(source).not.toContain('candidate="qs-launcher-capture-');
  });
});
