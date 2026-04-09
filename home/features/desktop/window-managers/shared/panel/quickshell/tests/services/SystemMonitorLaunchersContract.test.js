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

describe("system monitor launchers", () => {
  it("exports the shared launcher button from the system sections module", () => {
    expect(source("src/features/system/sections/qmldir")).toContain(
      "SystemMonitorLaunchButton 1.0 SystemMonitorLaunchButton.qml"
    );
  });

  it("keeps hardware-card launch affordances opt-in on reusable widgets", () => {
    const widgetPaths = [
      "src/features/system/sections/CpuWidget.qml",
      "src/features/system/sections/RamWidget.qml",
      "src/features/system/sections/DiskWidget.qml",
      "src/features/system/sections/GPUWidget.qml",
      "src/features/system/sections/NetworkGraphs.qml",
    ];

    for (const path of widgetPaths) {
      const qml = source(path);
      expect(qml).toContain("property bool showSystemMonitorLauncher: false");
      expect(qml).toContain("SystemMonitorLaunchButton {");
      expect(qml).toContain("visible: root.showSystemMonitorLauncher");
    }
  });

  it("enables the launcher only on command center hardware cards", () => {
    const controlCenter = source("src/features/control-center/ControlCenter.qml");

    expect(controlCenter).toContain("CpuWidget {");
    expect(controlCenter).toContain("NetworkGraphs {");
    expect(controlCenter).toContain("RamWidget {");
    expect(controlCenter).toContain("DiskWidget {");
    expect(controlCenter).toContain("GPUWidget {");

    expect(controlCenter.match(/showSystemMonitorLauncher: true/g)).toHaveLength(5);
  });

  it("does not opt into launchers from the monitor surfaces themselves", () => {
    const monitorPanel = source("src/features/system/surfaces/SystemMonitorPanel.qml");
    const statsMenu = source("src/features/system/surfaces/SystemStatsMenu.qml");

    expect(monitorPanel).not.toContain("showSystemMonitorLauncher: true");
    expect(statsMenu).not.toContain("showSystemMonitorLauncher: true");
  });
});
