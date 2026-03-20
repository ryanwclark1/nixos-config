import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

const sshHostListPath = resolve(quickshellRoot, "src/features/ssh/settings/SshHostList.qml");
const sshWidgetDataPath = resolve(quickshellRoot, "src/features/ssh/components/SshWidgetData.qml");
const controlCenterSectionPath = resolve(
  quickshellRoot,
  "src/features/settings/components/tabs/ShellControlCenterSection.qml"
);

describe("settings drag-and-drop contracts", () => {
  it("keeps SSH reorder disabled while filtering and routes moves through SshWidgetData", () => {
    const hostListSource = readFileSync(sshHostListPath, "utf8");
    const sshDataSource = readFileSync(sshWidgetDataPath, "utf8");

    expect(hostListSource).toContain('readonly property bool reorderDisabled: root.searchQuery.trim() !== ""');
    expect(hostListSource).toContain('title: "Reordering paused while filtering"');
    expect(hostListSource).toContain("dragEnabled: !root.reorderDisabled");
    expect(hostListSource).toContain("SettingsReorderButtons {");
    expect(hostListSource).toContain("moveUpEnabled: !root.reorderDisabled && hostRow.hostIndex > 0");
    expect(hostListSource).toContain("moveDownEnabled: !root.reorderDisabled && hostRow.hostIndex < (root.sshData.manualHosts.length - 1)");
    expect(sshDataSource).toContain("function moveManualHost(hostId, targetIndex)");
    expect(sshDataSource).toContain("SettingsReorderHelpers.moveArrayItem");
    expect(sshDataSource).toContain("return saveManualHosts(result.items);");
  });

  it("uses shared reorder state for Control Center toggles and plugins", () => {
    const source = readFileSync(controlCenterSectionPath, "utf8");

    expect(source).toContain("toggleReorderState.begin(\"control-center-toggle\"");
    expect(source).toContain("pluginReorderState.begin(\"control-center-plugin\"");
    expect(source).toContain("Helpers.moveDraggedOrderedValue(Config, ControlCenterRegistry, PluginService, \"controlCenterToggleOrder\"");
    expect(source).toContain("Helpers.moveDraggedOrderedValue(Config, ControlCenterRegistry, PluginService, \"controlCenterPluginOrder\"");
    expect(source).toContain('title: "Drag layout"');
  });
});
