import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const tabsRoot = resolve(quickshellRoot, "src/features/settings/components/tabs");

function readTabSource(fileName) {
  return readFileSync(resolve(tabsRoot, fileName), "utf8");
}

describe("Launcher settings section components", () => {
  it("keeps the general and search cards in extracted section files", () => {
    const generalSource = readTabSource("LauncherGeneralSection.qml");
    const searchSource = readTabSource("LauncherSearchSection.qml");

    expect(generalSource.match(/SettingsCard \{/g)).toHaveLength(2);
    expect(searchSource.match(/SettingsCard \{/g)).toHaveLength(2);
    expect(generalSource).toContain("launcherWideFieldMinimumWidth");
    expect(searchSource).toContain("launcherWideFieldMinimumWidth");
  });

  it("keeps the web custom-engine form bound through explicit section props", () => {
    const webSource = readTabSource("LauncherWebSection.qml");

    expect(webSource).toContain("required property string newEngineKey");
    expect(webSource).toContain("required property string newEngineName");
    expect(webSource).toContain("required property string newEngineUrl");
    expect(webSource).toContain("required property string newEngineIcon");
    expect(webSource).toContain("text: root.newEngineKey");
    expect(webSource).toContain("text: root.newEngineName");
    expect(webSource).toContain("text: root.newEngineUrl");
    expect(webSource).toContain("text: root.newEngineIcon");
    expect(webSource).toContain("root.setNewEngineKeyFn");
    expect(webSource).toContain("root.setNewEngineNameFn");
    expect(webSource).toContain("root.setNewEngineUrlFn");
    expect(webSource).toContain("root.setNewEngineIconFn");
    expect(webSource).not.toContain("parent.newEngineKey");
  });

  it("keeps the modes and runtime specialized controls in their extracted files", () => {
    const modesSource = readTabSource("LauncherModesSection.qml");
    const runtimeSource = readTabSource("LauncherRuntimeSection.qml");

    expect(modesSource.match(/LauncherModeList \{/g)).toHaveLength(2);
    expect(modesSource).toContain("disabledLauncherModesFn()");
    expect(runtimeSource).toContain("LauncherDiagnosticsSettingsCard {");
    expect(runtimeSource).toContain("resetLauncherDefaultsFn");
  });
});
