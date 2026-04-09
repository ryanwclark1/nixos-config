import { describe, it, expect } from "vitest";
import {
  _sanitizeDisabledPlugins,
  _sanitizePluginMap,
  _applyMap,
  _buildMap,
  applyData,
  buildData,
} from "../../src/services/config/ConfigPersistence.js";

// ---------------------------------------------------------------------------
// _sanitizeDisabledPlugins
// ---------------------------------------------------------------------------

describe("_sanitizeDisabledPlugins", () => {
  it("removes known removed plugin IDs", () => {
    const result = _sanitizeDisabledPlugins([
      "my.plugin",
      "quickshell.ssh.monitor",
      "other.plugin",
    ]);
    expect(result).toEqual(["my.plugin", "other.plugin"]);
  });

  it("returns empty array for non-array input", () => {
    expect(_sanitizeDisabledPlugins(null)).toEqual([]);
    expect(_sanitizeDisabledPlugins("string")).toEqual([]);
  });

  it("passes through valid IDs", () => {
    expect(_sanitizeDisabledPlugins(["a", "b"])).toEqual(["a", "b"]);
  });
});

// ---------------------------------------------------------------------------
// _sanitizePluginMap
// ---------------------------------------------------------------------------

describe("_sanitizePluginMap", () => {
  it("strips removed plugin keys from map", () => {
    const result = _sanitizePluginMap({
      "my.plugin": { foo: 1 },
      "quickshell.ssh.monitor": { bar: 2 },
    });
    expect(result).toEqual({ "my.plugin": { foo: 1 } });
  });

  it("returns empty object for null/non-object", () => {
    expect(_sanitizePluginMap(null)).toEqual({});
    expect(_sanitizePluginMap("string")).toEqual({});
  });
});

// ---------------------------------------------------------------------------
// _applyMap / _buildMap
// ---------------------------------------------------------------------------

describe("_applyMap", () => {
  it("applies section data to config via mapping table", () => {
    const config = {};
    const data = { height: 40, floating: true };
    const entries = [
      ["height", "barHeight"],
      ["floating", "barFloating"],
    ];
    _applyMap(config, data, entries);
    expect(config.barHeight).toBe(40);
    expect(config.barFloating).toBe(true);
  });

  it("skips undefined keys in data", () => {
    const config = { barHeight: 30 };
    _applyMap(config, { floating: false }, [
      ["height", "barHeight"],
      ["floating", "barFloating"],
    ]);
    expect(config.barHeight).toBe(30); // unchanged
    expect(config.barFloating).toBe(false);
  });

  it("applies transform functions", () => {
    const config = {};
    _applyMap(config, { lat: 42.5 }, [["lat", "latitude", String]]);
    expect(config.latitude).toBe("42.5");
  });

  it("does nothing for null section data", () => {
    const config = { x: 1 };
    _applyMap(config, null, [["x", "x"]]);
    expect(config.x).toBe(1);
  });
});

describe("_buildMap", () => {
  it("builds JSON-ready object from config via mapping table", () => {
    const config = { barHeight: 40, barFloating: true };
    const entries = [
      ["height", "barHeight"],
      ["floating", "barFloating"],
    ];
    const result = _buildMap(config, entries);
    expect(result).toEqual({ height: 40, floating: true });
  });
});

// ---------------------------------------------------------------------------
// buildData (integration — exercises _buildMap for all sections)
// ---------------------------------------------------------------------------

describe("buildData", () => {
  it("builds data object with all sections", () => {
    const config = {
      barHeight: 40,
      barFloating: false,
      barMargin: 4,
      barOpacity: 0.9,
      notifCenterWidth: 460,
      blurEnabled: true,
      glassOpacity: 0.8,
      settingsBackdropOpacity: 0.5,
      settingsSurfaceOpacity: 0.4,
      autoTransparency: false,
      selectedBarId: "bar1",
      barConfigs: [],
      controlCenterWidth: 400,
      launcherPrimaryModes: ["drun", "files", "system"],
      disabledPlugins: [],
      pluginLauncherTriggers: {},
      pluginLauncherNoTrigger: {},
      pluginSettings: {},
      pluginHotReload: false,
    };
    const data = buildData(config);
    expect(data.bar).toBeDefined();
    expect(data.bar.height).toBe(40);
    expect(data.notifications.centerWidth).toBe(460);
    expect(data.glass.blur).toBe(true);
    expect(data.bars.selectedBarId).toBe("bar1");
    expect(data.controlCenter.width).toBe(400);
    expect(data.launcher.primaryModes).toEqual(["drun", "files", "system"]);
    expect(data.plugins.disabled).toEqual([]);
  });
});

describe("power profile persistence", () => {
  it("applies mapped AC and battery power profile settings", () => {
    const config = {
      controlCenterWidthMin: 440,
      controlCenterWidthMax: 560,
      normalizeBarConfigs() {
        return [];
      },
      normalizeLauncherConfig() {},
    };
    const data = {
      _version: 2,
      power: {
        acMonitorTimeout: 15,
        acLockTimeout: 20,
        acSuspendTimeout: 45,
        acSuspendAction: "hibernate",
        batMonitorTimeout: 5,
        batLockTimeout: 7,
        batSuspendTimeout: 10,
        batSuspendAction: "poweroff",
      },
    };

    applyData(config, data);

    expect(config.powerAcMonitorTimeout).toBe(15);
    expect(config.powerAcSuspendAction).toBe("hibernate");
    expect(config.powerBatMonitorTimeout).toBe(5);
    expect(config.powerBatSuspendAction).toBe("poweroff");
  });
});
