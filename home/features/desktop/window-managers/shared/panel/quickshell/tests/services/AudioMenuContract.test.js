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

describe("Audio menu compact picker contract", () => {
  it("enables the compact device picker only when the popup is compact", () => {
    const menu = source("src/features/audio/AudioMenu.qml");

    expect(menu).toContain("useCompactDevicePicker: root.compactMode");
  });

  it("keeps a collapsed summary row and bounded list for compact device selection", () => {
    const section = source("src/features/audio/components/AudioDeviceSection.qml");

    expect(section).toContain("property bool useCompactDevicePicker: false");
    expect(section).toContain("property bool pickerExpanded: false");
    expect(section).toContain("property int compactPickerMaxHeight: 224");
    expect(section).toContain("visible: root.useCompactDevicePicker && root.deviceModel.length > 0");
    expect(section).toContain("source: IconHelpers.disclosureIcon(root.pickerExpanded)");
    expect(section).toContain("implicitHeight: Math.min(compactPickerView.contentHeight + Appearance.spacingXS * 2, root.compactPickerMaxHeight)");
    expect(section).toContain("AudioService.setDefaultDevice(modelData.id);");
    expect(section).toContain("root.pickerExpanded = false;");
    expect(section).toContain("model: root.useCompactDevicePicker ? [] : root.deviceModel");
  });
});
