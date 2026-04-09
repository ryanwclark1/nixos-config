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

describe("tooltip popup contract", () => {
  it("keeps bar tooltip edge logic while delegating rendering to the shared tooltip", () => {
    const barTooltipSource = source("src/features/bar/components/BarTooltip.qml");

    expect(barTooltipSource).toContain("readonly property var resolvedAnchorWindow:");
    expect(barTooltipSource).toContain("readonly property int tooltipSide:");
    expect(barTooltipSource).toContain("return Qt.BottomEdge;");
    expect(barTooltipSource).toContain("return Qt.TopEdge;");
    expect(barTooltipSource).toContain("return Qt.RightEdge;");
    expect(barTooltipSource).toContain("return Qt.LeftEdge;");
    expect(barTooltipSource).toContain("Tooltip {");
    expect(barTooltipSource).toContain("anchorWindow: root.resolvedAnchorWindow");
    expect(barTooltipSource).toContain("preferredSide: root.tooltipSide");
    expect(barTooltipSource).not.toContain("PopupWindow {");
  });

  it("uses the shared tooltip primitive for clipped settings color swatches", () => {
    const settingsColorRowSource = source("src/features/settings/components/SettingsColorRow.qml");

    expect(settingsColorRowSource).toContain("SharedWidgets.Tooltip {");
    expect(settingsColorRowSource).toContain("shown: colorMouse.containsMouse");
    expect(settingsColorRowSource).not.toContain("SharedWidgets.BarTooltip {");
  });
});
