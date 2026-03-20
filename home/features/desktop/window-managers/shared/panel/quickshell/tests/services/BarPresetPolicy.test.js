import { describe, it, expect } from "vitest";
import {
  HORIZONTAL_DEFAULT_PRESET,
  VERTICAL_BALANCED_PRESET,
  CUSTOM_PRESET,
  isAutoManagedPreset,
  defaultPresetForPosition,
  presetSectionWidgetTypes,
  verticalPresetSection,
  matchesPresetSectionWidgets,
  resolvePresetForBar,
} from "../../src/services/BarPresetPolicy.js";

function defaultSettings(widgetType) {
  return { marker: String(widgetType || "") };
}

function buildPresetWidgets(presetName) {
  const sections = presetSectionWidgetTypes(presetName);
  return Object.fromEntries(
    Object.entries(sections).map(([section, widgetTypes]) => [
      section,
      widgetTypes.map((widgetType, index) => ({
        instanceId: `${section}-${index}`,
        widgetType,
        enabled: true,
        settings: defaultSettings(widgetType),
      })),
    ])
  );
}

describe("BarPresetPolicy", () => {
  it("selects default presets from bar position", () => {
    expect(defaultPresetForPosition("top")).toBe(HORIZONTAL_DEFAULT_PRESET);
    expect(defaultPresetForPosition("bottom")).toBe(HORIZONTAL_DEFAULT_PRESET);
    expect(defaultPresetForPosition("left")).toBe(VERTICAL_BALANCED_PRESET);
    expect(defaultPresetForPosition("right")).toBe(VERTICAL_BALANCED_PRESET);
  });

  it("tracks which presets are auto-managed", () => {
    expect(isAutoManagedPreset(HORIZONTAL_DEFAULT_PRESET)).toBe(true);
    expect(isAutoManagedPreset(VERTICAL_BALANCED_PRESET)).toBe(true);
    expect(isAutoManagedPreset(CUSTOM_PRESET)).toBe(false);
    expect(isAutoManagedPreset("bogus")).toBe(false);
  });

  it("returns the recommended vertical section for preset widgets", () => {
    expect(verticalPresetSection("workspaces")).toBe("left");
    expect(verticalPresetSection("mediaBar")).toBe("center");
    expect(verticalPresetSection("audio")).toBe("right");
    expect(verticalPresetSection("windowTitle")).toBe("");
  });

  it("matches preset widgets only when composition and defaults line up", () => {
    const verticalWidgets = buildPresetWidgets(VERTICAL_BALANCED_PRESET);
    expect(
      matchesPresetSectionWidgets(verticalWidgets, VERTICAL_BALANCED_PRESET, defaultSettings)
    ).toBe(true);

    const customized = buildPresetWidgets(VERTICAL_BALANCED_PRESET);
    customized.right[0].settings = { marker: "customized" };
    expect(
      matchesPresetSectionWidgets(customized, VERTICAL_BALANCED_PRESET, defaultSettings)
    ).toBe(false);
  });

  it("migrates untouched vertical legacy layouts to the balanced preset", () => {
    const legacyHorizontalWidgets = buildPresetWidgets(HORIZONTAL_DEFAULT_PRESET);
    expect(
      resolvePresetForBar("left", "", legacyHorizontalWidgets, defaultSettings)
    ).toBe(VERTICAL_BALANCED_PRESET);
  });

  it("keeps customized vertical layouts marked as custom", () => {
    const customWidgets = buildPresetWidgets(HORIZONTAL_DEFAULT_PRESET);
    customWidgets.right = customWidgets.right.slice(0, 3);
    expect(
      resolvePresetForBar("left", "", customWidgets, defaultSettings)
    ).toBe(CUSTOM_PRESET);
  });
});
