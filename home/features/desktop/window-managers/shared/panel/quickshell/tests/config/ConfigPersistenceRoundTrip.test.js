import { describe, it, expect, vi, afterEach } from "vitest";
import {
  _MAPS,
  _applyMap,
  applyData,
  buildData,
} from "../../src/services/config/ConfigPersistence.js";

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function createConfig(overrides = {}) {
  return {
    notifCenterWidthMin: 360,
    notifCenterWidthDefault: 440,
    notifCenterWidthMax: 560,
    controlCenterWidthMin: 440,
    controlCenterWidthDefault: 440,
    controlCenterWidthMax: 560,
    barConfigs: [],
    selectedBarId: "",
    disabledPlugins: [],
    pluginLauncherTriggers: {},
    pluginLauncherNoTrigger: {},
    pluginSettings: {},
    pluginHotReload: false,
    normalizeBarConfigs(bars) {
      return Array.isArray(bars) ? clone(bars) : [];
    },
    normalizeLauncherConfig(data) {
      _applyMap(this, data.launcher, _MAPS.launcher);
    },
    ...overrides,
  };
}

describe("ConfigPersistence round trip", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("round-trips representative settings domains through buildData/applyData", () => {
    const source = createConfig({
      barConfigs: [
        {
          id: "bar-vertical",
          name: "Side Bar",
          position: "left",
          widgetPreset: "vertical-balanced",
          sectionWidgets: { left: [], center: [], right: [] },
        },
      ],
      selectedBarId: "bar-vertical",
      notifCenterWidth: 500,
      controlCenterWidth: 520,
      themeAutoScheduleEnabled: true,
      themeAutoScheduleMode: "sunrise_sunset",
      themeDarkName: "Tokyo Night",
      themeLightName: "Paper",
      themeDarkHour: 21,
      themeDarkMinute: 15,
      themeLightHour: 7,
      themeLightMinute: 45,
      themeAutoLatitude: "41.88",
      themeAutoLongitude: "-87.63",
      notifPosition: "bottom_left",
      notifTimeoutLow: 1200,
      notifTimeoutNormal: 3400,
      notifTimeoutCritical: 0,
      notifCompact: true,
      notifPrivacyMode: true,
      notifHistoryEnabled: false,
      notifHistoryMaxCount: 15,
      notifHistoryMaxAgeDays: 3,
      notifRules: [{ appName: "Slack", mute: true }],
      workspaceShowEmpty: false,
      workspaceShowNames: true,
      workspaceShowAppIcons: true,
      workspaceMaxIcons: 5,
      workspacePillSize: "large",
      workspaceScrollEnabled: false,
      workspaceReverseScroll: true,
      workspaceActiveColor: "#112233",
      workspaceUrgentColor: "#ff5500",
      notepadProjectSync: false,
      powerAcMonitorTimeout: 15,
      powerAcLockTimeout: 20,
      powerAcSuspendTimeout: 45,
      powerAcSuspendAction: "hibernate",
      powerBatMonitorTimeout: 5,
      powerBatLockTimeout: 7,
      powerBatSuspendTimeout: 10,
      powerBatSuspendAction: "poweroff",
      nightLightEnabled: true,
      nightLightTemperature: 3700,
      nightLightAutoSchedule: true,
      nightLightScheduleMode: "sunrise_sunset",
      nightLightStartHour: 19,
      nightLightStartMinute: 30,
      nightLightEndHour: 6,
      nightLightEndMinute: 15,
      nightLightLatitude: "41.88",
      nightLightLongitude: "-87.63",
      audioPinnedOutputs: ["speaker"],
      audioPinnedInputs: ["desk-mic"],
      audioHiddenOutputs: ["hdmi-out"],
      audioHiddenInputs: ["webcam-mic"],
      displayProfiles: [{ id: "dock", outputs: ["DP-1"] }],
      displayAutoProfile: true,
      modelUsageClaudeEnabled: false,
      modelUsageCodexEnabled: true,
      modelUsageGeminiEnabled: true,
      modelUsageActiveProvider: "codex",
      launcherFileSearchRoot: "/workspace",
      launcherFileShowHidden: true,
      launcherFileOpener: "xdg-open",
      launcherWebCustomEngines: [
        { key: "docs", name: "Docs", urlTemplate: "https://example.com?q=%s" },
      ],
      launcherWebBangsEnabled: true,
      launcherWebBangsLastSync: "2026-03-19T00:00:00.000Z",
      weatherUiAnimationEnabled: true,
      marketTickers: "AAPL MSFT",
      wallpaperTransitionType: "wipe",
      wallpaperTransitionDuration: 2500,
      wallpaperUseShellRenderer: true,
    });

    const data = buildData(source);
    const applied = createConfig({
      notifCenterWidth: 440,
      controlCenterWidth: 440,
      powerBatSuspendAction: "suspend",
    });

    applyData(applied, data);

    expect(applied.selectedBarId).toBe("bar-vertical");
    expect(applied.barConfigs).toEqual([
      {
        id: "bar-vertical",
        name: "Side Bar",
        position: "left",
        widgetPreset: "vertical-balanced",
        sectionWidgets: { left: [], center: [], right: [] },
      },
    ]);
    expect(applied.notifCenterWidth).toBe(500);
    expect(applied.controlCenterWidth).toBe(520);
    expect(applied.themeAutoScheduleMode).toBe("sunrise_sunset");
    expect(applied.themeAutoLatitude).toBe("41.88");
    expect(applied.notifRules).toEqual([{ appName: "Slack", mute: true }]);
    expect(applied.workspaceReverseScroll).toBe(true);
    expect(applied.workspaceActiveColor).toBe("#112233");
    expect(applied.notepadProjectSync).toBe(false);
    expect(applied.powerAcSuspendAction).toBe("hibernate");
    expect(applied.powerBatSuspendAction).toBe("poweroff");
    expect(applied.nightLightLongitude).toBe("-87.63");
    expect(applied.audioHiddenInputs).toEqual(["webcam-mic"]);
    expect(applied.displayProfiles).toEqual([{ id: "dock", outputs: ["DP-1"] }]);
    expect(applied.displayAutoProfile).toBe(true);
    expect(applied.modelUsageActiveProvider).toBe("codex");
    expect(applied.launcherFileSearchRoot).toBe("/workspace");
    expect(applied.launcherWebCustomEngines).toEqual([
      { key: "docs", name: "Docs", urlTemplate: "https://example.com?q=%s" },
    ]);
    expect(applied.launcherWebBangsLastSync).toBe("2026-03-19T00:00:00.000Z");
    expect(applied.weatherUiAnimationEnabled).toBe(true);
    expect(applied.marketTickers).toBe("AAPL MSFT");
    expect(applied.wallpaperTransitionType).toBe("wipe");
    expect(applied.wallpaperTransitionDuration).toBe(2500);
    expect(applied.wallpaperUseShellRenderer).toBe(true);
  });

  it("migrates legacy model usage keys away before validation", () => {
    const warnSpy = vi.spyOn(console, "warn").mockImplementation(() => {});
    const applied = createConfig();
    const legacyData = {
      _version: 4,
      modelUsage: {
        claudeEnabled: true,
        codexEnabled: true,
        geminiEnabled: false,
        activeProvider: "codex",
        barMetric: "tokens",
        refreshSec: 45,
      },
      controlCenter: { width: 440 },
      bars: { selectedBarId: "", configs: [] },
      plugins: { disabled: [], launcherTriggers: {}, launcherNoTrigger: {}, settings: {}, hotReload: false },
    };

    applyData(applied, legacyData);

    expect(applied.modelUsageActiveProvider).toBe("codex");
    expect(legacyData._version).toBe(6);
    expect(legacyData.modelUsage).not.toHaveProperty("barMetric");
    expect(legacyData.modelUsage).not.toHaveProperty("refreshSec");
    expect(warnSpy).not.toHaveBeenCalledWith(expect.stringContaining("modelUsage"));
  });

  it("migrates v5 configs to add a notification-center width default", () => {
    const applied = createConfig({
      notifCenterWidth: 360,
    });
    const legacyData = {
      _version: 5,
      notifications: {
        width: 330,
      },
      bars: { selectedBarId: "", configs: [] },
      plugins: { disabled: [], launcherTriggers: {}, launcherNoTrigger: {}, settings: {}, hotReload: false },
    };

    applyData(applied, legacyData);

    expect(legacyData._version).toBe(6);
    expect(legacyData.notifications.centerWidth).toBe(440);
    expect(applied.notifCenterWidth).toBe(440);
    expect(applied.notifWidth).toBe(330);
  });
});
