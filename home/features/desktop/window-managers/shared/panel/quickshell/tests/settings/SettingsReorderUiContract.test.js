import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

const dragHandlePath = resolve(
  quickshellRoot,
  "src/features/settings/components/SettingsDragHandle.qml"
);
const launcherModeListPath = resolve(
  quickshellRoot,
  "src/features/settings/components/tabs/LauncherModeList.qml"
);
const controlCenterPath = resolve(
  quickshellRoot,
  "src/features/settings/components/tabs/ShellControlCenterSection.qml"
);
const launcherSectionPath = resolve(
  quickshellRoot,
  "src/features/settings/components/tabs/ShellLauncherSection.qml"
);
const barWidgetsPath = resolve(
  quickshellRoot,
  "src/features/settings/components/tabs/BarWidgetsTab.qml"
);

describe("settings reorder UI contract", () => {
  it("routes the targeted settings surfaces through shared reorder rows and buttons", () => {
    const launcherModes = readFileSync(launcherModeListPath, "utf8");
    const controlCenter = readFileSync(controlCenterPath, "utf8");
    const launcher = readFileSync(launcherSectionPath, "utf8");
    const barWidgets = readFileSync(barWidgetsPath, "utf8");

    expect(launcherModes).toContain("SettingsReorderRow {");
    expect(launcherModes).toContain("SettingsReorderButtons {");
    expect(controlCenter).toContain("SettingsReorderRow {");
    expect(controlCenter).toContain("SettingsReorderButtons {");
    expect(launcher).toContain("SettingsReorderRow {");
    expect(launcher).toContain("SettingsReorderButtons {");
    expect(barWidgets).toContain("SettingsReorderRow {");
    expect(barWidgets).toContain("SettingsReorderButtons {");
  });

  it("uses offset-based dragging in the shared handle", () => {
    const source = readFileSync(dragHandlePath, "utf8");

    expect(source).toContain("readonly property real dragOffsetY");
    expect(source).toContain("onPositionChanged");
    expect(source).not.toContain("drag.target:");
  });

  it("keeps bar widgets on the shared inline handle instead of a duplicate reorder glyph", () => {
    const source = readFileSync(barWidgetsPath, "utf8");

    expect(source).toContain("overlayChildren: [");
    expect(source).toContain("onDragReleased:");
    expect(source).not.toContain('source: "re-order-dots-vertical.svg"');
  });

  it("does not reach into internal drag handle ids from consuming tabs", () => {
    const launcher = readFileSync(launcherSectionPath, "utf8");
    const barWidgets = readFileSync(barWidgetsPath, "utf8");

    expect(launcher).toContain("active: webProviderRow.dragging");
    expect(launcher).not.toMatch(/\bdragHandle\./);
    expect(barWidgets).toContain("Drag.active: root.dragReorderEnabled && widgetRow.dragging");
    expect(barWidgets).not.toMatch(/\bwidgetRow\.dragHandle\b/);
  });
});
