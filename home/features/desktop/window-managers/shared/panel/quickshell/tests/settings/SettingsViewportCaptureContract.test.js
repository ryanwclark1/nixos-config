import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const captureSettingsViewportPath = resolve(quickshellRoot, "scripts/capture-settings-viewport.sh");

describe("settings viewport capture contract", () => {
  it("uses SettingsHub.openTabScrolled when a live capture requests a scroll offset", () => {
    const source = readFileSync(captureSettingsViewportPath, "utf8");

    expect(source).toContain('if (( scroll_y > 0 )); then');
    expect(source).toContain('call_ipc SettingsHub openTabScrolled "${tab_id}" "${scroll_y}"');
    expect(source).toContain('SettingsHub.openTabScrolled(tabId, scrollY)');
  });
});
