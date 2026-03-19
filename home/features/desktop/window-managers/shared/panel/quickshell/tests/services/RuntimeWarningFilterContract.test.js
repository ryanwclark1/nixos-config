import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const runtimeWarningFilterPath = resolve(quickshellRoot, "scripts/runtime-warning-filter.sh");

describe("runtime warning filter contract", () => {
  it("treats the transient WeatherService current-condition parse warning as non-blocking in settings QA", () => {
    const source = readFileSync(runtimeWarningFilterPath, "utf8");

    expect(source).toContain("\\[W\\]\\[WeatherService\\] Error: missing current condition");
  });
});
