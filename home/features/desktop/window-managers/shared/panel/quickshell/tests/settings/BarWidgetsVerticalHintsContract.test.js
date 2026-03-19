import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

const barWidgetsTabPath = resolve(
  quickshellRoot,
  "src/features/settings/components/tabs/BarWidgetsTab.qml"
);
const barWidgetPickerOverlayPath = resolve(
  quickshellRoot,
  "src/features/settings/components/tabs/BarWidgetPickerOverlay.qml"
);
const registryPath = resolve(
  quickshellRoot,
  "src/features/bar/registry/BarWidgetRegistry.qml"
);

describe("Bar widgets vertical hints contract", () => {
  it("shows a vertical-mode callout and forwards bar position to summary chips", () => {
    const source = readFileSync(barWidgetsTabPath, "utf8");

    expect(source).toContain("readonly property bool selectedBarVertical: Config.isVerticalBar(selectedBarPosition)");
    expect(source).toContain('title: "Vertical bar mode"');
    expect(source).toContain("BarWidgetRegistry.summaryChips(widgetRow.widgetInstance, root.selectedBarPosition)");
    expect(source).toContain("verticalBar: root.selectedBarVertical");
  });

  it("shows vertical hints in the picker overlay", () => {
    const source = readFileSync(barWidgetPickerOverlayPath, "utf8");

    expect(source).toContain("required property bool verticalBar");
    expect(source).toContain("BarWidgetRegistry.verticalHintLabel(modelData.widgetType)");
  });

  it("defines vertical hint labels in the widget registry", () => {
    const source = readFileSync(registryPath, "utf8");

    expect(source).toContain("function verticalBehavior(widgetType)");
    expect(source).toContain("function verticalHintLabel(widgetType)");
    expect(source).toContain('return "Vertical: Hidden"');
    expect(source).toContain('return "Vertical: Icon"');
    expect(source).toContain('return "Vertical: Unverified"');
  });
});
