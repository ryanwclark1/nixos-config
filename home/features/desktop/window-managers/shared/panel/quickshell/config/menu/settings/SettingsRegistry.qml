import QtQuick

pragma Singleton

QtObject {
  id: root

  readonly property string defaultTabId: "system"

  readonly property var categories: [
    { id: "shell-core",      label: "Shell Core",      icon: "󰒓", order: 10, expandedByDefault: true  },
    { id: "visuals",         label: "Visuals",         icon: "󰏘", order: 20, expandedByDefault: true  },
    { id: "interaction",     label: "Interaction",     icon: "󰍉", order: 30, expandedByDefault: true  },
    { id: "surfaces",        label: "Surfaces",        icon: "󰖲", order: 40, expandedByDefault: true  },
    { id: "window-manager",  label: "Window Manager",  icon: "󱗼", order: 50, expandedByDefault: false },
    { id: "power-privacy",   label: "Power & Privacy", icon: "󰒃", order: 60, expandedByDefault: false },
    { id: "extensibility",   label: "Extensibility",   icon: "󰏗", order: 70, expandedByDefault: false },
    { id: "meta",            label: "Meta",            icon: "󰋗", order: 80, expandedByDefault: false }
  ]

  readonly property var tabs: [
    { id: "system",       legacyIndex: 0,  label: "System",         icon: "󰒓", categoryId: "shell-core",     order: 10, component: "SystemTab.qml",      searchTerms: ["shell", "notification", "control center"], owner: { surface: "controlCenter", service: "Config", configDomain: "shell" } },
    { id: "appearance",   legacyIndex: 1,  label: "Appearance",     icon: "󰏘", categoryId: "visuals",        order: 30, component: "AppearanceTab.qml",  searchTerms: ["appearance", "glass", "blur"], owner: { surface: "bar", service: "Config", configDomain: "appearance" } },
    { id: "theme",        legacyIndex: 2,  label: "Theme",          icon: "󰏘", categoryId: "visuals",        order: 10, component: "ThemeTab.qml",       searchTerms: ["theme", "colors"], owner: { surface: "", service: "ThemeService", configDomain: "theme" } },
    { id: "wallpaper",    legacyIndex: 3,  label: "Wallpaper",      icon: "󰸉", categoryId: "visuals",        order: 20, component: "WallpaperTab.qml",   searchTerms: ["wallpaper", "background", "pywal"], owner: { surface: "", service: "WallpaperService", configDomain: "wallpaper" } },
    { id: "hyprland",     legacyIndex: 4,  label: "Hyprland",       icon: "󱗼", categoryId: "window-manager", order: 10, component: "HyprlandTab.qml",    searchTerms: ["hyprland", "gaps", "opacity", "layout"], owner: { surface: "", service: "SettingsHub", configDomain: "hyprland" } },
    { id: "osd",          legacyIndex: 5,  label: "OSD",            icon: "󰍡", categoryId: "interaction",    order: 10, component: "OsdTab.qml",         searchTerms: ["osd", "overlay", "volume"], owner: { surface: "osd", service: "Config", configDomain: "osd" } },
    { id: "bars",         legacyIndex: 6,  label: "Bars",           icon: "󰕮", categoryId: "surfaces",       order: 10, component: "BarTab.qml",         searchTerms: ["bar", "bars", "multi bar", "display assignment"], owner: { surface: "bar", service: "Config", configDomain: "bars" } },
    { id: "bar-widgets",  legacyIndex: 7,  label: "Bar Widgets",    icon: "󰖲", categoryId: "surfaces",       order: 20, component: "BarWidgetsTab.qml",  searchTerms: ["bar widgets", "widgets", "sections"], owner: { surface: "bar", service: "BarWidgetRegistry", configDomain: "barWidgets" } },
    { id: "dock",         legacyIndex: 8,  label: "Dock",           icon: "󰍜", categoryId: "surfaces",       order: 30, component: "DockTab.qml",        searchTerms: ["dock", "pinned", "apps"], owner: { surface: "dock", service: "Config", configDomain: "dock" } },
    { id: "widgets",      legacyIndex: 9,  label: "Desktop Widgets",icon: "󰖲", categoryId: "surfaces",       order: 40, component: "WidgetsTab.qml",     searchTerms: ["widgets", "desktop"], owner: { surface: "desktopWidgets", service: "DesktopWidgetRegistry", configDomain: "desktopWidgets" } },
    { id: "lock-screen",  legacyIndex: 10, label: "Lock Screen",    icon: "󰌾", categoryId: "surfaces",       order: 50, component: "LockScreenTab.qml",  searchTerms: ["lock", "screen", "auth"], owner: { surface: "lockscreen", service: "Config", configDomain: "lockScreen" } },
    { id: "privacy",      legacyIndex: 11, label: "Privacy",        icon: "󰒃", categoryId: "power-privacy",  order: 10, component: "PrivacyTab.qml",     searchTerms: ["privacy", "camera", "mic"], owner: { surface: "privacyMenu", service: "PrivacyService", configDomain: "privacy" } },
    { id: "power",        legacyIndex: 12, label: "Power",          icon: "󰌪", categoryId: "power-privacy",  order: 20, component: "PowerTab.qml",       searchTerms: ["power", "battery"], owner: { surface: "powerMenu", service: "Config", configDomain: "power" } },
    { id: "hotkeys",      legacyIndex: 13, label: "Keybinds",       icon: "󰌌", categoryId: "interaction",    order: 30, component: "HotkeysTab.qml",     searchTerms: ["keys", "shortcuts"], owner: { surface: "", service: "Config", configDomain: "hotkeys" } },
    { id: "plugins",      legacyIndex: 14, label: "Plugins",        icon: "󰏗", categoryId: "extensibility",  order: 10, component: "PluginsTab.qml",     searchTerms: ["plugins", "extensions"], owner: { surface: "", service: "PluginService", configDomain: "plugins" } },
    { id: "about",        legacyIndex: 15, label: "About",          icon: "󰋗", categoryId: "meta",           order: 10, component: "AboutTab.qml",       searchTerms: ["about", "version"], owner: { surface: "", service: "Config", configDomain: "about" } },
    { id: "time-weather", legacyIndex: 16, label: "Time & Weather", icon: "󰔛", categoryId: "interaction",    order: 20, component: "TimeWeatherTab.qml", searchTerms: ["time", "clock", "weather"], owner: { surface: "dateTimeMenu", service: "WeatherService", configDomain: "timeWeather" } }
  ]

  function sortedCategories() {
    return categories.slice().sort(function(a, b) { return (a.order || 0) - (b.order || 0); });
  }

  function tabsForCategory(categoryId) {
    return tabs
      .filter(function(tab) { return tab.categoryId === categoryId; })
      .sort(function(a, b) { return (a.order || 0) - (b.order || 0); });
  }

  function findTab(tabId) {
    for (var i = 0; i < tabs.length; i++) {
      if (tabs[i].id === tabId) return tabs[i];
    }
    return null;
  }

  function tabIdForIndex(index) {
    for (var i = 0; i < tabs.length; i++) {
      if (tabs[i].legacyIndex === index) return tabs[i].id;
    }
    return "";
  }

  function indexForTabId(tabId) {
    for (var i = 0; i < tabs.length; i++) {
      if (tabs[i].id === tabId) return tabs[i].legacyIndex !== undefined ? tabs[i].legacyIndex : i;
    }
    return 0;
  }

  function searchTabs(query) {
    var q = String(query || "").trim().toLowerCase();
    if (!q) return [];

    var results = [];
    for (var i = 0; i < tabs.length; i++) {
      var t = tabs[i];
      var haystack = (t.label + " " + (t.searchTerms || []).join(" ")).toLowerCase();
      if (haystack.indexOf(q) !== -1) results.push(t);
    }
    return results;
  }

  function validateRegistry() {
    var seenTabIds = {};
    var seenLegacy = {};
    var categoryIds = {};

    for (var i = 0; i < categories.length; i++) {
      var c = categories[i];
      if (!c.id) console.warn("SettingsRegistry: category missing id at index " + i);
      if (categoryIds[c.id]) console.warn("SettingsRegistry: duplicate category id '" + c.id + "'");
      categoryIds[c.id] = true;
    }

    for (var j = 0; j < tabs.length; j++) {
      var t = tabs[j];
      if (!t.id) console.warn("SettingsRegistry: tab missing id at index " + j);
      if (seenTabIds[t.id]) console.warn("SettingsRegistry: duplicate tab id '" + t.id + "'");
      seenTabIds[t.id] = true;

      if (!t.categoryId || !categoryIds[t.categoryId])
        console.warn("SettingsRegistry: tab '" + t.id + "' references unknown category '" + t.categoryId + "'");

      if (!t.component)
        console.warn("SettingsRegistry: tab '" + t.id + "' missing component");

      if (t.legacyIndex !== undefined) {
        if (seenLegacy[t.legacyIndex] !== undefined)
          console.warn("SettingsRegistry: duplicate legacyIndex " + t.legacyIndex + " for tabs '" + seenLegacy[t.legacyIndex] + "' and '" + t.id + "'");
        seenLegacy[t.legacyIndex] = t.id;
      }
    }

    if (!findTab(defaultTabId))
      console.warn("SettingsRegistry: defaultTabId '" + defaultTabId + "' not found");
  }

  Component.onCompleted: validateRegistry()
}
