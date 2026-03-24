import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const printerBarWidgetPath = resolve(quickshellRoot, "src/bar/components/PrinterBarWidget.qml");
const printerMenuPath = resolve(quickshellRoot, "src/features/status/PrinterMenu.qml");

describe("Printer widget CUPS affordances contract", () => {
  it("shows the bar widget when printers or the CUPS web UI are available", () => {
    const source = readFileSync(printerBarWidgetPath, "utf8");

    expect(source).toContain("visible: PrinterService.hasPrinters || PrinterService.hasWebInterface");
    expect(source).toContain('PrinterService.hasWebInterface ? "Manage Printing" : "Printers"');
  });

  it("adds a context action and menu shortcut for the CUPS web interface", () => {
    const widgetSource = readFileSync(printerBarWidgetPath, "utf8");
    const menuSource = readFileSync(printerMenuPath, "utf8");

    expect(widgetSource).toContain('label: "Open CUPS Web Interface"');
    expect(widgetSource).toContain('icon: "server.svg"');
    expect(widgetSource).toContain("visible: PrinterService.hasWebInterface");
    expect(widgetSource).toContain("action: () => PrinterService.openWebInterface()");

    expect(menuSource).toContain('tooltipText: "Open CUPS Web Interface"');
    expect(menuSource).toContain("visible: PrinterService.hasWebInterface");
    expect(menuSource).toContain("onClicked: PrinterService.openWebInterface()");
  });
});
