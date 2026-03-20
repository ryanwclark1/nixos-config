import { describe, it, expect } from "vitest";
import { sortPickerItems } from "../../src/features/settings/components/tabs/BarWidgetPickerPolicy.js";

describe("BarWidgetPickerPolicy", () => {
  it("ranks recommended and vertical-safe widgets ahead of hidden or unverified ones", () => {
    const items = [
      { widgetType: "plugin:test.widget", label: "Plugin Widget", section: "right" },
      { widgetType: "windowTitle", label: "Window Title", section: "left" },
      { widgetType: "audio", label: "Audio", section: "right" },
      { widgetType: "dateTime", label: "Clock", section: "center" },
      { widgetType: "workspaces", label: "Workspaces", section: "left" },
    ];

    const sorted = sortPickerItems(items, "right", true).map(item => item.widgetType);
    expect(sorted).toEqual([
      "audio",
      "dateTime",
      "workspaces",
      "windowTitle",
      "plugin:test.widget",
    ]);
  });

  it("keeps non-vertical picker sorting section-first", () => {
    const items = [
      { widgetType: "tray", label: "Tray", section: "right" },
      { widgetType: "audio", label: "Audio", section: "right" },
      { widgetType: "logo", label: "Launcher", section: "left" },
    ];

    const sorted = sortPickerItems(items, "right", false).map(item => item.widgetType);
    expect(sorted).toEqual(["audio", "tray", "logo"]);
  });
});
