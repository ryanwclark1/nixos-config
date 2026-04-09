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

describe("Screenshot menu contract", () => {
  it("opens wider and caps height against the current screen", () => {
    const menu = source("src/features/screenshot/ScreenshotMenu.qml");

    expect(menu).toContain("popupMinWidth: 360; popupMaxWidth: 420; compactThreshold: 380");
    expect(menu).toContain("readonly property int _desiredHeight: compactMode ? 760 : 840");
    expect(menu).toContain("readonly property int _screenMaxHeight: screen ? Math.max(420, screen.height - 32) : 760");
    expect(menu).toContain("implicitHeight: Math.min(_desiredHeight, _screenMaxHeight)");
  });

  it("keeps the menu body scrollable so lower sections remain reachable", () => {
    const menu = source("src/features/screenshot/ScreenshotMenu.qml");

    expect(menu).toContain("SharedWidgets.ScrollableContent {");
    expect(menu).toContain("Layout.fillHeight: true");
    expect(menu).toContain('SharedWidgets.SectionLabel { label: "AI TOOLS" }');
    expect(menu).toContain('label: "RECENT"');
  });
});
