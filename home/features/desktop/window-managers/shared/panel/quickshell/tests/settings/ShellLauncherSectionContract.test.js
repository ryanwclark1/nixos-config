import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const launcherSectionPath = resolve(quickshellRoot, "src/features/settings/components/tabs/ShellLauncherSection.qml");

describe("ShellLauncherSection contract", () => {
  it("keeps new custom-engine form state on the section root", () => {
    const source = readFileSync(launcherSectionPath, "utf8");

    expect(source).toContain("property string newEngineKey");
    expect(source).toContain("property string newEngineName");
    expect(source).toContain("property string newEngineUrl");
    expect(source).toContain("property string newEngineIcon");
    expect(source).toContain("text: root.newEngineKey");
    expect(source).toContain("text: root.newEngineName");
    expect(source).toContain("text: root.newEngineUrl");
    expect(source).toContain("text: root.newEngineIcon");
    expect(source).not.toContain("parent.newEngineKey");
    expect(source).not.toContain("parent.newEngineName");
    expect(source).not.toContain("parent.newEngineUrl");
    expect(source).not.toContain("parent.newEngineIcon");
  });

  it("uses SettingsCard for launcher settings panels", () => {
    const source = readFileSync(launcherSectionPath, "utf8");

    expect(source).toContain("SettingsCard {");
    expect(source).not.toContain("LauncherSettingsPanel {");
    expect(source).not.toContain("LauncherSettingsHero {");
  });
});
