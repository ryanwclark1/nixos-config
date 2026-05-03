import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

function source(relativePath) {
  return readFileSync(resolve(quickshellRoot, relativePath), "utf8");
}

describe("System monitor panel contract", () => {
  it("opens wider by default and reserves more width for detail tables", () => {
    const panel = source("src/features/system/surfaces/SystemMonitorPanel.qml");

    expect(panel).toContain("readonly property int telemetryColumnMinWidth: 360");
    expect(panel).toContain("readonly property int detailColumnMinWidth: 760");
    expect(panel).toContain("readonly property int panelMaxWidth: 1760");
    expect(panel).toContain("property int panelWidth: 1360");
    expect(panel).toContain("Math.round(root.panelWidth * 0.32)");
  });

  it("separates passive status chips from active jump controls", () => {
    const panel = source("src/features/system/surfaces/SystemMonitorPanel.qml");

    expect(panel).toContain('text: "STATUS"');
    expect(panel).toContain('text: "JUMP TO"');
    expect(panel).toContain('text: "PROC " + String(ProcessService.detailStatus || "idle").toUpperCase()');
    expect(panel).toContain('text: "UNIT " + String(ServiceUnitService.detailStatus || "idle").toUpperCase()');
    expect(panel).toContain('text: "I/O " + String(SystemIoTelemetryService.telemetryStatus || "loading").toUpperCase()');
    expect(panel).toContain('label: "Processes"');
    expect(panel).toContain('label: "Services"');
    expect(panel).toContain("onClicked: root.jumpToSection(0)");
    expect(panel).toContain("onClicked: root.jumpToSection(1)");
  });

  it("keeps jump controls wired to scroll, focus, and pulse the destination section", () => {
    const panel = source("src/features/system/surfaces/SystemMonitorPanel.qml");
    const processWidget = source("src/features/system/sections/ProcessWidget.qml");
    const serviceTable = source("src/features/system/sections/SystemServiceTable.qml");

    expect(panel).toContain("function jumpToSection(index)");
    expect(panel).toContain("focusKeyboardSection(index);");
    expect(panel).toContain("processTable.pulseJumpHighlight()");
    expect(panel).toContain("serviceTable.pulseJumpHighlight()");

    expect(processWidget).toContain("property bool jumpHighlighted: false");
    expect(processWidget).toContain("function pulseJumpHighlight()");
    expect(processWidget).toContain("opacity: root.jumpHighlighted ? 1.0 : 0.0");

    expect(serviceTable).toContain("property bool jumpHighlighted: false");
    expect(serviceTable).toContain("function pulseJumpHighlight()");
    expect(serviceTable).toContain("opacity: root.jumpHighlighted ? 1.0 : 0.0");
  });

  it("separates process state filters from list and tree view mode controls", () => {
    const processWidget = source("src/features/system/sections/ProcessWidget.qml");

    expect(processWidget).toContain("id: stateFilterFlow");
    expect(processWidget).toContain("id: processViewModeRow");
    expect(processWidget).toContain('label: "List"');
    expect(processWidget).toContain('label: "Tree"');
    expect(processWidget).toContain('selected: root.displayMode === "flat"');
    expect(processWidget).toContain('selected: root.displayMode === "tree"');
  });

  it("keeps the process table subscribed when embedded outside system monitor surfaces", () => {
    const processWidget = source("src/features/system/sections/ProcessWidget.qml");

    expect(processWidget).toContain("SharedWidgets.Ref { service: ProcessService }");
  });
});
