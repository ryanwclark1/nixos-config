import { describe, it, expect } from "vitest";
import {
  widgetSettings,
  widgetDiagnosticId,
  itemLayoutFootprint,
  itemOccupiesSpace,
  compactPercentText,
  widgetValueStyle,
  statDisplayText,
  widgetDisplayMode,
  verticalWidgetBehavior,
  isWidgetHiddenInVertical,
  shouldCollapseVerticalOverflow,
  isCompactStatWidget,
  isIconOnlyStatWidget,
  isSummaryWidgetIconOnly,
  effectiveKeyboardLabelMode,
  widgetIntegerSetting,
  widgetBooleanSetting,
  widgetStringSetting,
  triggerWidgetIconOnly,
  triggerWidgetLabel,
} from "../../src/bar/PanelWidgetHelpers.js";

describe("widgetSettings", () => {
  it("returns settings from widget instance", () => {
    expect(widgetSettings({ settings: { x: 1 } })).toEqual({ x: 1 });
  });

  it("returns empty object for null/missing", () => {
    expect(widgetSettings(null)).toEqual({});
    expect(widgetSettings({})).toEqual({});
  });
});

describe("widgetDiagnosticId", () => {
  it("formats diagnostic string", () => {
    const result = widgetDiagnosticId(
      { widgetType: "cpuStatus", instanceId: "cpu1" },
      { id: "bar-main" }
    );
    expect(result).toBe("bar=bar-main widget=cpuStatus instance=cpu1");
  });

  it("handles missing instanceId", () => {
    const result = widgetDiagnosticId({ widgetType: "logo" }, { id: "bar1" });
    expect(result).toBe("bar=bar1 widget=logo");
  });
});

describe("itemLayoutFootprint / itemOccupiesSpace", () => {
  it("falls back to actual width and height when implicit size is zero", () => {
    const horizontalItem = {
      visible: true,
      implicitWidth: 0,
      implicitHeight: 0,
      width: 72,
      height: 32,
    };
    const verticalItem = {
      visible: true,
      implicitWidth: 0,
      implicitHeight: 0,
      width: 32,
      height: 72,
    };

    expect(itemLayoutFootprint(horizontalItem, false)).toBe(72);
    expect(itemLayoutFootprint(verticalItem, true)).toBe(72);
    expect(itemOccupiesSpace(horizontalItem, false)).toBe(true);
    expect(itemOccupiesSpace(verticalItem, true)).toBe(true);
  });

  it("still treats hidden items as non-occupying", () => {
    expect(
      itemOccupiesSpace(
        {
          visible: false,
          implicitWidth: 0,
          implicitHeight: 0,
          width: 72,
          height: 32,
        },
        false
      )
    ).toBe(false);
  });
});

describe("compactPercentText", () => {
  it("formats 0-1 value as percentage", () => {
    expect(compactPercentText(0.5)).toBe("50%");
    expect(compactPercentText(1)).toBe("100%");
    expect(compactPercentText(0)).toBe("0%");
  });

  it("clamps out-of-range values", () => {
    expect(compactPercentText(1.5)).toBe("100%");
    expect(compactPercentText(-0.5)).toBe("0%");
  });
});

describe("widgetValueStyle", () => {
  it("returns default style per widget type", () => {
    expect(widgetValueStyle({}, "cpuStatus")).toBe("percent");
    expect(widgetValueStyle({}, "ramStatus")).toBe("usage");
    expect(widgetValueStyle({}, "diskStatus")).toBe("percent");
    expect(widgetValueStyle({}, "networkStatus")).toBe("rate");
  });

  it("respects settings override", () => {
    expect(
      widgetValueStyle({ settings: { valueStyle: "usageTemp" } }, "cpuStatus")
    ).toBe("usageTemp");
  });

  it("rejects invalid style values", () => {
    expect(
      widgetValueStyle({ settings: { valueStyle: "bogus" } }, "cpuStatus")
    ).toBe("percent");
  });
});

describe("statDisplayText", () => {
  const ss = {
    cpuUsage: "45%",
    cpuTemp: "65°C",
    ramUsage: "8.2 GiB",
    ramPercent: 0.51,
    gpuUsage: "30%",
    gpuTemp: "55°C",
    diskUsage: "120 GiB",
    netDown: "5.2 MB/s",
    netUp: "1.1 MB/s",
  };

  it("returns CPU usage", () => {
    expect(statDisplayText("cpuStatus", {}, ss)).toBe("45%");
  });

  it("returns CPU+temp for usageTemp style", () => {
    expect(
      statDisplayText("cpuStatus", { settings: { valueStyle: "usageTemp" } }, ss)
    ).toBe("45% • 65°C");
  });

  it("returns RAM usage or percent", () => {
    expect(statDisplayText("ramStatus", {}, ss)).toBe("8.2 GiB");
    expect(
      statDisplayText("ramStatus", { settings: { valueStyle: "percent" } }, ss)
    ).toBe("51%");
  });

  it("returns network down rate", () => {
    expect(statDisplayText("networkStatus", {}, ss)).toBe("↓5.2 MB/s");
  });
});

describe("widgetDisplayMode", () => {
  it("defaults to auto", () => {
    expect(widgetDisplayMode({})).toBe("auto");
  });

  it("accepts valid modes", () => {
    expect(widgetDisplayMode({ settings: { displayMode: "icon" } })).toBe("icon");
    expect(widgetDisplayMode({ settings: { displayMode: "full" } })).toBe("full");
  });

  it("rejects invalid modes", () => {
    expect(widgetDisplayMode({ settings: { displayMode: "bogus" } })).toBe("auto");
  });
});

describe("isCompactStatWidget / isIconOnlyStatWidget", () => {
  it("returns true for compact mode", () => {
    expect(isCompactStatWidget({ settings: { displayMode: "compact" } }, false)).toBe(true);
  });

  it("auto mode is compact when vertical", () => {
    expect(isCompactStatWidget({}, true)).toBe(true);
    expect(isCompactStatWidget({}, false)).toBe(false);
  });

  it("icon-only detection", () => {
    expect(isIconOnlyStatWidget({ settings: { displayMode: "icon" } }, false)).toBe(true);
    expect(isIconOnlyStatWidget({}, false)).toBe(false);
  });

  it("forces vertical stats to compact unless explicitly icon-only", () => {
    const fullCpu = { widgetType: "cpuStatus", settings: { displayMode: "full" } };
    expect(isCompactStatWidget(fullCpu, true)).toBe(true);
    expect(isIconOnlyStatWidget(fullCpu, true)).toBe(false);

    const iconCpu = { widgetType: "cpuStatus", settings: { displayMode: "icon" } };
    expect(isCompactStatWidget(iconCpu, true)).toBe(false);
    expect(isIconOnlyStatWidget(iconCpu, true)).toBe(true);
  });
});

describe("vertical widget policy", () => {
  it("classifies built-in vertical behaviors", () => {
    expect(verticalWidgetBehavior({ widgetType: "windowTitle" })).toBe("hidden");
    expect(verticalWidgetBehavior({ widgetType: "keyboardLayout" })).toBe("short-label");
    expect(verticalWidgetBehavior({ widgetType: "cpuStatus" })).toBe("compact");
    expect(verticalWidgetBehavior({ widgetType: "weather" })).toBe("icon");
    expect(verticalWidgetBehavior({ widgetType: "pomodoro" })).toBe("icon");
    expect(verticalWidgetBehavior({ widgetType: "todo" })).toBe("icon");
    expect(verticalWidgetBehavior({ widgetType: "gameMode" })).toBe("icon");
    expect(verticalWidgetBehavior({ widgetType: "nightLight" })).toBe("icon");
    expect(verticalWidgetBehavior({ widgetType: "workspaces" })).toBe("native");
  });

  it("treats unrecognized widgets as unverified and collapsible when too wide", () => {
    expect(verticalWidgetBehavior({ widgetType: "plugin:test.widget" })).toBe("unverified");
    expect(shouldCollapseVerticalOverflow({ widgetType: "plugin:test.widget" })).toBe(true);
    expect(shouldCollapseVerticalOverflow({ widgetType: "workspaces" })).toBe(false);
  });

  it("marks hidden widgets for vertical bars", () => {
    expect(isWidgetHiddenInVertical({ widgetType: "ssh" })).toBe(true);
    expect(isWidgetHiddenInVertical({ widgetType: "dateTime" })).toBe(false);
  });
});

describe("summary and trigger overrides in vertical bars", () => {
  it("forces icon-only summary widgets on vertical bars even when set to full", () => {
    expect(
      isSummaryWidgetIconOnly({ widgetType: "weather", settings: { displayMode: "full" } }, true)
    ).toBe(true);
    expect(
      isSummaryWidgetIconOnly({ widgetType: "weather", settings: { displayMode: "full" } }, false)
    ).toBe(false);
  });

  it("forces simple trigger widgets to icon-only on vertical bars", () => {
    expect(
      triggerWidgetIconOnly({ widgetType: "logo", settings: { displayMode: "full" } }, true)
    ).toBe(true);
    expect(
      triggerWidgetIconOnly({ widgetType: "logo", settings: { displayMode: "full" } }, false)
    ).toBe(false);
  });
});

describe("effectiveKeyboardLabelMode", () => {
  it("forces keyboard layout widgets to short labels on vertical bars", () => {
    expect(
      effectiveKeyboardLabelMode({ widgetType: "keyboardLayout", settings: { labelMode: "full" } }, true)
    ).toBe("short");
    expect(
      effectiveKeyboardLabelMode({ widgetType: "keyboardLayout", settings: { labelMode: "full" } }, false)
    ).toBe("full");
  });
});

describe("widgetIntegerSetting", () => {
  it("returns parsed integer with clamping", () => {
    expect(widgetIntegerSetting({ settings: { size: "42" } }, "size", 10, 0, 100)).toBe(42);
    expect(widgetIntegerSetting({ settings: { size: "200" } }, "size", 10, 0, 100)).toBe(100);
    expect(widgetIntegerSetting({ settings: {} }, "size", 10, 0, 100)).toBe(10);
  });
});

describe("widgetBooleanSetting", () => {
  it("returns boolean from settings", () => {
    expect(widgetBooleanSetting({ settings: { show: true } }, "show", false)).toBe(true);
    expect(widgetBooleanSetting({ settings: { show: false } }, "show", true)).toBe(false);
  });

  it("returns fallback when undefined", () => {
    expect(widgetBooleanSetting({ settings: {} }, "show", true)).toBe(true);
  });
});

describe("widgetStringSetting", () => {
  it("returns value from allowed list", () => {
    expect(
      widgetStringSetting({ settings: { mode: "full" } }, "mode", "auto", ["auto", "full"])
    ).toBe("full");
  });

  it("returns fallback for invalid value", () => {
    expect(
      widgetStringSetting({ settings: { mode: "bogus" } }, "mode", "auto", ["auto", "full"])
    ).toBe("auto");
  });
});

describe("triggerWidgetIconOnly / triggerWidgetLabel", () => {
  it("defaults to icon-only", () => {
    expect(triggerWidgetIconOnly({})).toBe(true);
  });

  it("returns false for full mode", () => {
    expect(triggerWidgetIconOnly({ settings: { displayMode: "full" } })).toBe(false);
  });

  it("returns custom label or fallback", () => {
    expect(triggerWidgetLabel({ settings: { labelText: "My Label" } }, "Default")).toBe("My Label");
    expect(triggerWidgetLabel({ settings: {} }, "Default")).toBe("Default");
    expect(triggerWidgetLabel({ settings: { labelText: "  " } }, "Default")).toBe("Default");
  });
});
