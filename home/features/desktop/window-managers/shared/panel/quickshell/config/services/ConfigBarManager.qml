import QtQuick
import Quickshell

// Internal helper for Config — manages bar configurations, widget instances,
// screen assignment, conflict detection, and legacy bar migration.
// Not a singleton — instantiated as a child of Config.
QtObject {
  id: mgr

  // The parent Config singleton — used to access properties and trigger saves.
  required property var config

  // ── Widget instance creation ─────────────────

  function defaultBarSectionWidgets() {
    return {
      left: [
        createWidgetInstance("logo"),
        createWidgetInstance("workspaces"),
        createWidgetInstance("windowTitle"),
        createWidgetInstance("taskbar"),
        createWidgetInstance("cpuStatus"),
        createWidgetInstance("ramStatus")
      ],
      center: [
        createWidgetInstance("dateTime"),
        createWidgetInstance("mediaBar"),
        createWidgetInstance("updates"),
        createWidgetInstance("cava"),
        createWidgetInstance("idleInhibitor")
      ],
      right: [
        createWidgetInstance("weather"),
        createWidgetInstance("network"),
        createWidgetInstance("bluetooth"),
        createWidgetInstance("audio"),
        createWidgetInstance("music"),
        createWidgetInstance("privacy"),
        createWidgetInstance("recording"),
        createWidgetInstance("battery"),
        createWidgetInstance("printer"),
        createWidgetInstance("aiChat"),
        createWidgetInstance("notepad"),
        createWidgetInstance("controlCenter"),
        createWidgetInstance("tray"),
        createWidgetInstance("clipboard"),
        createWidgetInstance("keyboardLayout"),
        createWidgetInstance("notifications")
      ]
    };
  }

  function generateId(prefix) {
    var stamp = Date.now().toString(36);
    var suffix = Math.floor(Math.random() * 1679616).toString(36);
    return prefix + "-" + stamp + "-" + suffix;
  }

  function createWidgetInstance(widgetType, initialSettings) {
    var defaults = {};
    if (BarWidgetRegistry && BarWidgetRegistry.defaultSettings)
      defaults = BarWidgetRegistry.defaultSettings(widgetType);
    var settingsCopy = JSON.parse(JSON.stringify(defaults));
    if (initialSettings) {
      var provided = JSON.parse(JSON.stringify(initialSettings));
      for (var key in provided)
        settingsCopy[key] = provided[key];
    }
    return {
      instanceId: generateId("widget"),
      widgetType: widgetType,
      enabled: true,
      settings: settingsCopy
    };
  }

  // ── Bar config creation ─────────────────

  function createBarConfig(name) {
    var barIndex = (config.barConfigs || []).length + 1;
    var preferredPositions = ["top", "bottom", "left", "right"];
    var selectedPosition = "top";
    for (var posIndex = 0; posIndex < preferredPositions.length; ++posIndex) {
      var candidatePos = preferredPositions[posIndex];
      var occupied = false;
      for (var i = 0; i < (config.barConfigs || []).length; ++i) {
        if (config.barConfigs[i].enabled && config.barConfigs[i].position === candidatePos) {
          occupied = true;
          break;
        }
      }
      if (!occupied && config.dockEnabled && config.dockPosition === candidatePos)
        occupied = true;
      if (!occupied) {
        selectedPosition = candidatePos;
        break;
      }
    }
    return {
      id: generateId("bar"),
      name: name || (barIndex === 1 ? "Main Bar" : ("Bar " + barIndex)),
      enabled: true,
      position: selectedPosition,
      displayMode: "all",
      displayTargets: [],
      height: config.barHeight,
      floating: config.barFloating,
      margin: config.barMargin,
      opacity: config.barOpacity,
      sectionWidgets: defaultBarSectionWidgets()
    };
  }

  // ── Geometry helpers ─────────────────

  function isValidEdge(position) {
    return position === "top" || position === "bottom" || position === "left" || position === "right";
  }

  function isVerticalBar(positionOrBar) {
    var position = (typeof positionOrBar === "string") ? positionOrBar : ((positionOrBar && positionOrBar.position) || "top");
    return position === "left" || position === "right";
  }

  function barThickness(barConfig) {
    return Math.max(24, parseInt(barConfig && barConfig.height !== undefined ? barConfig.height : config.barHeight, 10) || config.barHeight);
  }

  function floatingInset(barConfig) {
    return !!(barConfig && barConfig.floating) ? Math.max(0, parseInt(barConfig.margin || 0, 10)) : 0;
  }

  // ── Screen helpers ─────────────────

  function screenName(screen) {
    if (!screen) return "";
    if (screen.name !== undefined) return String(screen.name);
    return String(screen);
  }

  function allScreens() {
    return Quickshell.screens ? Quickshell.screens.values || Quickshell.screens : [];
  }

  function primaryScreen() {
    var screens = allScreens();
    return screens.length > 0 ? screens[0] : null;
  }

  // ── Widget normalization ─────────────────

  function normalizeSectionWidgets(sectionWidgets) {
    var source = sectionWidgets || {};
    var normalized = { left: [], center: [], right: [] };
    var sections = ["left", "center", "right"];

    for (var i = 0; i < sections.length; ++i) {
      var section = sections[i];
      var items = source[section] || [];
      for (var j = 0; j < items.length; ++j) {
        var normalizedItems = normalizeWidgetInstances(items[j]);
        for (var k = 0; k < normalizedItems.length; ++k) {
          normalized[section].push(normalizedItems[k]);
        }
      }
    }

    return normalized;
  }

  function cloneWidgetSettings(item) {
    return item && item.settings ? JSON.parse(JSON.stringify(item.settings)) : {};
  }

  function normalizedWidgetSettings(widgetType, item) {
    var defaults = {};
    if (BarWidgetRegistry && BarWidgetRegistry.defaultSettings)
      defaults = BarWidgetRegistry.defaultSettings(widgetType);
    var merged = JSON.parse(JSON.stringify(defaults));
    var current = cloneWidgetSettings(item);
    for (var key in current)
      merged[key] = current[key];
    return merged;
  }

  function normalizeWidgetInstances(item) {
    var widgetType = item && item.widgetType ? item.widgetType : (item && item.widgetId ? item.widgetId : "");
    if ((typeof item === "string" && item === "systemMonitor") || widgetType === "systemMonitor") {
      var enabled = item && item.enabled !== undefined ? !!item.enabled : true;
      return [
        {
          instanceId: generateId("widget"),
          widgetType: "cpuStatus",
          enabled: enabled,
          settings: normalizedWidgetSettings("cpuStatus", item)
        },
        {
          instanceId: generateId("widget"),
          widgetType: "ramStatus",
          enabled: enabled,
          settings: normalizedWidgetSettings("ramStatus", item)
        }
      ];
    }

    return [normalizeWidgetInstance(item)];
  }

  function normalizeWidgetInstance(item) {
    if (typeof item === "string") return createWidgetInstance(item);

    var widgetType = item && item.widgetType ? item.widgetType : (item && item.widgetId ? item.widgetId : "spacer");
    return {
      instanceId: item && item.instanceId ? item.instanceId : generateId("widget"),
      widgetType: widgetType,
      enabled: item && item.enabled !== undefined ? !!item.enabled : true,
      settings: normalizedWidgetSettings(widgetType, item)
    };
  }

  // ── Bar config normalization ─────────────────

  function normalizeBarConfig(bar, index) {
    var normalized = {
      id: bar && bar.id ? bar.id : generateId("bar"),
      name: bar && bar.name ? bar.name : (index === 0 ? "Main Bar" : ("Bar " + (index + 1))),
      enabled: bar && bar.enabled !== undefined ? !!bar.enabled : true,
      position: isValidEdge(bar && bar.position) ? bar.position : "top",
      displayMode: bar && (bar.displayMode === "primary" || bar.displayMode === "specific") ? bar.displayMode : "all",
      displayTargets: bar && Array.isArray(bar.displayTargets) ? bar.displayTargets.slice() : [],
      height: Math.max(24, parseInt(bar && bar.height !== undefined ? bar.height : config.barHeight, 10) || config.barHeight),
      floating: bar && bar.floating !== undefined ? !!bar.floating : config.barFloating,
      margin: Math.max(0, parseInt(bar && bar.margin !== undefined ? bar.margin : config.barMargin, 10) || config.barMargin),
      opacity: Math.max(0.2, Math.min(1.0, Number(bar && bar.opacity !== undefined ? bar.opacity : config.barOpacity) || config.barOpacity)),
      autoHide: bar && bar.autoHide !== undefined ? !!bar.autoHide : false,
      autoHideDelay: Math.max(100, parseInt(bar && bar.autoHideDelay !== undefined ? bar.autoHideDelay : 300, 10) || 300),
      noBackground: bar && bar.noBackground !== undefined ? !!bar.noBackground : false,
      maximizeDetect: bar && bar.maximizeDetect !== undefined ? !!bar.maximizeDetect : false,
      scrollBehavior: bar && (bar.scrollBehavior === "workspace" || bar.scrollBehavior === "volume") ? bar.scrollBehavior : "none",
      shadowEnabled: bar && bar.shadowEnabled !== undefined ? !!bar.shadowEnabled : false,
      shadowOpacity: Math.max(0.0, Math.min(1.0, Number(bar && bar.shadowOpacity !== undefined ? bar.shadowOpacity : 0.3) || 0.3)),
      fontScale: Math.max(0.5, Math.min(2.0, Number(bar && bar.fontScale !== undefined ? bar.fontScale : 1.0) || 1.0)),
      iconScale: Math.max(0.5, Math.min(2.0, Number(bar && bar.iconScale !== undefined ? bar.iconScale : 1.0) || 1.0)),
      sectionWidgets: normalizeSectionWidgets(bar && bar.sectionWidgets ? bar.sectionWidgets : defaultBarSectionWidgets())
    };

    return normalized;
  }

  function migrateLegacyBars(data) {
    var migrated = createBarConfig("Main Bar");

    if (data && data.bar) {
      if (data.bar.height !== undefined) migrated.height = Math.max(24, parseInt(data.bar.height, 10) || config.barHeight);
      if (data.bar.floating !== undefined) migrated.floating = !!data.bar.floating;
      if (data.bar.margin !== undefined) migrated.margin = Math.max(0, parseInt(data.bar.margin, 10) || config.barMargin);
      if (data.bar.opacity !== undefined) migrated.opacity = Math.max(0.2, Math.min(1.0, Number(data.bar.opacity) || config.barOpacity));
    }

    return [migrated];
  }

  function normalizeBarConfigs(bars, data) {
    var inputBars = Array.isArray(bars) ? bars : [];
    if (inputBars.length === 0)
      inputBars = migrateLegacyBars(data);

    var normalized = [];
    for (var i = 0; i < inputBars.length && normalized.length < config.maxBars; ++i) {
      normalized.push(normalizeBarConfig(inputBars[i], normalized.length));
    }

    if (normalized.length === 0)
      normalized.push(normalizeBarConfig(createBarConfig("Main Bar"), 0));

    return normalized;
  }

  // ── Bar selection ─────────────────

  function ensureSelectedBar() {
    if (!config.barConfigs || config.barConfigs.length === 0) {
      config.selectedBarId = "";
      return;
    }

    var i;
    for (i = 0; i < config.barConfigs.length; ++i) {
      if (config.barConfigs[i].id === config.selectedBarId) return;
    }

    config.selectedBarId = config.barConfigs[0].id;
  }

  function selectedBar() {
    return barById(config.selectedBarId) || (config.barConfigs.length > 0 ? config.barConfigs[0] : null);
  }

  function barById(barId) {
    var bars = config.barConfigs || [];
    for (var i = 0; i < bars.length; ++i) {
      if (bars[i].id === barId) return bars[i];
    }
    return null;
  }

  // ── Screen–bar assignment ─────────────────

  function barsForScreen(screen) {
    var screensBars = [];
    var bars = config.barConfigs || [];
    for (var i = 0; i < bars.length; ++i) {
      if (barEnabledOnScreen(bars[i], screen)) screensBars.push(bars[i]);
    }
    return screensBars;
  }

  function barEnabledOnScreen(barConfig, screen) {
    if (!barConfig || !barConfig.enabled || !screen) return false;
    var mode = barConfig.displayMode || "all";
    if (mode === "all") return true;
    if (mode === "primary") return primaryScreen() === screen;

    var targets = barConfig.displayTargets || [];
    var name = screenName(screen);
    return targets.indexOf(name) !== -1;
  }

  function screensForBar(barConfig) {
    var screens = allScreens();
    var matches = [];
    for (var i = 0; i < screens.length; ++i) {
      if (barEnabledOnScreen(barConfig, screens[i])) matches.push(screens[i]);
    }
    return matches;
  }

  function barSectionWidgets(barConfig, section) {
    if (!barConfig || !barConfig.sectionWidgets || !barConfig.sectionWidgets[section]) return [];
    return barConfig.sectionWidgets[section];
  }

  function sectionLabel(section, position) {
    if (!isVerticalBar(position)) {
      if (section === "left") return "Left";
      if (section === "center") return "Center";
      return "Right";
    }

    if (section === "left") return "Top";
    if (section === "center") return "Middle";
    return "Bottom";
  }

  // ── Bar CRUD operations ─────────────────

  function cloneBar(barConfig) {
    return JSON.parse(JSON.stringify(barConfig));
  }

  function replaceBarConfig(updatedBar) {
    if (!updatedBar || !updatedBar.id) return false;
    var next = [];
    var replaced = false;
    for (var i = 0; i < config.barConfigs.length; ++i) {
      if (config.barConfigs[i].id === updatedBar.id) {
        next.push(normalizeBarConfig(updatedBar, i));
        replaced = true;
      } else {
        next.push(config.barConfigs[i]);
      }
    }
    if (!replaced) return false;
    config.barConfigs = next;
    ensureSelectedBar();
    syncLegacyBarSettingsFromPrimary();
    return true;
  }

  // ── Conflict detection ─────────────────

  function barConflictDetails(barConfig) {
    if (!barConfig || !barConfig.enabled) return null;
    var screens = screensForBar(barConfig);
    for (var i = 0; i < screens.length; ++i) {
      var conflictBar = screenBarConflict(barConfig.id, barConfig.position, screens[i]);
      if (conflictBar) {
        return {
          type: "bar",
          screenName: screenName(screens[i]),
          barId: conflictBar.id,
          barName: conflictBar.name || "Bar"
        };
      }
    }
    return null;
  }

  function barConflictMessage(barConfig) {
    var details = barConflictDetails(barConfig);
    if (!details) return "";
    return (details.barName || "Another bar") + " already uses the " + barConfig.position + " edge on " + details.screenName + ".";
  }

  function addBar() {
    if ((config.barConfigs || []).length >= config.maxBars) return null;
    var next = (config.barConfigs || []).slice();
    var created = createBarConfig();
    if (barConflictDetails(created)) return null;
    next.push(normalizeBarConfig(created, next.length));
    config.barConfigs = next;
    config.selectedBarId = created.id;
    syncLegacyBarSettingsFromPrimary();
    return created.id;
  }

  function removeBar(barId) {
    if ((config.barConfigs || []).length <= 1) return false;
    var next = [];
    for (var i = 0; i < config.barConfigs.length; ++i) {
      if (config.barConfigs[i].id !== barId) next.push(config.barConfigs[i]);
    }
    if (next.length === config.barConfigs.length) return false;
    config.barConfigs = next;
    ensureSelectedBar();
    syncLegacyBarSettingsFromPrimary();
    return true;
  }

  function setSelectedBar(barId) {
    if (!barById(barId)) return false;
    config.selectedBarId = barId;
    return true;
  }

  function updateBarConfig(barId, patch) {
    var barConfig = barById(barId);
    if (!barConfig) return false;

    var updated = cloneBar(barConfig);
    var keys = Object.keys(patch || {});
    for (var i = 0; i < keys.length; ++i)
      updated[keys[i]] = patch[keys[i]];

    if (updated.displayMode !== "specific") updated.displayTargets = [];
    updated = normalizeBarConfig(updated, 0);
    if (barConflictDetails(updated)) return false;

    return replaceBarConfig(updated);
  }

  function updateBarDisplayTargets(barId, targets) {
    return updateBarConfig(barId, { displayTargets: Array.isArray(targets) ? targets.slice() : [] });
  }

  function updateBarSection(barId, section, widgets) {
    var barConfig = barById(barId);
    if (!barConfig || ["left", "center", "right"].indexOf(section) === -1) return false;

    var updated = cloneBar(barConfig);
    if (!updated.sectionWidgets) updated.sectionWidgets = { left: [], center: [], right: [] };

    updated.sectionWidgets[section] = [];
    var source = Array.isArray(widgets) ? widgets : [];
    for (var i = 0; i < source.length; ++i)
      updated.sectionWidgets[section].push(normalizeWidgetInstance(source[i]));

    return replaceBarConfig(updated);
  }

  function addBarWidget(barId, section, widgetType, initialSettings) {
    var barConfig = barById(barId);
    if (!barConfig || ["left", "center", "right"].indexOf(section) === -1) return null;
    var widgets = barSectionWidgets(barConfig, section).slice();
    var created = createWidgetInstance(widgetType, initialSettings);
    widgets.push(created);
    if (!updateBarSection(barId, section, widgets)) return null;
    return created.instanceId;
  }

  function removeBarWidget(barId, section, instanceId) {
    var barConfig = barById(barId);
    if (!barConfig) return false;
    var widgets = barSectionWidgets(barConfig, section).slice();
    var next = [];
    for (var i = 0; i < widgets.length; ++i) {
      if (widgets[i].instanceId !== instanceId) next.push(widgets[i]);
    }
    return updateBarSection(barId, section, next);
  }

  function updateBarWidget(barId, section, instanceId, patch) {
    var barConfig = barById(barId);
    if (!barConfig) return false;
    var widgets = barSectionWidgets(barConfig, section).slice();
    var updated = [];
    var found = false;

    for (var i = 0; i < widgets.length; ++i) {
      var current = normalizeWidgetInstance(widgets[i]);
      if (current.instanceId === instanceId) {
        var merged = JSON.parse(JSON.stringify(current));
        var keys = Object.keys(patch || {});
        for (var j = 0; j < keys.length; ++j)
          merged[keys[j]] = patch[keys[j]];
        if (patch && patch.settings)
          merged.settings = JSON.parse(JSON.stringify(patch.settings));
        updated.push(normalizeWidgetInstance(merged));
        found = true;
      } else {
        updated.push(current);
      }
    }

    if (!found) return false;
    return updateBarSection(barId, section, updated);
  }

  function moveBarWidget(barId, section, fromIndex, toIndex, targetSection) {
    var barConfig = barById(barId);
    if (!barConfig) return false;
    var destinationSection = targetSection || section;
    if (["left", "center", "right"].indexOf(section) === -1 || ["left", "center", "right"].indexOf(destinationSection) === -1)
      return false;

    var sourceWidgets = barSectionWidgets(barConfig, section).slice();
    if (fromIndex < 0 || fromIndex >= sourceWidgets.length) return false;

    if (section === destinationSection) {
      if (toIndex < 0 || toIndex >= sourceWidgets.length) return false;
      if (fromIndex === toIndex) return true;

      var sameSectionItem = sourceWidgets.splice(fromIndex, 1)[0];
      sourceWidgets.splice(toIndex, 0, sameSectionItem);
      return updateBarSection(barId, section, sourceWidgets);
    }

    var targetWidgets = barSectionWidgets(barConfig, destinationSection).slice();
    if (toIndex < 0 || toIndex > targetWidgets.length) return false;

    var movedItem = sourceWidgets.splice(fromIndex, 1)[0];
    targetWidgets.splice(toIndex, 0, movedItem);

    var updatedConfig = updateBarSection(barId, section, sourceWidgets);
    if (!updatedConfig) return false;
    return updateBarSection(barId, destinationSection, targetWidgets);
  }

  function widgetInstance(barId, section, instanceId) {
    var widgets = barSectionWidgets(barById(barId), section);
    for (var i = 0; i < widgets.length; ++i) {
      if (widgets[i].instanceId === instanceId) return widgets[i];
    }
    return null;
  }

  // ── Anchor / edge reservation ─────────────────

  function surfaceAnchorBar(barId, screen) {
    var barConfig = barById(barId);
    if (barConfig && barEnabledOnScreen(barConfig, screen)) return barConfig;

    var candidates = barsForScreen(screen);
    if (candidates.length > 0) return candidates[0];
    return selectedBar();
  }

  function screenBarConflict(barId, position, screen) {
    var bars = config.barConfigs || [];
    for (var i = 0; i < bars.length; ++i) {
      var barConfig = bars[i];
      if (!barConfig.enabled || barConfig.id === barId) continue;
      if (barConfig.position !== position) continue;
      if (barEnabledOnScreen(barConfig, screen)) return barConfig;
    }
    return null;
  }

  function barHasConflict(barConfig) {
    if (!barConfig || !barConfig.enabled) return false;
    var screens = screensForBar(barConfig);
    for (var i = 0; i < screens.length; ++i) {
      if (screenBarConflict(barConfig.id, barConfig.position, screens[i])) return true;
    }
    return false;
  }

  // ── Dock conflict detection ─────────────────

  function dockConflictsWithBar(barConfig) {
    if (!config.dockEnabled || !barConfig || !barConfig.enabled) return false;
    return barConfig.position === config.dockPosition;
  }

  function dockConflictScreens(positionOverride) {
    var screens = allScreens();
    var matches = [];
    for (var i = 0; i < screens.length; ++i) {
      if (dockConflictsOnScreen(screens[i], positionOverride))
        matches.push(screenName(screens[i]));
    }
    return matches;
  }

  function dockConflictMessage(positionOverride) {
    var screens = dockConflictScreens(positionOverride);
    if (screens.length === 0) return "";
    var edge = isValidEdge(positionOverride) ? positionOverride : config.dockPosition;
    return "The dock shares the " + edge + " edge with a bar on " + screens.join(", ") + ". It will stay hidden only on those displays.";
  }

  function barDockConflictScreens(barConfig) {
    if (!config.dockEnabled || !barConfig || !barConfig.enabled) return [];
    if (barConfig.position !== config.dockPosition) return [];
    var screens = screensForBar(barConfig);
    var matches = [];
    for (var i = 0; i < screens.length; ++i) {
      if (dockConflictsOnScreen(screens[i], barConfig.position))
        matches.push(screenName(screens[i]));
    }
    return matches;
  }

  function barDockConflictMessage(barConfig) {
    var screens = barDockConflictScreens(barConfig);
    if (screens.length === 0) return "";
    return "This bar shares the " + barConfig.position + " edge with the dock on " + screens.join(", ") + ". The dock will stay hidden on those displays.";
  }

  function dockConflictsOnScreen(screen, positionOverride) {
    if (!config.dockEnabled || !screen) return false;
    var edge = isValidEdge(positionOverride) ? positionOverride : config.dockPosition;
    var bars = config.barConfigs || [];
    for (var i = 0; i < bars.length; ++i) {
      var barConfig = bars[i];
      if (!barConfig.enabled) continue;
      if (barConfig.position !== edge) continue;
      if (barEnabledOnScreen(barConfig, screen)) return true;
    }
    return false;
  }

  function dockHasConflict() {
    if (!config.dockEnabled) return false;
    var screens = allScreens();
    for (var i = 0; i < screens.length; ++i) {
      if (dockConflictsOnScreen(screens[i])) return true;
    }
    return false;
  }

  function canUseDockPosition(position) {
    return isValidEdge(position);
  }

  function setDockPosition(position) {
    if (!isValidEdge(position)) return false;
    config.dockPosition = position;
    return true;
  }

  // ── Edge reservation for overlay positioning ──

  function reservedEdgesForScreen(screen, excludeBarId) {
    var reserved = {
      top: config.overlayInset,
      right: config.overlayInset,
      bottom: config.overlayInset,
      left: config.overlayInset
    };

    var bars = config.barConfigs || [];
    for (var i = 0; i < bars.length; ++i) {
      var barConfig = bars[i];
      if (!barConfig.enabled || barConfig.id === excludeBarId) continue;
      if (!barEnabledOnScreen(barConfig, screen)) continue;
      reserved[barConfig.position] += barThickness(barConfig) + floatingInset(barConfig) + config.popupGap;
    }

    if (config.dockEnabled && !dockConflictsOnScreen(screen))
      reserved[config.dockPosition] += config.dockIconSize + 32;

    return reserved;
  }

  function notificationMargins(screen) {
    var reserved = reservedEdgesForScreen(screen, "");
    return {
      top: reserved.top,
      right: reserved.right,
      bottom: reserved.bottom,
      left: reserved.left
    };
  }

  // ── Legacy bar compatibility ─────────────────

  function compatibleLegacyBar() {
    return selectedBar() || (config.barConfigs.length > 0 ? config.barConfigs[0] : null);
  }

  function syncLegacyBarSettingsFromPrimary() {
    var primaryBar = compatibleLegacyBar();
    if (!primaryBar) return;

    config._syncingLegacyBarSettings = true;
    config.barHeight = primaryBar.height;
    config.barFloating = primaryBar.floating;
    config.barMargin = primaryBar.margin;
    config.barOpacity = primaryBar.opacity;
    config._syncingLegacyBarSettings = false;
  }

  function applyLegacyBarSetting(key, value) {
    if (config._syncingLegacyBarSettings) return;
    var primaryBar = compatibleLegacyBar();
    if (!primaryBar) return;

    var patch = {};
    patch[key] = value;
    updateBarConfig(primaryBar.id, patch);
  }
}
