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

describe("settings row layout contract", () => {
  it("keeps shared row components shrinkable inside grid layouts", () => {
    expect(
      componentSource("src/features/settings/components/SettingsToggleRow.qml")
    ).toContain("Layout.minimumWidth: 0");

    expect(
      componentSource("src/features/settings/components/SettingsModeRow.qml")
    ).toContain("Layout.minimumWidth: 0");

    expect(
      componentSource("src/features/settings/components/SettingsSliderRow.qml")
    ).toContain("Layout.minimumWidth: 0");

    expect(
      componentSource("src/features/settings/components/SettingsTextInputRow.qml")
    ).toContain("Layout.minimumWidth: 0");
  });
});
