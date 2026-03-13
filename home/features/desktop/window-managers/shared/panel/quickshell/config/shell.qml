//@ pragma UseQApplication
import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import "bar"
import "launcher"
import "menu"
import "modules"
import "notifications"
import "services"
import "widgets"

Scope {
  id: root

  // Canonical UI state: only one closable surface is active at a time.
  property string activeSurfaceId: ""
  property var activeSurfaceContext: null
  readonly property var surfaceRegistry: ({
    notifCenter: { kind: "panel", focusPolicy: "focus-on-open", legacyFlags: ["notifCenterVisible"] },
    controlCenter: { kind: "panel", focusPolicy: "preserve-app-focus", legacyFlags: ["controlCenterVisible"] },
    networkMenu: { kind: "popup", focusPolicy: "preserve-app-focus", legacyFlags: ["networkMenuVisible"] },
    audioMenu: { kind: "popup", focusPolicy: "preserve-app-focus", legacyFlags: ["audioMenuVisible"] },
    powerMenu: { kind: "panel", focusPolicy: "focus-on-open", legacyFlags: ["powerMenuVisible"] },
    clipboardMenu: { kind: "popup", focusPolicy: "focus-on-open", legacyFlags: ["clipboardMenuVisible"] },
    recordingMenu: { kind: "popup", focusPolicy: "preserve-app-focus", legacyFlags: ["recordingMenuVisible"] },
    musicMenu: { kind: "popup", focusPolicy: "preserve-app-focus", legacyFlags: ["musicMenuVisible"] },
    batteryMenu: { kind: "popup", focusPolicy: "preserve-app-focus", legacyFlags: ["batteryMenuVisible"] },
    weatherMenu: { kind: "popup", focusPolicy: "preserve-app-focus", legacyFlags: ["weatherMenuVisible"] },
    dateTimeMenu: { kind: "popup", focusPolicy: "preserve-app-focus", legacyFlags: ["dateTimeMenuVisible"] },
    systemStatsMenu: { kind: "popup", focusPolicy: "preserve-app-focus", legacyFlags: ["systemStatsMenuVisible"] },
    bluetoothMenu: { kind: "popup", focusPolicy: "preserve-app-focus", legacyFlags: ["bluetoothMenuVisible"] },
    printerMenu: { kind: "popup", focusPolicy: "preserve-app-focus", legacyFlags: ["printerMenuVisible"] },
    privacyMenu: { kind: "popup", focusPolicy: "preserve-app-focus", legacyFlags: ["privacyMenuVisible"] },
    notepad: { kind: "panel", focusPolicy: "focus-on-open", legacyFlags: ["notepadVisible"] },
    colorPicker: { kind: "panel", focusPolicy: "focus-on-open", legacyFlags: ["colorPickerVisible"] },
    displayConfig: { kind: "panel", focusPolicy: "focus-on-open", legacyFlags: ["displayConfigVisible"] },
    fileBrowser: { kind: "panel", focusPolicy: "focus-on-open", legacyFlags: ["fileBrowserVisible"] },
    cavaPopup: { kind: "popup", focusPolicy: "preserve-app-focus", legacyFlags: ["cavaPopupVisible"] }
  })
  readonly property var knownSurfaces: Object.keys(surfaceRegistry)
  readonly property var legacyPanelToSurface: {
    var mapping = {};
    for (var surfaceId in root.surfaceRegistry) {
      var meta = root.surfaceRegistry[surfaceId];
      var flags = meta && meta.legacyFlags ? meta.legacyFlags : [];
      for (var i = 0; i < flags.length; ++i)
        mapping[flags[i]] = surfaceId;
    }
    return mapping;
  }
  property string closingSurfaceId: ""
  property var closingSurfaceContext: null
  property var closingMenuScreen: null
  property string pendingSurfaceId: ""
  property var pendingSurfaceContext: null
  readonly property int popupSwitchDelay: 170

  readonly property bool notifCenterVisible: root.isSurfaceOpen("notifCenter")
  readonly property bool controlCenterVisible: root.isSurfaceOpen("controlCenter")
  readonly property bool networkMenuVisible: root.isSurfaceOpen("networkMenu")
  readonly property bool audioMenuVisible: root.isSurfaceOpen("audioMenu")
  readonly property bool powerMenuVisible: root.isSurfaceOpen("powerMenu")
  readonly property bool clipboardMenuVisible: root.isSurfaceOpen("clipboardMenu")
  readonly property bool recordingMenuVisible: root.isSurfaceOpen("recordingMenu")
  readonly property bool musicMenuVisible: root.isSurfaceOpen("musicMenu")
  readonly property bool batteryMenuVisible: root.isSurfaceOpen("batteryMenu")
  readonly property bool weatherMenuVisible: root.isSurfaceOpen("weatherMenu")
  readonly property bool dateTimeMenuVisible: root.isSurfaceOpen("dateTimeMenu")
  readonly property bool systemStatsMenuVisible: root.isSurfaceOpen("systemStatsMenu")
  readonly property bool bluetoothMenuVisible: root.isSurfaceOpen("bluetoothMenu")
  readonly property bool printerMenuVisible: root.isSurfaceOpen("printerMenu")
  readonly property bool privacyMenuVisible: root.isSurfaceOpen("privacyMenu")
  readonly property bool notepadVisible: root.isSurfaceOpen("notepad")
  readonly property bool colorPickerVisible: root.isSurfaceOpen("colorPicker")
  readonly property bool displayConfigVisible: root.isSurfaceOpen("displayConfig")
  readonly property bool fileBrowserVisible: root.isSurfaceOpen("fileBrowser")
  readonly property bool cavaPopupVisible: root.isSurfaceOpen("cavaPopup")

  // Track which screen triggered the current menu (captured at toggle time)
  property var menuScreen: null
  readonly property var activeScreen: (Quickshell.screens && Quickshell.screens.length > 0) ? (Quickshell.cursorScreen || Quickshell.screens[0]) : null

  function currentSurfaceScreen() {
    if (root.activeSurfaceContext && root.activeSurfaceContext.screen)
      return root.activeSurfaceContext.screen;
    return root.menuScreen || root.activeScreen || Config.primaryScreen();
  }

  function normalizeSurfaceId(surfaceId) {
    if (!surfaceId) return "";
    if (knownSurfaces.indexOf(surfaceId) !== -1) return surfaceId;
    if (legacyPanelToSurface[surfaceId]) return legacyPanelToSurface[surfaceId];
    return "";
  }

  function isSurfaceOpen(surfaceId) {
    return root.activeSurfaceId === surfaceId;
  }

  function surfaceMeta(surfaceId) {
    var resolved = normalizeSurfaceId(surfaceId);
    return resolved ? root.surfaceRegistry[resolved] || null : null;
  }

  function surfaceKind(surfaceId) {
    var meta = surfaceMeta(surfaceId);
    return meta ? meta.kind : "";
  }

  function barOwnsSurface(context, screenRef, barId) {
    return !!(context && context.barId === barId && context.screen === screenRef);
  }

  function surfaceContextFor(surfaceId, screenRef, barId) {
    if (root.activeSurfaceId === surfaceId && root.barOwnsSurface(root.activeSurfaceContext, screenRef, barId))
      return root.activeSurfaceContext;
    if (root.closingSurfaceId === surfaceId && root.barOwnsSurface(root.closingSurfaceContext, screenRef, barId))
      return root.closingSurfaceContext;
    return null;
  }

  function isSurfacePresentedOnBar(surfaceId, screenRef, barId) {
    return root.activeSurfaceId === surfaceId && root.barOwnsSurface(root.activeSurfaceContext, screenRef, barId);
  }

  function clearClosingSurface() {
    root.closingSurfaceId = "";
    root.closingSurfaceContext = null;
    root.closingMenuScreen = null;
  }

  function clearPendingSurface() {
    root.pendingSurfaceId = "";
    root.pendingSurfaceContext = null;
  }

  function defaultSurfaceContext(surfaceId, preferredScreen) {
    var screen = preferredScreen || root.activeScreen || Config.primaryScreen();
    var barConfig = Config.surfaceAnchorBar(Config.selectedBarId, screen);
    var position = barConfig ? barConfig.position : "top";
    var thickness = Config.barThickness(barConfig);
    var triggerRect = { x: 16, y: 16, width: 28, height: 28 };

    if (screen) {
      if (position === "top" || position === "bottom") {
        triggerRect.x = Math.max(16, screen.width - 72);
        triggerRect.y = 4;
      } else {
        triggerRect.x = 4;
        triggerRect.y = Math.max(16, Math.round(screen.height * 0.25));
      }
      triggerRect.width = Math.max(28, thickness - 8);
      triggerRect.height = 28;
    }

    return {
      surfaceId: surfaceId,
      barId: barConfig ? barConfig.id : "",
      position: position,
      screen: screen,
      screenName: Config.screenName(screen),
      triggerRect: triggerRect
    };
  }

  function resolveSurfaceContext(surfaceId, context) {
    var resolved = context || {};
    if (!resolved.screen)
      resolved.screen = root.activeScreen || Config.primaryScreen();
    if (!resolved.screenName)
      resolved.screenName = Config.screenName(resolved.screen);
    if (!resolved.barId || !Config.barById(resolved.barId)) {
      var fallback = defaultSurfaceContext(surfaceId, resolved.screen);
      if (!resolved.barId) resolved.barId = fallback.barId;
      if (!resolved.position) resolved.position = fallback.position;
      if (!resolved.triggerRect) resolved.triggerRect = fallback.triggerRect;
    }
    if (!resolved.position) {
      var barConfig = Config.barById(resolved.barId);
      resolved.position = barConfig ? barConfig.position : "top";
    }
    if (!resolved.triggerRect)
      resolved.triggerRect = defaultSurfaceContext(surfaceId, resolved.screen).triggerRect;
    resolved.surfaceId = surfaceId;
    return resolved;
  }

  function commitSurfaceOpen(surfaceId, surfaceContext) {
    var resolvedContext = surfaceContext || resolveSurfaceContext(surfaceId, {});
    root.clearClosingSurface();
    root.activeSurfaceId = surfaceId;
    root.activeSurfaceContext = resolvedContext;
    root.menuScreen = resolvedContext.screen || root.activeScreen;
  }

  function beginPopupSwitch(surfaceId, surfaceContext) {
    root.pendingSurfaceId = surfaceId;
    root.pendingSurfaceContext = surfaceContext;
    root.closingSurfaceId = root.activeSurfaceId;
    root.closingSurfaceContext = root.activeSurfaceContext;
    root.closingMenuScreen = root.menuScreen;
    root.activeSurfaceId = "";
    root.activeSurfaceContext = null;
    root.menuScreen = null;
    popupSwitchTimer.restart();
  }

  function openSurface(surfaceId, context) {
    var resolved = normalizeSurfaceId(surfaceId);
    if (!resolved) return false;
    var surfaceContext = resolveSurfaceContext(resolved, context);

    if (root.pendingSurfaceId === resolved) {
      root.pendingSurfaceContext = surfaceContext;
      return true;
    }

    if (root.activeSurfaceId
      && root.activeSurfaceId !== resolved
      && root.surfaceKind(root.activeSurfaceId) === "popup"
      && root.surfaceKind(resolved) === "popup") {
      beginPopupSwitch(resolved, surfaceContext);
      return true;
    }

    popupSwitchTimer.stop();
    root.clearPendingSurface();
    root.clearClosingSurface();
    root.commitSurfaceOpen(resolved, surfaceContext);
    return true;
  }

  function closeSurface(surfaceId) {
    var resolved = normalizeSurfaceId(surfaceId);
    if (!resolved) return false;
    if (root.pendingSurfaceId === resolved)
      root.clearPendingSurface();
    if (root.activeSurfaceId !== resolved) return false;
    popupSwitchTimer.stop();
    root.clearClosingSurface();
    root.activeSurfaceId = "";
    root.activeSurfaceContext = null;
    root.menuScreen = null;
    return true;
  }

  function closeAllSurfaces() {
    popupSwitchTimer.stop();
    root.clearPendingSurface();
    root.clearClosingSurface();
    root.activeSurfaceId = "";
    root.activeSurfaceContext = null;
    root.menuScreen = null;
  }

  function toggleSurface(surfaceId, context) {
    var resolved = normalizeSurfaceId(surfaceId);
    if (!resolved) return false;
    if (root.activeSurfaceId === resolved) {
      closeAllSurfaces();
    } else {
      openSurface(resolved, context);
    }
    return true;
  }

  // Backward-compatibility helper for older callers.
  function togglePanel(panel) {
    return toggleSurface(panel);
  }

  function popupAnchorX(context, popupWidth, screenWidth) {
    var trigger = context && context.triggerRect ? context.triggerRect : { x: 16, y: 16, width: 28, height: 28 };
    var position = context && context.position ? context.position : "top";
    var minX = Config.overlayInset;
    var maxX = Math.max(minX, screenWidth - popupWidth - Config.overlayInset);
    var x = trigger.x;

    if (position === "top" || position === "bottom") {
      x = trigger.x + (trigger.width / 2) - (popupWidth / 2);
    } else if (position === "left")
      x = trigger.x + trigger.width + Config.popupGap;
    else
      x = trigger.x - popupWidth - Config.popupGap;

    return Math.min(Math.max(minX, x), maxX);
  }

  function popupAnchorY(context, popupHeight, screenHeight) {
    var trigger = context && context.triggerRect ? context.triggerRect : { x: 16, y: 16, width: 28, height: 28 };
    var position = context && context.position ? context.position : "top";
    var minY = Config.overlayInset;
    var maxY = Math.max(minY, screenHeight - popupHeight - Config.overlayInset);
    var y = trigger.y + trigger.height + Config.popupGap;

    if (position === "bottom")
      y = trigger.y - popupHeight - Config.popupGap;
    else if (position === "left" || position === "right") {
      y = trigger.y + (trigger.height / 2) - (popupHeight / 2);
    }

    return Math.min(Math.max(minY, y), maxY);
  }

  function popupMaxHeight(screenHeight) {
    if (screenHeight === undefined || screenHeight <= 0)
      return 560;
    return Math.max(320, screenHeight - 32);
  }

  Timer {
    id: popupSwitchTimer
    interval: root.popupSwitchDelay
    repeat: false
    onTriggered: {
      if (root.pendingSurfaceId) {
        var nextSurfaceId = root.pendingSurfaceId;
        var nextSurfaceContext = root.pendingSurfaceContext;
        root.clearPendingSurface();
        root.commitSurfaceOpen(nextSurfaceId, nextSurfaceContext);
      } else {
        root.clearClosingSurface();
      }
    }
  }

  function surfacePanelLayout(context, preferredWidth) {
    var resolvedContext = context || defaultSurfaceContext(root.activeSurfaceId, root.currentSurfaceScreen());
    var screen = resolvedContext.screen || root.activeScreen || Config.primaryScreen();
    var position = resolvedContext.position || "right";
    var reserved = Config.reservedEdgesForScreen(screen, "");
    var width = preferredWidth || Config.controlCenterWidth;
    var height = screen ? Math.max(360, Math.min(screen.height - reserved.top - reserved.bottom, Math.round(screen.height * 0.78))) : 640;
    var x = Config.overlayInset;

    if (screen) {
      if (position === "top" || position === "bottom") {
        x = resolvedContext.triggerRect
          ? resolvedContext.triggerRect.x + (resolvedContext.triggerRect.width / 2) - (width / 2)
          : Math.round((screen.width - width) / 2);
        x = Math.min(Math.max(reserved.left, x), Math.max(reserved.left, screen.width - reserved.right - width));
      }
    }

    return {
      edge: position,
      screen: screen,
      width: width,
      height: height,
      x: x,
      top: reserved.top,
      right: reserved.right,
      bottom: reserved.bottom,
      left: reserved.left
    };
  }

  function toggleNotifications() { toggleSurface("notifCenter"); }
  function toggleControls() { toggleSurface("controlCenter"); }
  function toggleNetworkMenu() { toggleSurface("networkMenu"); }
  function toggleAudioMenu() { toggleSurface("audioMenu"); }
  function toggleClipboardMenu() { toggleSurface("clipboardMenu"); }
  function toggleRecordingMenu() { toggleSurface("recordingMenu"); }
  function toggleMusicMenu() { toggleSurface("musicMenu"); }
  function toggleBatteryMenu() { toggleSurface("batteryMenu"); }
  function toggleWeatherMenu() { toggleSurface("weatherMenu"); }
  function toggleDateTimeMenu() { toggleSurface("dateTimeMenu"); }
  function toggleSystemStatsMenu() { toggleSurface("systemStatsMenu"); }
  function toggleBluetoothMenu() { toggleSurface("bluetoothMenu"); }
  function togglePrinterMenu() { toggleSurface("printerMenu"); }
  function togglePrivacyMenu() { toggleSurface("privacyMenu"); }
  function toggleNotepad() { toggleSurface("notepad"); }
  function toggleColorPicker() { toggleSurface("colorPicker"); }
  function toggleDisplayConfig() { toggleSurface("displayConfig"); }
  function toggleFileBrowser() { toggleSurface("fileBrowser"); }
  function toggleCavaPopup() { toggleSurface("cavaPopup"); }

  IpcHandler {
    target: "Shell"
    function toggleNotifications() { root.toggleNotifications(); }
    function toggleControls() { root.toggleControls(); }
    function toggleNetworkMenu() { root.toggleNetworkMenu(); }
    function toggleAudioMenu() { root.toggleAudioMenu(); }
    function toggleBluetoothMenu() { root.toggleBluetoothMenu(); }
    function togglePrinterMenu() { root.togglePrinterMenu(); }
    function togglePrivacyMenu() { root.togglePrivacyMenu(); }
    function toggleClipboardMenu() { root.toggleClipboardMenu(); }
    function toggleRecordingMenu() { root.toggleRecordingMenu(); }
    function toggleMusicMenu() { root.toggleMusicMenu(); }
    function toggleBatteryMenu() { root.toggleBatteryMenu(); }
    function toggleWeatherMenu() { root.toggleWeatherMenu(); }
    function toggleDateTimeMenu() { root.toggleDateTimeMenu(); }
    function toggleSystemStatsMenu() { root.toggleSystemStatsMenu(); }
    function toggleNotepad() { root.toggleNotepad(); }
    function toggleColorPicker() { root.toggleColorPicker(); }
    function toggleDisplayConfig() { root.toggleDisplayConfig(); }
    function toggleFileBrowser() { root.toggleFileBrowser(); }
    function toggleSurface(surfaceId: string) { root.toggleSurface(surfaceId); }
    function openSurface(surfaceId: string) { root.openSurface(surfaceId); }
    function closeAllSurfaces() { root.closeAllSurfaces(); }

    function closeAll() {
      root.closeAllSurfaces();
    }

    function togglePowermenu() {
      root.toggleSurface("powerMenu");
    }

    function reloadConfig() {
      Config.load();
    }
  }

  // Global shortcuts (outside Variants to avoid duplicate registration)
  Shortcut {
    sequence: "Meta+S"
    onActivated: settingsHub.toggle()
  }

  Shortcut {
    sequence: "Meta+C"
    onActivated: root.toggleControls()
  }

  Shortcut {
    sequence: "Meta+N"
    onActivated: root.toggleNotifications()
  }

  // Ensure ThemeService initializes early (loads manifest + applies saved theme)
  Component.onCompleted: { void ThemeService.activeThemeId; }

  NotificationManager {
    id: notifManager
  }

  // Per-screen bars + popup menus
  Variants {
    model: Quickshell.screens

    delegate: Component {
      Item {
        id: screenBars
        required property ShellScreen modelData
        property var bars: Config.barsForScreen(modelData)

        Variants {
          model: screenBars.bars

          delegate: Component {
            PanelWindow {
              id: barWindow
              required property var modelData
              readonly property var barConfig: modelData
              readonly property bool vertical: Config.isVerticalBar(barConfig.position)
              readonly property int marginValue: Config.floatingInset(barConfig)
              readonly property int thicknessValue: Config.barThickness(barConfig)
              screen: screenBars.modelData

              function surfaceContext(surfaceId) {
                return root.surfaceContextFor(surfaceId, screenBars.modelData, barConfig.id);
              }

              function popupVisible(surfaceId) {
                return root.isSurfacePresentedOnBar(surfaceId, screenBars.modelData, barConfig.id);
              }

              function popupPreferredEdge(surfaceId) {
                var context = surfaceContext(surfaceId);
                return context ? context.position : barConfig.position;
              }

              function popupAnchorXFor(surfaceId, popupWidth) {
                return root.popupAnchorX(surfaceContext(surfaceId), popupWidth, screen ? screen.width : width);
              }

              function popupAnchorYFor(surfaceId, popupHeight) {
                return root.popupAnchorY(surfaceContext(surfaceId), popupHeight, screen ? screen.height : height);
              }

              anchors {
                top: barConfig.position === "top" || barConfig.position === "left" || barConfig.position === "right"
                bottom: barConfig.position === "bottom" || barConfig.position === "left" || barConfig.position === "right"
                left: barConfig.position === "left" || ((barConfig.position === "top" || barConfig.position === "bottom") && barConfig.floating)
                right: barConfig.position === "right" || ((barConfig.position === "top" || barConfig.position === "bottom") && barConfig.floating)
              }
              margins {
                top: (barConfig.position === "top" || (vertical && barConfig.floating)) ? marginValue : 0
                bottom: (barConfig.position === "bottom" || (vertical && barConfig.floating)) ? marginValue : 0
                left: (barConfig.position === "left" || (!vertical && barConfig.floating)) ? marginValue : 0
                right: (barConfig.position === "right" || (!vertical && barConfig.floating)) ? marginValue : 0
              }

              color: "transparent"
              implicitWidth: vertical ? panel.implicitWidth : 0
              implicitHeight: vertical ? 0 : panel.implicitHeight

              WlrLayershell.layer: WlrLayer.Top
              WlrLayershell.namespace: "quickshell-bar-" + barConfig.id
              WlrLayershell.exclusiveZone: vertical ? width + marginValue : height + marginValue
              WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

              Panel {
                id: panel
                anchors.fill: parent
                manager: notifManager
                anchorWindow: barWindow
                screenRef: screenBars.modelData
                barConfig: barWindow.barConfig
                activeSurfaceId: root.barOwnsSurface(root.activeSurfaceContext, screenBars.modelData, barWindow.barConfig.id) ? root.activeSurfaceId : ""
                onSurfaceRequested: (surfaceId, context) => root.toggleSurface(surfaceId, context)
              }

              BluetoothMenu {
                anchor.window: barWindow
                preferredEdge: barWindow.popupPreferredEdge("bluetoothMenu")
                anchor.rect.x: barWindow.popupAnchorXFor("bluetoothMenu", width)
                anchor.rect.y: barWindow.popupAnchorYFor("bluetoothMenu", height)
                wantVisible: barWindow.popupVisible("bluetoothMenu")
                onCloseRequested: root.closeSurface("bluetoothMenu")
              }

              AudioMenu {
                anchor.window: barWindow
                preferredEdge: barWindow.popupPreferredEdge("audioMenu")
                anchor.rect.x: barWindow.popupAnchorXFor("audioMenu", width)
                anchor.rect.y: barWindow.popupAnchorYFor("audioMenu", height)
                wantVisible: barWindow.popupVisible("audioMenu")
                onCloseRequested: root.closeSurface("audioMenu")
              }

            NetworkMenu {
              anchor.window: barWindow
              preferredEdge: barWindow.popupPreferredEdge("networkMenu")
              anchor.rect.x: barWindow.popupAnchorXFor("networkMenu", width)
              anchor.rect.y: barWindow.popupAnchorYFor("networkMenu", height)
              wantVisible: barWindow.popupVisible("networkMenu")
              onCloseRequested: root.closeSurface("networkMenu")
            }

            ClipboardMenu {
              anchor.window: barWindow
              preferredEdge: barWindow.popupPreferredEdge("clipboardMenu")
              anchor.rect.x: barWindow.popupAnchorXFor("clipboardMenu", width)
              anchor.rect.y: barWindow.popupAnchorYFor("clipboardMenu", height)
              wantVisible: barWindow.popupVisible("clipboardMenu")
              onCloseRequested: root.closeSurface("clipboardMenu")
            }

            RecordingMenu {
              anchor.window: barWindow
              preferredEdge: barWindow.popupPreferredEdge("recordingMenu")
              anchor.rect.x: barWindow.popupAnchorXFor("recordingMenu", width)
              anchor.rect.y: barWindow.popupAnchorYFor("recordingMenu", height)
              wantVisible: barWindow.popupVisible("recordingMenu")
              onCloseRequested: root.closeSurface("recordingMenu")
            }

            PrivacyMenu {
              anchor.window: barWindow
              preferredEdge: barWindow.popupPreferredEdge("privacyMenu")
              anchor.rect.x: barWindow.popupAnchorXFor("privacyMenu", width)
              anchor.rect.y: barWindow.popupAnchorYFor("privacyMenu", height)
              wantVisible: barWindow.popupVisible("privacyMenu")
              onCloseRequested: root.closeSurface("privacyMenu")
            }

            MusicMenu {
              anchor.window: barWindow
              preferredEdge: barWindow.popupPreferredEdge("musicMenu")
              anchor.rect.x: barWindow.popupAnchorXFor("musicMenu", width)
              anchor.rect.y: barWindow.popupAnchorYFor("musicMenu", height)
              wantVisible: barWindow.popupVisible("musicMenu")
              onCloseRequested: root.closeSurface("musicMenu")
            }

            BatteryMenu {
              anchor.window: barWindow
              preferredEdge: barWindow.popupPreferredEdge("batteryMenu")
              anchor.rect.x: barWindow.popupAnchorXFor("batteryMenu", width)
              anchor.rect.y: barWindow.popupAnchorYFor("batteryMenu", height)
              wantVisible: barWindow.popupVisible("batteryMenu")
              onCloseRequested: root.closeSurface("batteryMenu")
            }

            WeatherMenu {
              anchor.window: barWindow
              preferredEdge: barWindow.popupPreferredEdge("weatherMenu")
              implicitHeight: Math.min(600, root.popupMaxHeight((barWindow.screen && barWindow.screen.height) ? barWindow.screen.height : barWindow.height))
              anchor.rect.x: barWindow.popupAnchorXFor("weatherMenu", width)
              anchor.rect.y: barWindow.popupAnchorYFor("weatherMenu", implicitHeight)
              wantVisible: barWindow.popupVisible("weatherMenu")
              onCloseRequested: root.closeSurface("weatherMenu")
            }

            DateTimeMenu {
              anchor.window: barWindow
              preferredEdge: barWindow.popupPreferredEdge("dateTimeMenu")
              implicitHeight: Math.min(560, root.popupMaxHeight((barWindow.screen && barWindow.screen.height) ? barWindow.screen.height : barWindow.height))
              anchor.rect.x: barWindow.popupAnchorXFor("dateTimeMenu", width)
              anchor.rect.y: barWindow.popupAnchorYFor("dateTimeMenu", implicitHeight)
              wantVisible: barWindow.popupVisible("dateTimeMenu")
              onCloseRequested: root.closeSurface("dateTimeMenu")
            }

            SystemStatsMenu {
              anchor.window: barWindow
              preferredEdge: barWindow.popupPreferredEdge("systemStatsMenu")
              anchor.rect.x: barWindow.popupAnchorXFor("systemStatsMenu", width)
              anchor.rect.y: barWindow.popupAnchorYFor("systemStatsMenu", height)
              wantVisible: barWindow.popupVisible("systemStatsMenu")
              onCloseRequested: root.closeSurface("systemStatsMenu")
            }

            PrinterMenu {
              anchor.window: barWindow
              preferredEdge: barWindow.popupPreferredEdge("printerMenu")
              anchor.rect.x: barWindow.popupAnchorXFor("printerMenu", width)
              anchor.rect.y: barWindow.popupAnchorYFor("printerMenu", height)
              wantVisible: barWindow.popupVisible("printerMenu")
              onCloseRequested: root.closeSurface("printerMenu")
            }

              CavaPopup {
                anchor.window: barWindow
                preferredEdge: barWindow.popupPreferredEdge("cavaPopup")
                anchor.rect.x: barWindow.popupAnchorXFor("cavaPopup", width)
                anchor.rect.y: barWindow.popupAnchorYFor("cavaPopup", height)
                wantVisible: barWindow.popupVisible("cavaPopup")
                cavaData: panel.fullCavaData
                onCloseRequested: root.closeSurface("cavaPopup")
              }
            }
          }
        }
      }
    }
  }

  Osd {
    id: osd
  }

  MediaOsd {
    id: mediaOsd
  }

  WorkspaceOsd {
    id: workspaceOsd
  }

  Loader {
    id: overview
    active: CompositorAdapter.supportsOverview
    source: "launcher/Overview.qml"
  }

  Dock {
    id: dock
  }

  Notifications {
    id: popups
    manager: notifManager
  }

  LazyLoader {
    active: root.notifCenterVisible
    NotificationCenter {
      id: center
      readonly property var layoutState: root.surfacePanelLayout(root.activeSurfaceContext, Config.controlCenterWidth)
      screen: layoutState.screen
      manager: notifManager
      showContent: root.notifCenterVisible
      surfaceEdge: layoutState.edge
      panelWidth: layoutState.width
      panelHeight: layoutState.height
      panelX: layoutState.x
      reservedTop: layoutState.top
      reservedRight: layoutState.right
      reservedBottom: layoutState.bottom
      reservedLeft: layoutState.left
      onCloseRequested: root.closeSurface("notifCenter")
    }
  }

  ControlCenter {
    id: controls
    readonly property var layoutState: root.surfacePanelLayout(root.activeSurfaceContext, Config.controlCenterWidth)
    screen: layoutState.screen
    manager: notifManager
    showContent: root.controlCenterVisible
    surfaceEdge: layoutState.edge
    panelWidth: layoutState.width
    panelHeight: layoutState.height
    panelX: layoutState.x
    reservedTop: layoutState.top
    reservedRight: layoutState.right
    reservedBottom: layoutState.bottom
    reservedLeft: layoutState.left
    onCloseRequested: root.closeSurface("controlCenter")
  }

  // --- File operation coordination ---
  // Tracks what triggered the FileBrowser so we can route fileSelected back
  property string _fileBrowserCaller: "" // "notepad-open", "notepad-save", "wallpaper", "wallpaper-folder"
  property string _pendingNotepadContent: "" // content to save for notepad-save
  property string _wallpaperMonitor: "" // monitor name for wallpaper browse
  property bool _reopenSettingsHubAfterFileBrowser: false

  function _openFileBrowserForNotepad(mode) {
    _reopenSettingsHubTimer.stop();
    _fileBrowserCaller = mode === "save" ? "notepad-save" : "notepad-open";
    root.openSurface("fileBrowser");
    // FileBrowser is now inside LazyLoader — need to defer open() call
    _fileBrowserOpenTimer.opMode = mode;
    _fileBrowserOpenTimer.restart();
  }

  Timer {
    id: _fileBrowserOpenTimer
    interval: 50
    property string opMode: "open"
    onTriggered: {
      if (fileBrowser) {
        var home = Quickshell.env("HOME") || "/home";
        var wallpaperDir = WallpaperService.normalizedWallpaperDir(Config.wallpaperDefaultFolder);
        if (opMode === "__wallpaper__") {
          fileBrowser.open(wallpaperDir, [{label: "Images", extensions: ["jpg","jpeg","png","webp","gif"]}], "open");
        } else if (opMode === "__wallpaper_folder__") {
          fileBrowser.open(wallpaperDir, [], "folder");
        } else if (opMode === "open") {
          fileBrowser.open(home, [{label: "Text Files", extensions: ["txt","md","json","qml","conf","log","nix","sh","toml","yaml","yml"]}], "open");
        } else {
          fileBrowser.open(home, [{label: "Text Files", extensions: ["txt","md"]}], "save");
        }
      }
    }
  }

  // Avoid reactivating SettingsHub in the same click cycle as modal close.
  Timer {
    id: _reopenSettingsHubTimer
    interval: 130
    repeat: false
    onTriggered: {
      if (root._reopenSettingsHubAfterFileBrowser && !root.fileBrowserVisible) {
        settingsHub.open();
        root._reopenSettingsHubAfterFileBrowser = false;
      }
    }
  }

  LazyLoader {
    active: root.notepadVisible
    Notepad {
      id: notepad
      screen: root.currentSurfaceScreen()
      showContent: root.notepadVisible
      onCloseRequested: root.closeSurface("notepad")
      onOpenFileRequested: root._openFileBrowserForNotepad("open")
      onSaveAsRequested: (content) => {
        root._pendingNotepadContent = content;
        root._openFileBrowserForNotepad("save");
      }
    }
  }

  LazyLoader {
    active: root.powerMenuVisible
    Powermenu {
      id: powermenu
      screen: root.currentSurfaceScreen()
      isVisible: root.powerMenuVisible
    }
  }

  Launcher {
    id: launcher
  }

  SettingsHub {
    id: settingsHub
    interactionBlocked: root.fileBrowserVisible
    onBrowseWallpaper: (monitorName) => {
      _reopenSettingsHubTimer.stop();
      root._fileBrowserCaller = "wallpaper";
      root._wallpaperMonitor = monitorName;
      root._reopenSettingsHubAfterFileBrowser = settingsHub.isOpen;
      if (settingsHub.isOpen) settingsHub.close();
      root.openSurface("fileBrowser");
      _fileBrowserOpenTimer.opMode = "__wallpaper__";
      _fileBrowserOpenTimer.restart();
    }
    onPickWallpaperFolder: {
      _reopenSettingsHubTimer.stop();
      root._fileBrowserCaller = "wallpaper-folder";
      root._reopenSettingsHubAfterFileBrowser = settingsHub.isOpen;
      if (settingsHub.isOpen) settingsHub.close();
      root.openSurface("fileBrowser");
      _fileBrowserOpenTimer.opMode = "__wallpaper_folder__";
      _fileBrowserOpenTimer.restart();
    }
  }

  LazyLoader {
    active: root.colorPickerVisible
    ColorPicker {
      id: colorPicker
      isOpen: root.colorPickerVisible
      onIsOpenChanged: if (!isOpen) root.closeSurface("colorPicker")
    }
  }

  LazyLoader {
    active: root.displayConfigVisible
    DisplayConfig {
      id: displayConfig
      isOpen: root.displayConfigVisible
      onIsOpenChanged: if (!isOpen) root.closeSurface("displayConfig")
    }
  }

  FileBrowser {
    id: fileBrowser
    isOpen: root.fileBrowserVisible
    onIsOpenChanged: {
      if (!isOpen) {
        root.closeSurface("fileBrowser");
        if (root._reopenSettingsHubAfterFileBrowser) {
          _reopenSettingsHubTimer.restart();
        }
      }
    }
    onFileSelected: (filePath) => {
      root.closeSurface("fileBrowser");
      if (root._fileBrowserCaller === "notepad-open") {
        // Re-open notepad if it was closed, then load file
        root.openSurface("notepad");
        // Defer until notepad is created by LazyLoader
        Qt.callLater(function() {
          if (notepad) notepad.loadFile(filePath);
        });
      } else if (root._fileBrowserCaller === "notepad-save") {
        root.openSurface("notepad");
        Qt.callLater(function() {
          if (notepad) notepad.saveToFile(filePath, root._pendingNotepadContent);
        });
      } else if (root._fileBrowserCaller === "wallpaper") {
        Quickshell.execDetached(["sh", "-c",
          "swww img '" + filePath.replace(/'/g, "'\\''") + "'" +
          (root._wallpaperMonitor ? " --outputs '" + root._wallpaperMonitor + "'" : "") +
          " --transition-type grow --transition-duration 1.5"
        ]);
      }
      root._fileBrowserCaller = "";
      root._pendingNotepadContent = "";
    }
    onFolderSelected: (folderPath) => {
      root.closeSurface("fileBrowser");
      if (root._fileBrowserCaller === "wallpaper-folder") {
        Config.wallpaperDefaultFolder = folderPath;
        WallpaperService.scanWallpapers();
      }
      root._fileBrowserCaller = "";
      root._pendingNotepadContent = "";
    }
  }

  NativeLock {
    id: lockscreen
  }

  // Per-screen desktop background + widgets
  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        required property ShellScreen modelData
        screen: modelData

        anchors {
          top: true
          left: true
          right: true
          bottom: true
        }
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        DesktopWidgets {
          id: desktopWidgets
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.leftMargin: 80
          anchors.topMargin: 120
        }
      }
    }
  }

  // Per-screen toast overlay
  Variants {
    model: Quickshell.screens

    delegate: Component {
      ToastOverlay {
        required property ShellScreen modelData
        screenModel: modelData
      }
    }
  }

  Corners {
    id: screenCorners
  }

  // Per-screen decorative border
  Variants {
    model: Quickshell.screens

    delegate: Component {
      ScreenBorder {
        required property ShellScreen modelData
        screen: modelData
        visible: Config.showScreenBorders
      }
    }
  }
}
