import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const osdPath = resolve(quickshellRoot, "src/features/osd/Osd.qml");
const configPath = resolve(quickshellRoot, "src/services/Config.qml");

describe("critical OSD contract", () => {
  it("throttles repeated critical-state popups and re-shows when the summary changes", () => {
    const osdSource = readFileSync(osdPath, "utf8");

    expect(osdSource).toContain("property double _lastCriticalOsdAt: 0");
    expect(osdSource).toContain('property string _lastCriticalSummaryShown: ""');
    expect(osdSource).toContain("function showCriticalOsdIfNeeded()");
    expect(osdSource).toContain("var cooldownElapsed = root._lastCriticalOsdAt <= 0");
    expect(osdSource).toContain("var summaryChanged = summary !== root._lastCriticalSummaryShown;");
    expect(osdSource).toContain("if (!summaryChanged && !cooldownElapsed)");
    expect(osdSource).toContain("root._lastCriticalSummaryShown = summary;");
    expect(osdSource).toContain("root._lastCriticalOsdAt = now;");
    expect(osdSource).toContain("function onCriticalSummaryChanged()");
  });

  it("defines a dedicated critical OSD cooldown config", () => {
    const configSource = readFileSync(configPath, "utf8");

    expect(configSource).toContain("property int osdCriticalCooldownMs: 300000");
  });
});
