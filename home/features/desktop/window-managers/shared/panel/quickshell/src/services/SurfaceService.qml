import QtQuick
import Quickshell

QtObject {
    id: root

    property string activeSurfaceId: ""
    property var activeSurfaceContext: null
    readonly property var surfaceRegistry: ({
            notifCenter: {
                kind: "panel",
                focusPolicy: "focus-on-open",
                legacyFlags: ["notifCenterVisible"]
            },
            controlCenter: {
                kind: "panel",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["controlCenterVisible"]
            },
            networkMenu: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["networkMenuVisible"]
            },
            vpnMenu: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["vpnMenuVisible"]
            },
            audioMenu: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["audioMenuVisible"]
            },
            powerMenu: {
                kind: "panel",
                focusPolicy: "focus-on-open",
                legacyFlags: ["powerMenuVisible"]
            },
            clipboardMenu: {
                kind: "popup",
                focusPolicy: "focus-on-open",
                legacyFlags: ["clipboardMenuVisible"]
            },
            recordingMenu: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["recordingMenuVisible"]
            },
            musicMenu: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["musicMenuVisible"]
            },
            batteryMenu: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["batteryMenuVisible"]
            },
            weatherMenu: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["weatherMenuVisible"]
            },
            marketMenu: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["marketMenuVisible"]
            },
            modelUsageMenu: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["modelUsageMenuVisible"]
            },
            sshMenu: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["sshMenuVisible"]
            },
            dockerMenu: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["dockerMenuVisible"]
            },
            dateTimeMenu: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["dateTimeMenuVisible"]
            },
            systemStatsMenu: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["systemStatsMenuVisible"]
            },
            systemMonitor: {
                kind: "panel",
                focusPolicy: "focus-on-open",
                legacyFlags: ["systemMonitorVisible"]
            },
            bluetoothMenu: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["bluetoothMenuVisible"]
            },
            printerMenu: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["printerMenuVisible"]
            },
            privacyMenu: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["privacyMenuVisible"]
            },
            notepad: {
                kind: "panel",
                focusPolicy: "focus-on-open",
                legacyFlags: ["notepadVisible"]
            },
            colorPicker: {
                kind: "panel",
                focusPolicy: "focus-on-open",
                legacyFlags: ["colorPickerVisible"]
            },
            displayConfig: {
                kind: "panel",
                focusPolicy: "focus-on-open",
                legacyFlags: ["displayConfigVisible"]
            },
            fileBrowser: {
                kind: "panel",
                focusPolicy: "focus-on-open",
                legacyFlags: ["fileBrowserVisible"]
            },
            screenshotMenu: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["screenshotMenuVisible"]
            },
            cavaPopup: {
                kind: "popup",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["cavaPopupVisible"]
            },
            aiChat: {
                kind: "panel",
                focusPolicy: "focus-on-open",
                legacyFlags: ["aiChatVisible"]
            },
            commandPalette: {
                kind: "panel",
                focusPolicy: "focus-on-open"
            },
            osk: {
                kind: "panel",
                focusPolicy: "preserve-app-focus",
                legacyFlags: ["oskVisible"]
            }
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
    property var menuScreen: null
    readonly property var activeScreen: (Quickshell.screens && Quickshell.screens.length > 0) ? (Quickshell.cursorScreen || Quickshell.screens[0]) : null

    // Keep closing popup anchor context alive until the shared popup exit animation
    // has finished, otherwise the window can jump to the default inset mid-fade.
    readonly property int popupSwitchDelay: Appearance.durationNormal + 40

    function currentSurfaceScreen() {
        if (root.activeSurfaceContext && root.activeSurfaceContext.screen)
            return root.activeSurfaceContext.screen;
        return root.menuScreen || root.activeScreen || Config.primaryScreen();
    }

    function normalizeSurfaceId(surfaceId) {
        if (!surfaceId)
            return "";
        if (knownSurfaces.indexOf(surfaceId) !== -1)
            return surfaceId;
        if (legacyPanelToSurface[surfaceId])
            return legacyPanelToSurface[surfaceId];
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
        var triggerRect = {
            x: 16,
            y: 16,
            width: 28,
            height: 28
        };

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
        var resolved = context || ({});
        if (!resolved.screen)
            resolved.screen = root.activeScreen || Config.primaryScreen();
        if (!resolved.screenName)
            resolved.screenName = Config.screenName(resolved.screen);
        if (!resolved.barId || !Config.barById(resolved.barId)) {
            var fallback = defaultSurfaceContext(surfaceId, resolved.screen);
            if (!resolved.barId)
                resolved.barId = fallback.barId;
            if (!resolved.position)
                resolved.position = fallback.position;
            if (!resolved.triggerRect)
                resolved.triggerRect = fallback.triggerRect;
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

    function beginPopupClose(surfaceId, surfaceContext) {
        root.closingSurfaceId = surfaceId;
        root.closingSurfaceContext = surfaceContext;
        root.closingMenuScreen = root.menuScreen;
        root.activeSurfaceId = "";
        root.activeSurfaceContext = null;
        root.menuScreen = null;
        popupSwitchTimer.restart();
    }

    function openSurface(surfaceId, context) {
        var resolved = normalizeSurfaceId(surfaceId);
        if (!resolved)
            return false;
        var surfaceContext = resolveSurfaceContext(resolved, context);

        if (root.pendingSurfaceId === resolved) {
            root.pendingSurfaceContext = surfaceContext;
            return true;
        }

        if (root.activeSurfaceId && root.activeSurfaceId !== resolved && root.surfaceKind(root.activeSurfaceId) === "popup" && root.surfaceKind(resolved) === "popup") {
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
        if (!resolved)
            return false;
        if (root.pendingSurfaceId === resolved)
            root.clearPendingSurface();
        if (root.activeSurfaceId !== resolved)
            return false;
        popupSwitchTimer.stop();
        if (root.surfaceKind(resolved) === "popup")
            root.beginPopupClose(resolved, root.activeSurfaceContext);
        else {
            root.clearClosingSurface();
            root.activeSurfaceId = "";
            root.activeSurfaceContext = null;
            root.menuScreen = null;
        }
        return true;
    }

    function closeAllSurfaces() {
        popupSwitchTimer.stop();
        root.clearPendingSurface();
        if (root.activeSurfaceId && root.surfaceKind(root.activeSurfaceId) === "popup")
            root.beginPopupClose(root.activeSurfaceId, root.activeSurfaceContext);
        else {
            root.clearClosingSurface();
            root.activeSurfaceId = "";
            root.activeSurfaceContext = null;
            root.menuScreen = null;
        }
    }

    function toggleSurface(surfaceId, context) {
        var resolved = normalizeSurfaceId(surfaceId);
        if (!resolved)
            return false;
        if (root.activeSurfaceId === resolved)
            closeAllSurfaces();
        else
            openSurface(resolved, context);
        return true;
    }

    function popupAnchorX(context, popupWidth, screenWidth) {
        var trigger = context && context.triggerRect ? context.triggerRect : {
            x: 16,
            y: 16,
            width: 28,
            height: 28
        };
        var position = context && context.position ? context.position : "top";
        var minX = Config.overlayInset;
        var maxX = Math.max(minX, screenWidth - popupWidth - Config.overlayInset);
        var x = trigger.x;

        if (position === "top" || position === "bottom")
            x = trigger.x + (trigger.width / 2) - (popupWidth / 2);
        else if (position === "left")
            x = trigger.x + trigger.width + Config.popupGap;
        else
            x = trigger.x - popupWidth - Config.popupGap;

        return Math.min(Math.max(minX, x), maxX);
    }

    function popupAnchorY(context, popupHeight, screenHeight) {
        var trigger = context && context.triggerRect ? context.triggerRect : {
            x: 16,
            y: 16,
            width: 28,
            height: 28
        };
        var position = context && context.position ? context.position : "top";
        var minY = Config.overlayInset;
        var maxY = Math.max(minY, screenHeight - popupHeight - Config.overlayInset);
        var y = trigger.y + trigger.height + Config.popupGap;

        if (position === "bottom")
            y = trigger.y - popupHeight - Config.popupGap;
        else if (position === "left" || position === "right")
            y = trigger.y + (trigger.height / 2) - (popupHeight / 2);

        return Math.min(Math.max(minY, y), maxY);
    }

    function popupMaxHeight(screenHeight) {
        if (screenHeight === undefined || screenHeight <= 0)
            return 560;
        return Math.max(320, screenHeight - 32);
    }

    function surfacePanelLayout(context, preferredWidth) {
        var resolvedContext = context || defaultSurfaceContext(root.activeSurfaceId, root.currentSurfaceScreen());
        var screen = resolvedContext.screen || root.activeScreen || Config.primaryScreen();
        var position = resolvedContext.position || "right";
        var reserved = Config.reservedEdgesForScreen(screen, "");
        var width = preferredWidth || Config.controlCenterWidth;
        // PanelWindow uses implicitWidth panelWidth+20 and margins.right = reserved.right + spacingS;
        // keep the layer surface within the output so the right edge (radius, content) is not clipped.
        if (screen && screen.width > 0) {
            var panelSlack = 28;
            var maxPanel = screen.width - reserved.left - reserved.right - panelSlack;
            if (maxPanel > 0)
                width = Math.min(width, maxPanel);
        }
        var height = screen ? Math.max(360, Math.min(screen.height - reserved.top - reserved.bottom, Math.round(screen.height * 0.78))) : 640;
        var x = Config.overlayInset;

        if (screen && (position === "top" || position === "bottom")) {
            x = resolvedContext.triggerRect ? resolvedContext.triggerRect.x + (resolvedContext.triggerRect.width / 2) - (width / 2) : Math.round((screen.width - width) / 2);
            x = Math.min(Math.max(reserved.left, x), Math.max(reserved.left, screen.width - reserved.right - width));
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

    property Timer popupSwitchTimer: Timer {
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

    onActiveSurfaceIdChanged: {
        if (!Config.pauseAutoSave && Config.activeSurfaceId !== activeSurfaceId) {
            Config.activeSurfaceId = activeSurfaceId;
        }
    }

    Component.onCompleted: {
        // Delay recovery slightly to ensure all shell components are ready
        recoveryTimer.restart();
    }

    property Timer recoveryTimer: Timer {
        interval: 350
        onTriggered: {
            if (Config.activeSurfaceId && root.surfaceKind(Config.activeSurfaceId) !== "popup") {
                root.openSurface(Config.activeSurfaceId);
            }
        }
    }
}
