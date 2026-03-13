import QtQuick
import Quickshell
import Quickshell.Io
import "."

pragma Singleton

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
      console.warn("ThemeService: could not load themes.json (error " + error + ")");
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
      console.error("ThemeService: failed to parse themes.json: " + e);
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
    Colors._isLight = false;
    Colors.reloadColors();
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
