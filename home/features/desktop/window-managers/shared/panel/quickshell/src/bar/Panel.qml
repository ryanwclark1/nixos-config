import QtQuick
import Quickshell
import "."
import "widgets"
import "../features/system/sections"
import "../services"
import "../widgets" as SharedWidgets
import "PanelWidgetHelpers.js" as PanelHelpers
import "components"

Item {
    id: root

    SharedWidgets.SurfaceGradient {
        id: barGradient
    }

    // Widgets/menus hold Refs for Recording, Privacy, Printer, Media, Weather, Market.
    // Keep SystemStatus here so minimal bars (no logo/stat pills) still get stats + isCritical.
    SharedWidgets.ServiceRefList {
        services: [SystemStatus]
    }

    property var manager: null
    property var anchorWindow: null
    property var screenRef: null
    property var barConfig: null
    property string activeSurfaceId: ""
    property var activeSurfaceContext: null

    readonly property string position: (barConfig && barConfig.position) || "top"
    readonly property bool vertical: Config.isVerticalBar(position)
    readonly property int thickness: Config.barThickness(barConfig)
    readonly property var sectionWidgets: (barConfig && barConfig.sectionWidgets) || ({
            left: [],
            center: [],
            right: []
        })
    readonly property int outerPadding: Appearance.spacingM
    readonly property int sectionSpacing: Appearance.spacingS
    readonly property int runtimeSpacing: Appearance.spacingM
    readonly property int verticalItemWidthCap: vertical ? Math.max(24, thickness) : 0
    readonly property int verticalBarWidthCap: vertical ? (verticalItemWidthCap + outerPadding * 2) : 0
    readonly property real centerTargetOffset: 0
    readonly property real centerMinOffset: outerPadding + leftSection.width + (leftSection.width > 0 ? runtimeSpacing : 0) - width / 2 + centerSection.width / 2
    readonly property real centerMaxOffset: width / 2 - outerPadding - rightSection.width - (rightSection.width > 0 ? runtimeSpacing : 0) - centerSection.width / 2
    readonly property real centerClampedOffset: centerMinOffset > centerMaxOffset ? 0 : Math.max(centerMinOffset, Math.min(centerTargetOffset, centerMaxOffset))
    readonly property real computedOpacity: (barConfig && barConfig.opacity !== undefined) ? barConfig.opacity : Config.barOpacity
    readonly property bool floatingBar: barConfig && barConfig.floating !== undefined ? !!barConfig.floating : Config.barFloating
    readonly property bool autoHide: !!(barConfig && barConfig.autoHide)
    readonly property int autoHideDelay: (barConfig && barConfig.autoHideDelay) || 300
    readonly property bool noBackground: !!(barConfig && barConfig.noBackground)
    readonly property bool maximizeDetect: !!(barConfig && barConfig.maximizeDetect)
    readonly property string scrollBehavior: (barConfig && barConfig.scrollBehavior) || "none"
    readonly property bool shadowEnabled: !!(barConfig && barConfig.shadowEnabled)
    readonly property real shadowOpacity: (barConfig && barConfig.shadowOpacity !== undefined) ? barConfig.shadowOpacity : 0.3
    readonly property real barFontScale: (barConfig && barConfig.fontScale !== undefined) ? barConfig.fontScale : 1.0
    readonly property real barIconScale: (barConfig && barConfig.iconScale !== undefined) ? barConfig.iconScale : 1.0
    property bool _autoHidden: false
    property bool _hovered: false
    property var _widgetDiagnosticStates: ({})
    property var _barInactiveLogged: ({})
    property bool diagnosticsReady: false
    // Expose to shell.qml for exclusiveZone control
    readonly property bool isAutoHidden: _autoHidden
    signal surfaceRequested(string surfaceId, var context)
    signal contextMenuRequested(var actions, var triggerRect)

    implicitHeight: vertical ? 0 : thickness
    implicitWidth: vertical ? verticalBarWidthCap : 0

    function resetDiagnosticWarmup() {
        diagnosticsReady = false;
        _barInactiveLogged = ({});
        diagnosticWarmupTimer.restart();
    }

    function sectionItems(section) {
        if (Config.barUseModularEntries) {
            var entries = [];
            if (section === "left") entries = Config.barLeftEntries;
            else if (section === "center") entries = Config.barCenterEntries;
            else if (section === "right") entries = Config.barRightEntries;

            return entries.map(function(type, idx) {
                return { 
                    widgetType: type, 
                    enabled: true,
                    section: section,
                    index: idx,
                    isModular: true
                };
            });
        }
        var items = sectionWidgets && sectionWidgets[section] ? sectionWidgets[section] : [];
        return items;
    }

    function isLauncherWidget(widgetInstance) {
        return !!widgetInstance && String(widgetInstance.widgetType || "") === "logo";
    }

    function leadingLauncherItems(section) {
        var items = sectionItems(section);
        if (items.length > 0 && isLauncherWidget(items[0]))
            return [items[0]];
        return [];
    }

    function trailingSectionItems(section) {
        var items = sectionItems(section);
        if (items.length > 0 && isLauncherWidget(items[0]))
            return items.slice(1);
        return items;
    }

    // Cached section arrays — computed once per sectionWidgets change instead of 10× per layout pass
    readonly property var _leftLeading: leadingLauncherItems("left")
    readonly property var _leftTrailing: trailingSectionItems("left")
    readonly property var _centerItems: sectionItems("center")
    readonly property var _rightItems: sectionItems("right")

    function widgetSettings(wi) { return PanelHelpers.widgetSettings(wi); }
    function widgetDiagnosticId(wi) { return PanelHelpers.widgetDiagnosticId(wi, root.barConfig); }
    function itemLayoutFootprint(item) { return PanelHelpers.itemLayoutFootprint(item, root.vertical); }
    function itemOccupiesSpace(item) { return PanelHelpers.itemOccupiesSpace(item, root.vertical); }
    function isWidgetHiddenInVertical(wi) { return PanelHelpers.isWidgetHiddenInVertical(wi); }
    function shouldCollapseVerticalOverflow(wi) { return PanelHelpers.shouldCollapseVerticalOverflow(wi); }

    function inactiveBarWidgetReason(widgetInstance, hiddenInVertical) {
        if (!widgetInstance)
            return "missing widget instance";
        if (hiddenInVertical)
            return "hidden on vertical bar (widget policy)";
        if (widgetInstance.enabled === false)
            return "disabled in bar layout — enable in Settings -> Bar or set enabled: true in config";
        return "";
    }

    function maybeLogBarWidgetInactive(widgetId, widgetInstance, hiddenInVertical) {
        if (!Config.barWidgetLoadLogging)
            return;
        var reason = inactiveBarWidgetReason(widgetInstance, hiddenInVertical);
        if (!reason)
            return;
        var prev = _barInactiveLogged[widgetId];
        if (prev === reason)
            return;
        _barInactiveLogged[widgetId] = reason;
        var wtype = widgetInstance ? String(widgetInstance.widgetType || "") : "";
        var barId = barConfig ? barConfig.id : "";
        Logger.i("Panel", "bar widget inactive:", widgetId, "type=" + wtype, "bar=" + barId, reason);
    }

    function reportWidgetDiagnostic(widgetId, state, details) {
        var previous = _widgetDiagnosticStates[widgetId] || "";
        if (previous === state)
            return;

        if (state === "ok" || state === "inactive" || state === "pending") {
            _widgetDiagnosticStates[widgetId] = state;
            return;
        }

        _widgetDiagnosticStates[widgetId] = state;
        if (Config.barWidgetLoadLogging)
            Logger.w("Panel", "widget state warning:", widgetId, "state=" + state, details || "");
    }

    onBarConfigChanged: resetDiagnosticWarmup()
    onSectionWidgetsChanged: resetDiagnosticWarmup()
    Component.onCompleted: {
        resetDiagnosticWarmup();
        var panelPerfDone = Logger.perf("Panel", "firstFrameAfterMount");
        Qt.callLater(panelPerfDone);
    }

    Timer {
        id: diagnosticWarmupTimer
        readonly property int _diagnosticWarmupMs: 1200
        interval: _diagnosticWarmupMs
        repeat: false
        onTriggered: root.diagnosticsReady = true
    }

    function requestSurface(surfaceId, item, extraContext) {
        if (!item)
            return;
        var topLeft = item.mapToItem(root, 0, 0);
        var context = {
            surfaceId: surfaceId,
            barId: barConfig ? barConfig.id : "",
            position: position,
            screen: screenRef,
            screenName: Config.screenName(screenRef),
            triggerRect: {
                x: topLeft.x,
                y: topLeft.y,
                width: item.width,
                height: item.height
            }
        };
        if (extraContext) {
            for (var key in extraContext)
                context[key] = extraContext[key];
        }
        root.surfaceRequested(surfaceId, context);
    }

    function isSurfaceActive(surfaceId, extraKey, extraValue) {
        if (root.activeSurfaceId !== surfaceId)
            return false;
        if (extraKey === undefined)
            return true;
        return !!(root.activeSurfaceContext && root.activeSurfaceContext[extraKey] === extraValue);
    }

    function statDisplayText(widgetType, wi) { return PanelHelpers.statDisplayText(widgetType, wi, SystemStatus); }
    function compactStatDisplayText(widgetType, wi) { return PanelHelpers.compactStatDisplayText(widgetType, wi, SystemStatus); }
    function statTooltipText(widgetType, wi) { return PanelHelpers.statTooltipText(widgetType, wi, SystemStatus); }
    function isCompactStatWidget(wi) { return PanelHelpers.isCompactStatWidget(wi, root.vertical); }
    function isIconOnlyStatWidget(wi) { return PanelHelpers.isIconOnlyStatWidget(wi, root.vertical); }
    function isSummaryWidgetIconOnly(wi) { return PanelHelpers.isSummaryWidgetIconOnly(wi, root.vertical); }
    function widgetIntegerSetting(wi, key, fallback, minValue, maxValue) { return PanelHelpers.widgetIntegerSetting(wi, key, fallback, minValue, maxValue); }
    function widgetBooleanSetting(wi, key, fallback) { return PanelHelpers.widgetBooleanSetting(wi, key, fallback); }
    function effectiveKeyboardLabelMode(wi) { return PanelHelpers.effectiveKeyboardLabelMode(wi, root.vertical); }
    function triggerWidgetIconOnly(wi) { return PanelHelpers.triggerWidgetIconOnly(wi, root.vertical); }
    function triggerWidgetLabel(wi, fallback) { return PanelHelpers.triggerWidgetLabel(wi, fallback); }

    readonly property var _widgetComponents: ({
        "logo": logoComponent,
        "workspaces": workspacesComponent,
        "specialWorkspaces": specialWorkspacesComponent,
        "taskbar": taskbarComponent,
        "windowTitle": windowTitleComponent,
        "keyboardLayout": keyboardLayoutComponent,
        "cpuStatus": cpuStatusComponent,
        "ramStatus": ramStatusComponent,
        "gpuStatus": gpuStatusComponent,
        "diskStatus": diskStatusComponent,
        "networkStatus": networkStatusComponent,
        "systemMonitor": legacySystemMonitorComponent,
        "dateTime": dateTimeComponent,
        "mediaBar": mediaBarComponent,
        "updates": updatesComponent,
        "cava": cavaComponent,
        "idleInhibitor": idleInhibitorComponent,
        "modelUsage": modelUsageComponent,
        "weather": weatherComponent,
        "market": marketComponent,
        "ssh": sshComponent,
        "vpn": vpnComponent,
        "network": networkComponent,
        "bluetooth": bluetoothComponent,
        "audio": audioComponent,
        "music": musicComponent,
        "privacy": privacyComponent,
        "voxtype": voxtypeComponent,
        "recording": recordingComponent,
        "battery": batteryComponent,
        "printer": printerComponent,
        "aiChat": aiChatPillComponent,
        "notepad": notepadComponent,
        "controlCenter": controlCenterComponent,
        "tray": trayComponent,
        "clipboard": clipboardComponent,
        "screenshot": screenshotComponent,
        "notifications": notificationsComponent,
        "personality": personalityComponent,
        "pomodoro": pomodoroComponent,
        "todo": todoComponent,
        "gameMode": gameModeComponent,
        "nightLight": nightLightComponent,
        "spacer": spacerComponent,
        "separator": separatorComponent
    })

    function componentForWidget(widgetType) {
        var type = String(widgetType || "");
        if (type.indexOf("plugin:") === 0)
            return pluginComponent;
        return _widgetComponents[type] || unknownComponent;
    }

    PanelBarInteractionLayer {
        anchors.fill: parent
        panel: root
    }

    // Auto-hide: slide bar off-screen and fade out
    property real _slideOffset: root._autoHidden ? (root.position === "bottom" ? root.thickness : -root.thickness) : 0

    Behavior on _slideOffset {
        NumberAnimation {
            duration: Appearance.durationFast
            easing.type: Easing.InOutQuad
        }
    }

    opacity: root._autoHidden ? 0 : 1
    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.durationFast
            easing.type: Easing.InOutQuad
        }
    }

    transform: Translate {
        y: root._slideOffset
    }

    PanelShadowLayer {
        anchors.fill: parent
        shadowEnabled: root.shadowEnabled
        autoHidden: root._autoHidden
        floatingBar: root.floatingBar
        shadowOpacity: root.shadowOpacity
    }

    // ── Background ────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: root.noBackground ? "transparent" : Colors.bgGlass
        radius: root.floatingBar ? Appearance.radiusMedium : 0
        clip: true

        gradient: (root.floatingBar && !root.noBackground) ? barGradient : null

        border.color: (root.floatingBar && !root.noBackground) ? Colors.border : "transparent"
        border.width: (root.floatingBar && !root.noBackground) ? 1 : 0

        // If not floating, add a subtle border on the edge
        Rectangle {
            visible: !root.floatingBar && !root.noBackground
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: root.position === "top" ? parent.bottom : undefined
            anchors.top: root.position === "bottom" ? parent.top : undefined
            height: 1
            color: Colors.border
        }

        // Inner subtle highlight border
        SharedWidgets.InnerHighlight {
            highlightOpacity: 0.12
            visible: !root.noBackground
        }

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: {
                if (!Config.barUseModularEntries) return;

                var availableWidgets = [
                    { label: "Logo/Launcher", type: "logo", icon: "app-generic.svg" },
                    { label: "Workspaces", type: "workspaces", icon: "color-palette.svg" },
                    { label: "Window Title", type: "windowTitle", icon: "options.svg" },
                    { label: "Clock/Date", type: "dateTime", icon: "clock.svg" },
                    { label: "Media Bar", type: "mediaBar", icon: "music-note-2.svg" },
                    { label: "System Tray", type: "tray", icon: "settings.svg" },
                    { label: "Notifications", type: "notifications", icon: "alert.svg" },
                    { label: "Audio", type: "audio", icon: "speaker.svg" },
                    { label: "Network", type: "network", icon: "ethernet.svg" },
                    { label: "Battery", type: "battery", icon: "battery-full.svg" },
                    { label: "Personality", type: "personality", icon: "people.svg" },
                    { label: "Spacer", type: "spacer", icon: "subtract.svg" },
                    { label: "Separator", type: "separator", icon: "subtract.svg" }
                ];

                function makeSectionMenu(section) {
                    return availableWidgets.map(function(w) {
                        return {
                            label: w.label,
                            icon: w.icon,
                            action: function() { 
                                Config.addModularEntry(section, w.type); 
                                ToastService.showNoticeAction("Widget added", "Added " + w.label, "Undo", () => Config.undoModularChange());
                            }
                        };
                    });
                }

                var actions = [
                    {
                        label: "Add Widget to Left",
                        icon: "arrow-left.svg",
                        children: makeSectionMenu("left")
                    },
                    {
                        label: "Add Widget to Center",
                        icon: "arrow-sync.svg",
                        children: makeSectionMenu("center")
                    },
                    {
                        label: "Add Widget to Right",
                        icon: "arrow-right.svg",
                        children: makeSectionMenu("right")
                    },
                    { separator: true },
                    {
                        label: "Open Settings",
                        icon: "settings.svg",
                        action: function() { root.requestSurface("controlCenter", null); }
                    }
                ];

                root.contextMenuRequested(actions, {
                    x: point.position.x,
                    y: point.position.y,
                    width: 1,
                    height: 1
                });
            }
        }
    }

    BarSectionRepeater {
        id: leftSection
        vertical: root.vertical
        sectionSpacing: runtimeSpacing + root.sectionSpacing
        sectionModel: root._leftLeading
        trailingModel: root._leftTrailing
        trailingSpacing: runtimeSpacing
        sectionDelegate: widgetLoaderDelegate
        anchors.left: !root.vertical ? parent.left : undefined
        anchors.leftMargin: !root.vertical ? outerPadding : 0
        anchors.verticalCenter: !root.vertical ? parent.verticalCenter : undefined
        anchors.top: root.vertical ? parent.top : undefined
        anchors.topMargin: root.vertical ? outerPadding : 0
        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
    }

    Loader {
        id: criticalStatusLoader
        active: SystemStatus.isCritical
        visible: SystemStatus.isCritical && !root.vertical
        height: root.thickness
        width: item ? item.implicitWidth : 0
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: leftSection.right
        anchors.leftMargin: root.runtimeSpacing
        z: 20
        sourceComponent: criticalAlertComponent
    }

    BarSectionRepeater {
        id: centerSection
        vertical: root.vertical
        sectionSpacing: runtimeSpacing
        sectionModel: root._centerItems
        sectionDelegate: widgetLoaderDelegate
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: root.vertical ? 0 : root.centerClampedOffset
        anchors.verticalCenter: parent.verticalCenter
    }

    BarSectionRepeater {
        id: rightSection
        vertical: root.vertical
        sectionSpacing: runtimeSpacing
        sectionModel: root._rightItems
        sectionDelegate: widgetLoaderDelegate
        anchors.right: !root.vertical ? parent.right : undefined
        anchors.rightMargin: !root.vertical ? outerPadding : 0
        anchors.verticalCenter: !root.vertical ? parent.verticalCenter : undefined
        anchors.bottom: root.vertical ? parent.bottom : undefined
        anchors.bottomMargin: root.vertical ? outerPadding : 0
        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
    }

    Component {
        id: widgetLoaderDelegate
        Item {
            id: diagnosticWrapper
            required property var modelData
            property var widgetInstance: modelData
            property string deferredDiagnosticState: ""
            property string deferredDiagnosticDetail: ""
            property bool stuckPendingReported: false
            readonly property bool occupiesSpace: root.itemOccupiesSpace(widgetLoader.item)
            readonly property bool diagnosticsReady: root.diagnosticsReady
            readonly property bool hiddenInVertical: root.vertical && root.isWidgetHiddenInVertical(widgetInstance)
            readonly property real rawWidgetWidth: {
                var raw = widgetLoader.item ? (widgetLoader.item.implicitWidth || widgetLoader.item.width || 0) : 0;
                raw = Number(raw);
                return isNaN(raw) ? 0 : raw;
            }
            readonly property real rawWidgetHeight: {
                var raw = widgetLoader.item ? (widgetLoader.item.implicitHeight || widgetLoader.item.height || 0) : 0;
                raw = Number(raw);
                return isNaN(raw) ? 0 : raw;
            }
            readonly property bool collapseForVerticalOverflow: root.vertical
                && root.shouldCollapseVerticalOverflow(widgetInstance)
                && widgetLoader.item
                && widgetLoader.item.visible !== false
                && rawWidgetWidth > root.verticalItemWidthCap
            readonly property bool contributesLayout: occupiesSpace && !collapseForVerticalOverflow
            readonly property bool widgetEnabled: !!widgetInstance
                && widgetInstance.enabled !== false
                && !hiddenInVertical
            readonly property string widgetId: root.widgetDiagnosticId(widgetInstance)
            readonly property string diagnosticState: {
                if (!widgetEnabled)
                    return "inactive";
                if (widgetLoader.status === Loader.Error)
                    return "load-error";
                if (widgetLoader.active && !widgetLoader.item)
                    return "pending";
                if (!widgetLoader.item)
                    return "inactive";
                if (widgetLoader.item.visible === false)
                    return "ok";
                if (collapseForVerticalOverflow)
                    return "vertical-overflow";
                if (!occupiesSpace)
                    return "zero-footprint";
                return "ok";
            }
            clip: root.vertical
            implicitWidth: contributesLayout ? (root.vertical ? Math.min(root.verticalItemWidthCap, Math.max(root.thickness, rawWidgetWidth)) : rawWidgetWidth) : 0
            implicitHeight: contributesLayout ? (root.vertical ? rawWidgetHeight : root.thickness) : 0
            width: contributesLayout ? (root.vertical ? Math.min(root.verticalItemWidthCap, Math.max(root.thickness, rawWidgetWidth)) : rawWidgetWidth) : 0
            height: contributesLayout ? (root.vertical ? rawWidgetHeight : root.thickness) : 0

            function refreshDiagnosticState() {
                if (diagnosticState === "inactive")
                    root.maybeLogBarWidgetInactive(widgetId, widgetInstance, hiddenInVertical);

                if (diagnosticState === "pending")
                    stuckPendingTimer.restart();
                else {
                    stuckPendingTimer.stop();
                    stuckPendingReported = false;
                }

                var detail = "";
                if (diagnosticState === "load-error") {
                    detail = "component failed to load";
                    if (Config.barWidgetLoadLogging) {
                        var wtypeErr = widgetInstance ? String(widgetInstance.widgetType || "") : "";
                        var barErr = root.barConfig ? root.barConfig.id : "";
                        detail += " | type=" + wtypeErr + " bar=" + barErr + " loaderStatus=" + widgetLoader.status;
                    }
                } else if (diagnosticState === "vertical-overflow") {
                    detail = "widget exceeded the vertical width cap and was collapsed";
                } else if (diagnosticState === "zero-footprint") {
                    detail = "widget is enabled but reports zero layout footprint";
                    if (Config.barWidgetLoadLogging) {
                        var wtypeZ = widgetInstance ? String(widgetInstance.widgetType || "") : "";
                        var barZ = root.barConfig ? root.barConfig.id : "";
                        var itemVis = widgetLoader.item ? widgetLoader.item.visible : null;
                        detail += " | type=" + wtypeZ + " bar=" + barZ + " itemVisible=" + itemVis;
                    }
                }
                if (diagnosticState === "zero-footprint") {
                    if (!root.diagnosticsReady) {
                        diagnosticGraceTimer.stop();
                        deferredDiagnosticState = "";
                        deferredDiagnosticDetail = "";
                        return;
                    }
                    deferredDiagnosticState = diagnosticState;
                    deferredDiagnosticDetail = detail;
                    diagnosticGraceTimer.restart();
                    return;
                }
                diagnosticGraceTimer.stop();
                deferredDiagnosticState = "";
                deferredDiagnosticDetail = "";
                root.reportWidgetDiagnostic(widgetId, diagnosticState, detail);
            }

            onDiagnosticStateChanged: diagnosticWrapper.refreshDiagnosticState()
            onDiagnosticsReadyChanged: diagnosticWrapper.refreshDiagnosticState()
            Component.onCompleted: diagnosticWrapper.refreshDiagnosticState()

            Timer {
                id: diagnosticGraceTimer
                readonly property int _diagnosticGraceMs: 180
                interval: _diagnosticGraceMs
                repeat: false
                onTriggered: {
                    if (parent.diagnosticState !== parent.deferredDiagnosticState)
                        return;
                    root.reportWidgetDiagnostic(parent.widgetId, parent.deferredDiagnosticState, parent.deferredDiagnosticDetail);
                }
            }

            Timer {
                id: stuckPendingTimer
                interval: 5000
                repeat: false
                onTriggered: {
                    if (parent.diagnosticState !== "pending")
                        return;
                    if (!Config.barWidgetLoadLogging || parent.stuckPendingReported)
                        return;
                    parent.stuckPendingReported = true;
                    var wtypeP = parent.widgetInstance ? String(parent.widgetInstance.widgetType || "") : "";
                    var barP = root.barConfig ? root.barConfig.id : "";
                    Logger.w("Panel", "bar widget still pending after 5s:", parent.widgetId, "type=" + wtypeP, "bar=" + barP);
                }
            }

            Loader {
                id: widgetLoader
                anchors.centerIn: parent
                active: parent.widgetEnabled
                sourceComponent: root.componentForWidget(parent.widgetInstance ? parent.widgetInstance.widgetType : "")
                onStatusChanged: diagnosticWrapper.refreshDiagnosticState()
                onLoaded: {
                    if (item && item.widgetInstance !== undefined)
                        item.widgetInstance = parent.widgetInstance;
                    diagnosticWrapper.refreshDiagnosticState();
                }
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: {
                    if (!Config.barUseModularEntries || !widgetInstance.isModular) {
                        // Fallback to widget's own context menu if it has one
                        if (widgetLoader.item && widgetLoader.item.contextMenuRequested) {
                            // This is handled inside widgets usually
                        }
                        return;
                    }

                    var moveWidget = function(dir) {
                        Config.moveModularEntry(widgetInstance.section, widgetInstance.index, dir);
                        ToastService.showNoticeAction("Layout updated", "Widget moved", "Undo", () => Config.undoModularChange());
                    };

                    var removeWidget = function() {
                        Config.removeModularEntry(widgetInstance.section, widgetInstance.index);
                        ToastService.showNoticeAction("Widget removed", "Removed " + widgetInstance.widgetType, "Undo", () => Config.undoModularChange());
                    };

                    var actions = [
                        {
                            label: "Move Left",
                            icon: "arrow-left.svg",
                            action: function() { moveWidget(-1); }
                        },
                        {
                            label: "Move Right",
                            icon: "arrow-right.svg",
                            action: function() { moveWidget(1); }
                        },
                        {
                            separator: true
                        },
                        {
                            label: "Remove Widget",
                            icon: "dismiss.svg",
                            danger: true,
                            action: function() { removeWidget(); }
                        }
                    ];

                    var topLeft = diagnosticWrapper.mapToItem(root, 0, 0);
                    root.contextMenuRequested(actions, {
                        x: topLeft.x,
                        y: topLeft.y,
                        width: diagnosticWrapper.width,
                        height: diagnosticWrapper.height
                    });
                }
            }
        }
    }

    Component {
        id: logoComponent
        Logo {
            property var widgetInstance: null
            tooltipText: "Application launcher"
            anchorWindow: root.anchorWindow
            iconOnly: root.triggerWidgetIconOnly(widgetInstance)
            labelText: root.triggerWidgetLabel(widgetInstance, "Apps")
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: criticalAlertComponent
        SharedWidgets.BarPill {
            property var widgetInstance: null
            visible: SystemStatus.isCritical
            anchorWindow: root.anchorWindow
            normalColor: Colors.withAlpha(Colors.error, 0.2)
            hoverColor: Colors.withAlpha(Colors.error, 0.28)
            activeColor: Colors.withAlpha(Colors.error, 0.28)
            normalBorderColor: Colors.error
            activeBorderColor: Colors.error
            tooltipText: "CRITICAL: High load or temperature detected"

            SharedWidgets.SvgIcon {
                anchors.centerIn: parent
                source: "alert.svg"
                color: Colors.error
                size: Appearance.fontSizeLarge
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: 1.0
                        to: 0.3
                        duration: Appearance.durationMediumSlow
                    }
                    NumberAnimation {
                        from: 0.3
                        to: 1.0
                        duration: Appearance.durationMediumSlow
                    }
                }
            }
        }
    }

    Component {
        id: workspacesComponent
        Workspaces {
            property var widgetInstance: null
            vertical: root.vertical
            anchorWindow: root.anchorWindow
            settings: root.widgetSettings(widgetInstance)
            showAddButton: root.widgetSettings(widgetInstance).showAddButton !== false
            showMiniMap: root.widgetSettings(widgetInstance).showMiniMap !== false
        }
    }

    Component {
        id: specialWorkspacesComponent
        SpecialWorkspaces {
            property var widgetInstance: null
            vertical: root.vertical
            anchorWindow: root.anchorWindow
        }
    }

    Component {
        id: taskbarComponent
        Taskbar {
            property var widgetInstance: null
            vertical: root.vertical
            anchorWindow: root.anchorWindow
            buttonSize: root.widgetIntegerSetting(widgetInstance, "buttonSize", 32, 24, 56)
            iconSize: root.widgetIntegerSetting(widgetInstance, "iconSize", 20, 14, 36)
            showRunningIndicator: root.widgetSettings(widgetInstance).showRunningIndicator !== false
            showSeparator: root.widgetSettings(widgetInstance).showSeparator !== false
            maxUnpinned: root.widgetIntegerSetting(widgetInstance, "maxUnpinned", 0, 0, 20)
        }
    }

    Component {
        id: windowTitleComponent
        WindowTitle {
            property var widgetInstance: null
        }
    }

    Component {
        id: keyboardLayoutComponent
        KeyboardLayout {
            property var widgetInstance: null
            vertical: root.vertical
            anchorWindow: root.anchorWindow
        }
    }

    Component {
        id: cpuStatusComponent
        StatPill {
            property var widgetInstance: null
            statKey: "cpuStatus"
            icon: "developer-board.svg"
            iconColor: Colors.primary
            label: "CPU"
            anchorWindow: root.anchorWindow
            compact: root.isCompactStatWidget(widgetInstance)
            iconOnly: root.isIconOnlyStatWidget(widgetInstance)
            valueText: root.statDisplayText("cpuStatus", widgetInstance)
            compactValueText: root.compactStatDisplayText("cpuStatus", widgetInstance)
            tooltipText: root.statTooltipText("cpuStatus", widgetInstance)
            isActive: root.isSurfaceActive("systemStatsMenu", "statKey", "cpuStatus")
            onClicked: root.requestSurface("systemStatsMenu", this, { statKey: "cpuStatus" })
        }
    }

    Component {
        id: ramStatusComponent
        StatPill {
            property var widgetInstance: null
            statKey: "ramStatus"
            icon: "board.svg"
            iconColor: Colors.accent
            label: "RAM"
            anchorWindow: root.anchorWindow
            compact: root.isCompactStatWidget(widgetInstance)
            iconOnly: root.isIconOnlyStatWidget(widgetInstance)
            valueText: root.statDisplayText("ramStatus", widgetInstance)
            compactValueText: root.compactStatDisplayText("ramStatus", widgetInstance)
            tooltipText: root.statTooltipText("ramStatus", widgetInstance)
            isActive: root.isSurfaceActive("systemStatsMenu", "statKey", "ramStatus")
            onClicked: root.requestSurface("systemStatsMenu", this, { statKey: "ramStatus" })
        }
    }

    Component {
        id: gpuStatusComponent
        StatPill {
            property var widgetInstance: null
            statKey: "gpuStatus"
            icon: "developer-board.svg"
            iconColor: Colors.secondary
            label: "GPU"
            anchorWindow: root.anchorWindow
            compact: root.isCompactStatWidget(widgetInstance)
            iconOnly: root.isIconOnlyStatWidget(widgetInstance)
            valueText: root.statDisplayText("gpuStatus", widgetInstance)
            compactValueText: root.compactStatDisplayText("gpuStatus", widgetInstance)
            tooltipText: root.statTooltipText("gpuStatus", widgetInstance)
            isActive: root.isSurfaceActive("systemStatsMenu", "statKey", "gpuStatus")
            onClicked: root.requestSurface("systemStatsMenu", this, { statKey: "gpuStatus" })
        }
    }

    Component {
        id: diskStatusComponent
        StatPill {
            property var widgetInstance: null
            statKey: "diskStatus"
            icon: "hard-drive.svg"
            iconColor: Colors.secondary
            label: "Disk"
            anchorWindow: root.anchorWindow
            compact: root.isCompactStatWidget(widgetInstance)
            iconOnly: root.isIconOnlyStatWidget(widgetInstance)
            valueText: root.statDisplayText("diskStatus", widgetInstance)
            compactValueText: root.compactStatDisplayText("diskStatus", widgetInstance)
            tooltipText: root.statTooltipText("diskStatus", widgetInstance)
            isActive: root.isSurfaceActive("systemStatsMenu", "statKey", "diskStatus")
            onClicked: root.requestSurface("systemStatsMenu", this, { statKey: "diskStatus" })
        }
    }

    Component {
        id: networkStatusComponent
        StatPill {
            property var widgetInstance: null
            statKey: "networkStatus"
            icon: "ethernet.svg"
            iconColor: Colors.primary
            label: "Net"
            anchorWindow: root.anchorWindow
            compact: root.isCompactStatWidget(widgetInstance)
            iconOnly: root.isIconOnlyStatWidget(widgetInstance)
            valueText: root.statDisplayText("networkStatus", widgetInstance)
            compactValueText: root.compactStatDisplayText("networkStatus", widgetInstance)
            tooltipText: root.statTooltipText("networkStatus", widgetInstance)
            isActive: root.isSurfaceActive("systemStatsMenu", "statKey", "networkStatus")
            onClicked: root.requestSurface("systemStatsMenu", this, { statKey: "networkStatus" })
        }
    }

    Component {
        id: legacySystemMonitorComponent
        SystemMonitor {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            isActive: root.isSurfaceActive("systemStatsMenu")
            onStatsClicked: root.requestSurface("systemStatsMenu", this)
        }
    }

    Component {
        id: dateTimeComponent
        DateTimeBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
            isActive: root.isSurfaceActive("dateTimeMenu")
            onClicked: triggerItem => root.requestSurface("dateTimeMenu", triggerItem)
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: mediaBarComponent
        SharedWidgets.MediaBar {
            property var widgetInstance: null
            vertical: root.vertical
            iconOnly: root.isSummaryWidgetIconOnly(widgetInstance)
            maxTextWidth: root.widgetIntegerSetting(widgetInstance, "maxTextWidth", 150, 80, 240)
            showVisualizer: root.widgetBooleanSetting(widgetInstance, "showVisualizer", true)
            visualizerBars: root.widgetIntegerSetting(widgetInstance, "visualizerBars", 8, 4, 20)
            anchorWindow: root.anchorWindow
        }
    }

    Component {
        id: updatesComponent
        UpdatesBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
        }
    }

    Component {
        id: cavaComponent
        CavaBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
            isActive: root.isSurfaceActive("cavaPopup")
            onClicked: triggerItem => root.requestSurface("cavaPopup", triggerItem)
        }
    }

    Component {
        id: idleInhibitorComponent
        IdleInhibitorBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: modelUsageComponent
        ModelUsageBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
            isActive: root.isSurfaceActive("modelUsageMenu")
            onTriggerRequested: triggerItem => root.requestSurface("modelUsageMenu", triggerItem)
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: weatherComponent
        WeatherBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
            isActive: root.isSurfaceActive("weatherMenu")
            onTriggerRequested: triggerItem => root.requestSurface("weatherMenu", triggerItem)
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: marketComponent
        MarketBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
            isActive: root.isSurfaceActive("marketMenu")
            onTriggerRequested: triggerItem => root.requestSurface("marketMenu", triggerItem)
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: sshComponent
        SharedWidgets.SshWidget {
            id: sshWidgetRoot
            property var widgetInstance: null
            isActive: root.isSurfaceActive("sshMenu")
            anchorWindow: root.anchorWindow
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

            Connections {
                target: sshWidgetRoot
                function onSurfaceRequested(triggerItem, extraContext) {
                    root.requestSurface("sshMenu", triggerItem, extraContext);
                }
            }
        }
    }

    Component {
        id: vpnComponent
        VpnBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
            isActive: root.isSurfaceActive("vpnMenu")
            onTriggerRequested: triggerItem => root.requestSurface("vpnMenu", triggerItem)
            onNetworkClicked: triggerItem => root.requestSurface("networkMenu", triggerItem)
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: networkComponent
        SharedWidgets.BarPill {
            property var widgetInstance: null
            isActive: root.isSurfaceActive("networkMenu")
            anchorWindow: root.anchorWindow
            tooltipText: networkWidget.tooltipText
            onClicked: root.requestSurface("networkMenu", this)
            contextActions: [
                {
                    label: "Open Network Menu",
                    icon: "ethernet.svg",
                    action: () => root.requestSurface("networkMenu", this)
                }
            ]
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

            Row {
                spacing: Appearance.spacingS
                SharedWidgets.NetworkWidget {
                    id: networkWidget
                    iconOnly: root.isSummaryWidgetIconOnly(widgetInstance)
                }
            }
        }
    }

    Component {
        id: bluetoothComponent
        BluetoothBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
            isActive: root.isSurfaceActive("bluetoothMenu")
            onTriggerRequested: triggerItem => root.requestSurface("bluetoothMenu", triggerItem)
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: audioComponent
        SharedWidgets.BarPill {
            property var widgetInstance: null
            isActive: root.isSurfaceActive("audioMenu")
            anchorWindow: root.anchorWindow
            tooltipText: audioWidget.tooltipText
            onClicked: root.requestSurface("audioMenu", this)
            contextActions: [
                {
                    label: AudioService.outputMuted ? "Unmute" : "Mute",
                    icon: AudioService.outputMuted ? "speaker-mute.svg" : "speaker-2-filled.svg",
                    action: () => AudioService.toggleMute("@DEFAULT_AUDIO_SINK@", AudioService.outputMuted)
                },
                {
                    separator: true
                },
                {
                    label: "Open Audio Menu",
                    icon: "speaker.svg",
                    action: () => root.requestSurface("audioMenu", this)
                }
            ]
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

            Row {
                spacing: Appearance.spacingS
                SharedWidgets.AudioWidget {
                    id: audioWidget
                    iconOnly: root.isSummaryWidgetIconOnly(widgetInstance)
                }
            }
        }
    }

    Component {
        id: musicComponent
        MusicBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
            isActive: root.isSurfaceActive("musicMenu")
            onTriggerRequested: triggerItem => root.requestSurface("musicMenu", triggerItem)
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: privacyComponent
        PrivacyBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
            isActive: root.isSurfaceActive("privacyMenu")
            onTriggerRequested: triggerItem => root.requestSurface("privacyMenu", triggerItem)
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: voxtypeComponent
        VoxtypeBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: recordingComponent
        RecordingBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
            isActive: root.isSurfaceActive("recordingMenu")
            onTriggerRequested: triggerItem => root.requestSurface("recordingMenu", triggerItem)
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: batteryComponent
        SharedWidgets.BarPill {
            property var widgetInstance: null
            visible: batteryWidget.showBattery
            isActive: root.isSurfaceActive("batteryMenu")
            anchorWindow: root.anchorWindow
            tooltipText: batteryWidget.tooltipText
            onClicked: root.requestSurface("batteryMenu", this)
            contextActions: [
                {
                    label: "Power Saver",
                    icon: "power.svg",
                    action: () => PowerProfileService.setProfile("power-saver")
                },
                {
                    label: "Balanced",
                    icon: "scales.svg",
                    action: () => PowerProfileService.setProfile("balanced")
                },
                {
                    label: "Performance",
                    icon: "flash-on.svg",
                    action: () => PowerProfileService.setProfile("performance")
                },
                {
                    separator: true
                },
                {
                    label: "Open Battery Menu",
                    icon: "battery-full.svg",
                    action: () => root.requestSurface("batteryMenu", this)
                }
            ]
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

            Row {
                spacing: Appearance.spacingXS
                SharedWidgets.BatteryWidget {
                    id: batteryWidget
                    iconOnly: root.isSummaryWidgetIconOnly(widgetInstance)
                }
            }
        }
    }

    Component {
        id: printerComponent
        PrinterBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
            isActive: root.isSurfaceActive("printerMenu")
            onTriggerRequested: triggerItem => root.requestSurface("printerMenu", triggerItem)
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: aiChatPillComponent
        BarSurfacePill {
            surfaceId: "aiChat"
            iconText: "sparkle.svg"
            iconSize: Appearance.fontSizeLarge
            defaultLabel: "AI"
            tooltipText: "AI Chat"
            panelRef: root
        }
    }

    Component {
        id: notepadComponent
        BarSurfacePill {
            surfaceId: "notepad"
            iconText: "edit.svg"
            iconSize: Appearance.fontSizeLarge
            defaultLabel: "Notes"
            tooltipText: "Notepad"
            panelRef: root
        }
    }

    Component {
        id: controlCenterComponent
        BarSurfacePill {
            surfaceId: "controlCenter"
            iconText: "settings.svg"
            defaultLabel: "Controls"
            tooltipText: "System controls"
            tooltipShortcutText: "Meta+C"
            panelRef: root
        }
    }

    Component {
        id: trayComponent
        SharedWidgets.TrayWidget {
            property var widgetInstance: null
            vertical: root.vertical
            anchorWindow: root.anchorWindow
            itemSize: root.widgetIntegerSetting(widgetInstance, "itemSize", 24, 18, 40)
            iconSize: root.widgetIntegerSetting(widgetInstance, "iconSize", 18, 12, 32)
            itemSpacing: root.widgetIntegerSetting(widgetInstance, "spacing", Appearance.spacingS, 2, 16)
        }
    }

    Component {
        id: clipboardComponent
        BarSurfacePill {
            surfaceId: "clipboardMenu"
            iconText: "paste.svg"
            defaultLabel: "Clipboard"
            tooltipText: "Clipboard history"
            panelRef: root
            extraContextActions: [
                {
                    label: "Clear History",
                    icon: "archive.svg",
                    danger: true,
                    action: () => Quickshell.execDetached(["cliphist", "wipe"])
                }
            ]
        }
    }

    Component {
        id: screenshotComponent
        BarSurfacePill {
            surfaceId: "screenshotMenu"
            iconText: "image-copy.svg"
            defaultLabel: "Shot"
            tooltipText: "Screenshot"
            panelRef: root
        }
    }

    Component {
        id: notificationsComponent
        NotificationsBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
            manager: root.manager
            isActive: root.isSurfaceActive("notifCenter")
            onTriggerRequested: triggerItem => root.requestSurface("notifCenter", triggerItem)
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: spacerComponent
        Item {
            property var widgetInstance: null
            readonly property int spacerSize: {
                var settings = root.widgetSettings(widgetInstance);
                return Math.max(8, parseInt(settings.size !== undefined ? settings.size : 24, 10) || 24);
            }
            width: root.vertical ? 1 : spacerSize
            height: root.vertical ? spacerSize : 1
            implicitWidth: width
            implicitHeight: height
        }
    }

    Component {
        id: separatorComponent
        Rectangle {
            property var widgetInstance: null
            readonly property int separatorThickness: root.widgetIntegerSetting(widgetInstance, "thickness", 1, 1, 8)
            readonly property int separatorLength: root.widgetIntegerSetting(widgetInstance, "length", 20, 8, 64)
            implicitWidth: root.vertical ? Math.max(24, root.thickness - 8) : separatorThickness
            implicitHeight: root.vertical ? separatorThickness : separatorLength
            width: implicitWidth
            height: implicitHeight
            radius: Appearance.radiusXXXS
            color: Colors.border
            opacity: {
                var settings = root.widgetSettings(widgetInstance);
                var parsed = Number(settings.opacity !== undefined ? settings.opacity : 0.8);
                if (isNaN(parsed))
                    return 0.8;
                return Math.max(0.1, Math.min(1.0, parsed));
            }
        }
    }

    Component {
        id: pluginComponent
        Loader {
            property var widgetInstance: null
            readonly property var pluginMeta: BarWidgetRegistry.pluginByWidgetType(widgetInstance ? widgetInstance.widgetType : "")
            source: pluginMeta ? pluginMeta.path + pluginMeta.entryFile : ""
            onStatusChanged: {
                if (status === Loader.Error && widgetInstance)
                    Logger.w("BarWidgetRegistry", "failed to load plugin widget " + widgetInstance.widgetType + " from " + source);
                if (status === Loader.Ready && item && pluginMeta) {
                    var api = PluginService.getPluginAPI(pluginMeta.id);
                    if (api && item.hasOwnProperty("pluginApi"))
                        item.pluginApi = api;
                    if (item.hasOwnProperty("pluginManifest"))
                        item.pluginManifest = pluginMeta;
                    if (item.hasOwnProperty("pluginService"))
                        item.pluginService = PluginService;
                }
            }
        }
    }

    Component {
        id: personalityComponent
        SharedWidgets.PersonalityGif {
            property var widgetInstance: null
        }
    }

    Component {
        id: pomodoroComponent
        PomodoroBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: todoComponent
        TodoBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: gameModeComponent
        GameModeBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: nightLightComponent
        NightLightBarWidget {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            vertical: root.vertical
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        }
    }

    Component {
        id: unknownComponent
        SharedWidgets.BarPill {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            enabled: false
            tooltipText: "Unknown widget: " + (widgetInstance ? widgetInstance.widgetType : "")
            Text {
                text: "?"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeMedium
            }
        }
    }
}
