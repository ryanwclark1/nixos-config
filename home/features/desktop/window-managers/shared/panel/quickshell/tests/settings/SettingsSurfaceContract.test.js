import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

function componentSource(relativePath) {
  return readFileSync(resolve(quickshellRoot, relativePath), "utf8");
}

describe("settings surface contract", () => {
  it("uses the shared header band for settings hero and cards", () => {
    expect(
      componentSource("src/features/settings/components/SettingsPageHero.qml")
    ).toContain("SettingsHeaderBand {");

    expect(
      componentSource("src/features/settings/components/SettingsCard.qml")
    ).toContain("SettingsHeaderBand {");

    expect(
      componentSource("src/features/settings/components/LauncherSettingsPanel.qml")
    ).toContain("SettingsHeaderBand {");
  });

  it("removes the hard-coded partial tint blocks from shared settings surfaces", () => {
    expect(
      componentSource("src/features/settings/components/SettingsPageHero.qml")
    ).not.toContain("heroColumn.implicitHeight * 0.45");

    expect(
      componentSource("src/features/settings/components/SettingsPageHero.qml")
    ).not.toContain("color: Colors.withAlpha(Colors.primary, 0.05)");

    expect(
      componentSource("src/features/settings/components/SettingsCard.qml")
    ).not.toContain("color: Colors.withAlpha(Colors.surface, 0.28)");

    expect(
      componentSource("src/features/settings/components/LauncherSettingsPanel.qml")
    ).not.toContain("SharedWidgets.AdaptiveAccentStrip {");
  });

  it("keeps the shared settings header band gradient-driven with a divider hook", () => {
    const source = componentSource("src/features/settings/components/SettingsHeaderBand.qml");

    expect(source).toContain("property real dividerY: bandHeight");
    expect(source).toContain("property bool showDivider: false");
    expect(source.match(/GradientStop \{/g)).toHaveLength(9);
  });

  it("exports shared settings surface helpers in the qmldir manifest", () => {
    const source = componentSource("src/features/settings/components/qmldir");

    expect(source).toContain("SettingsHeaderBand 1.0 SettingsHeaderBand.qml");
    expect(source).toContain("SettingsReorderButtons 1.0 SettingsReorderButtons.qml");
    expect(source).toContain("SettingsReorderRow 1.0 SettingsReorderRow.qml");
  });
});
