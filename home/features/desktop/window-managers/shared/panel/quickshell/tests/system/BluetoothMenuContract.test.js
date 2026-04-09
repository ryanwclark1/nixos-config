import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

function source(relativePath) {
  return readFileSync(resolve(quickshellRoot, relativePath), "utf8");
}

describe("Bluetooth menu contract", () => {
  it("renders through BluetoothCatalogService instead of directly binding available rows to Bluetooth.devices", () => {
    const menu = source("src/features/network/BluetoothMenu.qml");
    const catalogService = source("src/services/BluetoothCatalogService.qml");
    const dependencyService = source("src/services/DependencyService.qml");

    expect(menu).toContain("readonly property bool isScanning: BluetoothCatalogService.isScanning");
    expect(menu).toContain("model: BluetoothCatalogService.connectedDevices");
    expect(menu).toContain("model: BluetoothCatalogService.pairedDevices");
    expect(menu).toContain("model: BluetoothCatalogService.availableDevices");
    expect(menu).not.toContain("model: Bluetooth.devices");

    expect(catalogService).toContain("property Process _monitor: Process {");
    expect(catalogService).toContain('command: DependencyService.resolveCommand("qs-bluetooth-monitor")');
    expect(catalogService).toContain("root._entriesByAddress = Catalog.markMissingEntries");
    expect(catalogService).toContain('enriched.subtitle = Catalog.subtitleForEntry(enriched);');

    expect(dependencyService).toContain('"qs-bluetooth-monitor"');
  });
});
