import { describe, it, expect } from "vitest";
import { sortPickerItems } from "../../src/features/settings/components/tabs/BarWidgetPickerPolicy.js";
import {
  annotatePickerItems,
  canAddToBar,
  usageForWidgetType,
} from "../../src/services/BarWidgetInstancePolicy.js";

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

  it("summarizes existing widget usage across bar sections", () => {
    const usage = usageForWidgetType({
      left: [{ widgetType: "logo" }, { widgetType: "tray" }],
      center: [{ widgetType: "dateTime" }],
      right: [{ widgetType: "tray" }],
    }, "tray");

    expect(usage).toEqual({
      widgetType: "tray",
      instanceCount: 2,
      sections: ["left", "right"],
    });
  });

  it("blocks singleton widgets already present on the bar", () => {
    expect(canAddToBar({
      left: [{ widgetType: "logo" }],
      center: [],
      right: [],
    }, "logo")).toBe(false);
  });

  it("keeps repeatable widgets addable even when already present", () => {
    expect(canAddToBar({
      left: [{ widgetType: "separator" }],
      center: [{ widgetType: "spacer" }],
      right: [],
    }, "separator")).toBe(true);

    const annotated = annotatePickerItems([
      { widgetType: "separator", label: "Separator" },
      { widgetType: "logo", label: "Launcher" },
    ], {
      left: [{ widgetType: "separator" }, { widgetType: "logo" }],
      center: [],
      right: [],
    });

    expect(annotated).toEqual([
      expect.objectContaining({
        widgetType: "separator",
        instanceCount: 1,
        existingSections: ["left"],
        canAdd: true,
        repeatable: true,
      }),
      expect.objectContaining({
        widgetType: "logo",
        instanceCount: 1,
        existingSections: ["left"],
        canAdd: false,
        repeatable: false,
      }),
    ]);
  });
});
