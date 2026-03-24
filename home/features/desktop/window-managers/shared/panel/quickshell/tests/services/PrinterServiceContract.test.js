import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const printerServicePath = resolve(quickshellRoot, "src/services/PrinterService.qml");

describe("PrinterService contract", () => {
  it("probes the active CUPS server and normalizes a browser URL", () => {
    const source = readFileSync(printerServicePath, "utf8");

    expect(source).toContain("import Quickshell.Io");
    expect(source).toContain("lpstat -H");
    expect(source).toContain("*/cups.sock) url='http://localhost:631/'");
    expect(source).toContain('property string webInterfaceUrl: ""');
    expect(source).toContain("readonly property bool availabilityKnown: _webProbeComplete");
    expect(source).toContain('readonly property bool hasWebInterface: availabilityKnown && _webProbeReachable && webInterfaceUrl !== ""');
    expect(source).toContain("curl -fsSI --max-time 2");
  });

  it("refreshes and opens the CUPS web interface through explicit service actions", () => {
    const source = readFileSync(printerServicePath, "utf8");

    expect(source).toContain("function openWebInterface()");
    expect(source).toContain('Quickshell.execDetached(["xdg-open", root.webInterfaceUrl])');
    expect(source).toContain("printerPoll.triggerPoll();");
    expect(source).toContain("_refreshWebInterfaceState();");
  });
});
