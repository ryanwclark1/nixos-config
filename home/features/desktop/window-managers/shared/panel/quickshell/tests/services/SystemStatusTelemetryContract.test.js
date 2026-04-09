import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

const systemStatusPath = resolve(quickshellRoot, "src/services/SystemStatus.qml");
const ramWidgetPath = resolve(quickshellRoot, "src/features/system/sections/RamWidget.qml");
const gpuWidgetPath = resolve(quickshellRoot, "src/features/system/sections/GPUWidget.qml");
const summaryPath = resolve(quickshellRoot, "src/features/system/sections/SystemMonitorSummary.qml");
const panelPath = resolve(quickshellRoot, "src/bar/Panel.qml");
const healthTabPath = resolve(quickshellRoot, "src/features/settings/components/tabs/HealthTab.qml");

describe("SystemStatus telemetry contract", () => {
  it("uses tagged fast-path telemetry rows and exposes RAM text helpers", () => {
    const systemStatus = readFileSync(systemStatusPath, "utf8");

    expect(systemStatus).toContain("import \"SystemStatusTelemetry.js\" as SystemStatusTelemetry");
    expect(systemStatus).toContain("cpu_raw\\\\t%s");
    expect(systemStatus).toContain("ram_used_text\\\\t%s");
    expect(systemStatus).toContain("ram_total_text\\\\t%s");
    expect(systemStatus).toContain("swap_used_text\\\\t%s");
    expect(systemStatus).toContain("swap_total_text\\\\t%s");
    expect(systemStatus).toContain("disk_pct\\\\t%s");
    expect(systemStatus).toContain("net_rx\\\\t%s");
    expect(systemStatus).toContain("net_tx\\\\t%s");
    expect(systemStatus).toContain("readonly property string ramPercentText");
    expect(systemStatus).toContain("readonly property string ramUsedTotalText");
    expect(systemStatus).toContain("property string swapUsage");
    expect(systemStatus).toContain("parse: function(out) { return root._parseLiteStats(out); }");
  });

  it("keeps the RAM card sourced from SystemStatus instead of a local free -h poll", () => {
    const ramWidget = readFileSync(ramWidgetPath, "utf8");

    expect(ramWidget).toContain("value: SystemStatus.ramUsedTotalText");
    expect(ramWidget).toContain("value: SystemStatus.ramPercentText");
    expect(ramWidget).toContain("value: SystemStatus.swapUsage");
    expect(ramWidget).not.toContain("free -h");
  });
});

describe("system resource icon contract", () => {
  it("keeps CPU, RAM, and GPU icons distinct across key surfaces", () => {
    const panel = readFileSync(panelPath, "utf8");
    const gpuWidget = readFileSync(gpuWidgetPath, "utf8");
    const summary = readFileSync(summaryPath, "utf8");
    const healthTab = readFileSync(healthTabPath, "utf8");

    expect(panel).toContain('statKey: "cpuStatus"');
    expect(panel).toContain('icon: "developer-board.svg"');
    expect(panel).toContain('statKey: "ramStatus"');
    expect(panel).toContain('icon: "memory.svg"');
    expect(panel).toContain('statKey: "gpuStatus"');
    expect(panel).toContain('icon: "board.svg"');

    expect(gpuWidget).toContain('icon: "board.svg"');
    expect(summary).toContain('icon: "memory.svg"');
    expect(summary).toContain('icon: "board.svg"');
    expect(healthTab).toContain('{ icon: "memory.svg", label: "RAM Usage"');
    expect(healthTab).toContain('{ icon: "board.svg", label: "GPU Usage"');
  });
});
