pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "."
import "ScheduleUtils.js" as SU

QtObject {
  id: root

  property var themes: []
  property var activeTheme: null
  property string activeThemeId: ""

  property FileView manifestFile: FileView {
    path: Quickshell.env("HOME") + "/.config/quickshell/themes.json"
    blockLoading: true
    printErrors: false
    onLoaded: root._loadManifest()
    onLoadFailed: (error) => {
      Logger.w("ThemeService", "could not load themes.json (error " + error + ")");
    }
  }

  // Handle the startup race: themes.json may load before config.json.
  // When Config finally loads themeName, re-apply if we have the manifest ready.
  property Connections _configWatcher: Connections {
    target: Config
    function onThemeNameChanged() {
      if (Config.themeName && root.themes.length > 0 && !root.activeTheme) {
        root._applyById(Config.themeName);
      }
    }
  }

  function _loadManifest() {
    try {
      var raw = manifestFile.text();
      if (!raw) return;
      themes = JSON.parse(raw);
      // Apply saved theme on startup (if Config already loaded)
      if (Config.themeName) {
        _applyById(Config.themeName);
      }
    } catch (e) {
      Logger.e("ThemeService", "failed to parse themes.json:", e);
    }
  }

  function _applyById(themeId) {
    for (var i = 0; i < themes.length; i++) {
      if (themes[i].id === themeId) {
        activeTheme = themes[i];
        activeThemeId = themeId;
        Colors.applyBase24(themes[i].palette, themes[i].variant);
        return true;
      }
    }
    return false;
  }

  function applyTheme(themeId) {
    if (_applyById(themeId)) {
      Config.themeName = themeId;
    }
  }

  function clearTheme() {
    Config.themeName = "";
    activeThemeId = "";
    activeTheme = null;
    Colors._themeActive = false;
    Colors._isLight = false;
    Colors.reloadColors();
  }

  // ── Auto Schedule (fires once per minute via SystemClock) ──
  property Connections _scheduleClock: Connections {
    target: SystemClock
    enabled: Config.themeAutoScheduleEnabled
    function onMinutesChanged() { root._evaluateThemeSchedule(); }
  }
  Component.onCompleted: if (Config.themeAutoScheduleEnabled) _evaluateThemeSchedule()

  function _evaluateThemeSchedule() {
    if (!Config.themeAutoScheduleEnabled) return;
    if (!Config.themeDarkName && !Config.themeLightName) return;

    var now = new Date();
    var shouldBeDark = false;

    if (Config.themeAutoScheduleMode === "sunrise_sunset") {
      shouldBeDark = _shouldBeDarkForSunrise(now);
    } else {
      shouldBeDark = _shouldBeDarkForFixedTime(now);
    }

    var targetTheme = shouldBeDark ? Config.themeDarkName : Config.themeLightName;
    if (targetTheme && targetTheme !== root.activeThemeId) {
      root.applyTheme(targetTheme);
    }
  }

  function _shouldBeDarkForFixedTime(now) {
    return SU.isInWindow(
      SU.currentMinutes(now),
      Config.themeDarkHour * 60 + Config.themeDarkMinute,
      Config.themeLightHour * 60 + Config.themeLightMinute
    );
  }

  function _shouldBeDarkForSunrise(now) {
    return SU.isDarkAtLocation(now,
      parseFloat(Config.themeAutoLatitude),
      parseFloat(Config.themeAutoLongitude));
  }

  function searchThemes(query, variantFilter) {
    var q = (query || "").toLowerCase();
    var results = [];
    for (var i = 0; i < themes.length; i++) {
      var t = themes[i];
      if (variantFilter && t.variant !== variantFilter) continue;
      if (q && t.name.toLowerCase().indexOf(q) === -1 && t.id.toLowerCase().indexOf(q) === -1) continue;
      results.push(t);
    }
    return results;
  }
}
