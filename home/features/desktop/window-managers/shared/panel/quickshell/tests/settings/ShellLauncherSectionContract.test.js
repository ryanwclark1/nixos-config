import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const launcherSectionPath = resolve(quickshellRoot, "src/features/settings/components/tabs/ShellLauncherSection.qml");
const tabsQmldirPath = resolve(quickshellRoot, "src/features/settings/components/tabs/qmldir");
const componentsQmldirPath = resolve(quickshellRoot, "src/features/settings/components/qmldir");

describe("ShellLauncherSection contract", () => {
  it("keeps new custom-engine form state on the section root and passes it to LauncherWebSection", () => {
    const source = readFileSync(launcherSectionPath, "utf8");

    expect(source).toContain("property string newEngineKey");
    expect(source).toContain("property string newEngineName");
    expect(source).toContain("property string newEngineUrl");
    expect(source).toContain("property string newEngineIcon");
    expect(source).toContain("LauncherWebSection {");
    expect(source).toContain("newEngineKey: root.newEngineKey");
    expect(source).toContain("newEngineName: root.newEngineName");
    expect(source).toContain("newEngineUrl: root.newEngineUrl");
    expect(source).toContain("newEngineIcon: root.newEngineIcon");
    expect(source).not.toContain("parent.newEngineKey");
    expect(source).not.toContain("parent.newEngineName");
    expect(source).not.toContain("parent.newEngineUrl");
    expect(source).not.toContain("parent.newEngineIcon");
  });

  it("delegates launcher settings UI into extracted section components", () => {
    const source = readFileSync(launcherSectionPath, "utf8");

    expect(source).toContain("LauncherSettingsHero {");
    expect(source).toContain("LauncherGeneralSection {");
    expect(source).toContain("LauncherSearchSection {");
    expect(source).toContain("LauncherWebSection {");
    expect(source).toContain("LauncherModesSection {");
    expect(source).toContain("LauncherRuntimeSection {");
    expect(source).not.toContain("SettingsCard {");
  });

  it("keeps general/search field grids on a wider shared breakpoint", () => {
    const source = readFileSync(launcherSectionPath, "utf8");

    expect(source).toContain("readonly property int launcherWideFieldMinimumWidth: 420");
    expect(source.match(/launcherWideFieldMinimumWidth: root\.launcherWideFieldMinimumWidth/g)).toHaveLength(2);
  });

  it("exports extracted launcher components through the tabs qmldir", () => {
    const qmldir = readFileSync(tabsQmldirPath, "utf8");
    const componentsQmldir = readFileSync(componentsQmldirPath, "utf8");

    expect(componentsQmldir).toContain("LauncherSettingsHero 1.0 LauncherSettingsHero.qml");
    expect(qmldir).toContain("LauncherGeneralSection 1.0 LauncherGeneralSection.qml");
    expect(qmldir).toContain("LauncherSearchSection 1.0 LauncherSearchSection.qml");
    expect(qmldir).toContain("LauncherWebSection 1.0 LauncherWebSection.qml");
    expect(qmldir).toContain("LauncherModesSection 1.0 LauncherModesSection.qml");
    expect(qmldir).toContain("LauncherRuntimeSection 1.0 LauncherRuntimeSection.qml");
  });
});
