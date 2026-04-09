import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const osdPath = resolve(quickshellRoot, "src/features/osd/Osd.qml");
const configPath = resolve(quickshellRoot, "src/services/Config.qml");
const systemStatusPath = resolve(quickshellRoot, "src/services/SystemStatus.qml");

describe("critical OSD contract", () => {
  it("throttles repeated critical-state popups and re-shows when the OSD summary changes", () => {
    const osdSource = readFileSync(osdPath, "utf8");

    expect(osdSource).toContain("property double _lastCriticalOsdAt: 0");
    expect(osdSource).toContain('property string _lastCriticalSummaryShown: ""');
    expect(osdSource).toContain("function showCriticalOsdIfNeeded()");
    expect(osdSource).toContain("if (!startupComplete || !SystemStatus.shouldShowCriticalOsd)");
    expect(osdSource).toContain("var summary = String(SystemStatus.criticalOsdSummary || \"\");");
    expect(osdSource).toContain("var cooldownElapsed = root._lastCriticalOsdAt <= 0");
    expect(osdSource).toContain("var summaryChanged = summary !== root._lastCriticalSummaryShown;");
    expect(osdSource).toContain("if (!summaryChanged && !cooldownElapsed)");
    expect(osdSource).toContain("root._lastCriticalSummaryShown = summary;");
    expect(osdSource).toContain("root._lastCriticalOsdAt = now;");
    expect(osdSource).toContain("function onShouldShowCriticalOsdChanged()");
    expect(osdSource).toContain("function onCriticalOsdSummaryChanged()");
  });

  it("defines a dedicated critical OSD cooldown config", () => {
    const configSource = readFileSync(configPath, "utf8");

    expect(configSource).toContain("property int osdCriticalCooldownMs: 300000");
    expect(configSource).toContain("property int osdCriticalThermalSustainMs: 60000");
  });

  it("limits the critical OSD to sustained thermal and health-check failures instead of load spikes", () => {
    const systemStatusSource = readFileSync(systemStatusPath, "utf8");

    expect(systemStatusSource).toContain(
      "readonly property bool hasSustainedHighTemp: hasHighTemp",
    );
    expect(systemStatusSource).toContain(
      "&& (_lastThermalSampleAtMs - _highTempSinceMs) >= Math.max(0, Config.osdCriticalThermalSustainMs)",
    );
    expect(systemStatusSource).toContain(
      'readonly property bool shouldShowCriticalOsd: hasSustainedHighTemp || overallStatus === "failure"',
    );
    expect(systemStatusSource).toContain("property double _highTempSinceMs: 0");
    expect(systemStatusSource).toContain("property double _lastThermalSampleAtMs: 0");
    expect(systemStatusSource).toContain("readonly property var criticalOsdReasons: {");
    expect(systemStatusSource).toContain('if (hasSustainedHighTemp && cpuTempNum > _cpuTempHighThreshold)');
    expect(systemStatusSource).toContain('reasons.push("CPU " + cpuTemp);');
    expect(systemStatusSource).toContain('if (hasSustainedHighTemp && gpuTempNum > _gpuTempHighThreshold)');
    expect(systemStatusSource).toContain('reasons.push("GPU " + gpuTemp);');
    expect(systemStatusSource).toContain('reasons.push("health check failure");');
    expect(systemStatusSource).toContain("root._lastThermalSampleAtMs = now;");
    expect(systemStatusSource).toContain("if (root.hasHighTemp) {");
    expect(systemStatusSource).toContain("root._highTempSinceMs = now;");
  });
});
