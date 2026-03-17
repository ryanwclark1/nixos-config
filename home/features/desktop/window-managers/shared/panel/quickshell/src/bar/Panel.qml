import QtQuick
import Quickshell
import "."
import "widgets"
import "./widgets" as Widgets
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

    SharedWidgets.Ref {
        service: RecordingService
    }
    SharedWidgets.Ref {
        service: PrivacyService
    }
    SharedWidgets.Ref {
        service: PrinterService
    }
    SharedWidgets.Ref {
        service: SystemStatus
    }
    SharedWidgets.Ref {
        service: MediaService
    }
    SharedWidgets.Ref {
        service: WeatherService
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
    readonly property int outerPadding: Colors.spacingM
    readonly property int sectionSpacing: Colors.spacingS
    readonly property int runtimeSpacing: Colors.spacingM
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
    property bool diagnosticsReady: false
    // Expose to shell.qml for exclusiveZone control
    readonly property bool isAutoHidden: _autoHidden
    signal surfaceRequested(string surfaceId, var context)
    signal contextMenuRequested(var actions, var triggerRect)

    implicitHeight: vertical ? 0 : thickness
    implicitWidth: vertical ? Math.max(thickness, Math.max(leftColumn.implicitWidth, Math.max(centerColumn.implicitWidth, rightColumn.implicitWidth)) + outerPadding * 2) : 0

    function resetDiagnosticWarmup() {
        diagnosticsReady = false;
        diagnosticWarmupTimer.restart();
    }

    function sectionItems(section) {
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

    function widgetSettings(wi) { return PanelHelpers.widgetSettings(wi); }
    function widgetDiagnosticId(wi) { return PanelHelpers.widgetDiagnosticId(wi, root.barConfig); }
    function itemLayoutFootprint(item) { return PanelHelpers.itemLayoutFootprint(item, root.vertical); }
    function itemOccupiesSpace(item) { return PanelHelpers.itemOccupiesSpace(item, root.vertical); }

    function reportWidgetDiagnostic(widgetId, state, details) {
        var previous = _widgetDiagnosticStates[widgetId] || "";
        if (previous === state)
            return;

        if (state === "ok" || state === "inactive" || state === "pending") {
            _widgetDiagnosticStates[widgetId] = state;
            return;
        }

        _widgetDiagnosticStates[widgetId] = state;
        console.warn("[Panel] widget state warning:", widgetId, "state=" + state, details || "");
    }

    onBarConfigChanged: resetDiagnosticWarmup()
    onSectionWidgetsChanged: resetDiagnosticWarmup()
    Component.onCompleted: resetDiagnosticWarmup()

    Timer {
        id: diagnosticWarmupTimer
        interval: 1200
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

    function compactPercentText(value) { return PanelHelpers.compactPercentText(value); }
    function widgetValueStyle(wi, widgetType) { return PanelHelpers.widgetValueStyle(wi, widgetType); }
    function statDisplayText(widgetType, wi) { return PanelHelpers.statDisplayText(widgetType, wi, SystemStatus); }
    function compactStatDisplayText(widgetType, wi) { return PanelHelpers.compactStatDisplayText(widgetType, wi, SystemStatus); }
    function statTooltipText(widgetType, wi) { return PanelHelpers.statTooltipText(widgetType, wi, SystemStatus); }
    function widgetDisplayMode(wi) { return PanelHelpers.widgetDisplayMode(wi); }
    function widgetSummaryDisplayMode(wi) { return PanelHelpers.widgetSummaryDisplayMode(wi); }
    function isCompactStatWidget(wi) { return PanelHelpers.isCompactStatWidget(wi, root.vertical); }
    function isIconOnlyStatWidget(wi) { return PanelHelpers.isIconOnlyStatWidget(wi); }
    function isSummaryWidgetIconOnly(wi) { return PanelHelpers.isSummaryWidgetIconOnly(wi, root.vertical); }
    function isSummaryWidgetFull(wi) { return PanelHelpers.isSummaryWidgetFull(wi, root.vertical); }
    function widgetIntegerSetting(wi, key, fallback, minValue, maxValue) { return PanelHelpers.widgetIntegerSetting(wi, key, fallback, minValue, maxValue); }
    function widgetBooleanSetting(wi, key, fallback) { return PanelHelpers.widgetBooleanSetting(wi, key, fallback); }
    function widgetStringSetting(wi, key, fallback, allowedValues) { return PanelHelpers.widgetStringSetting(wi, key, fallback, allowedValues); }
    function triggerWidgetIconOnly(wi) { return PanelHelpers.triggerWidgetIconOnly(wi); }
    function triggerWidgetLabel(wi, fallback) { return PanelHelpers.triggerWidgetLabel(wi, fallback); }

    function componentForWidget(widgetType) {
        if (widgetType === "logo")
            return logoComponent;
        if (widgetType === "workspaces")
            return workspacesComponent;
        if (widgetType === "taskbar")
            return taskbarComponent;
        if (widgetType === "windowTitle")
            return windowTitleComponent;
        if (widgetType === "keyboardLayout")
            return keyboardLayoutComponent;
        if (widgetType === "cpuStatus")
            return cpuStatusComponent;
        if (widgetType === "ramStatus")
            return ramStatusComponent;
        if (widgetType === "gpuStatus")
            return gpuStatusComponent;
        if (widgetType === "systemMonitor")
            return legacySystemMonitorComponent;
        if (widgetType === "dateTime")
            return dateTimeComponent;
        if (widgetType === "mediaBar")
            return mediaBarComponent;
        if (widgetType === "updates")
            return updatesComponent;
        if (widgetType === "cava")
            return cavaComponent;
        if (widgetType === "idleInhibitor")
            return idleInhibitorComponent;
        if (widgetType === "weather")
            return weatherComponent;
        if (widgetType === "ssh")
            return sshComponent;
        if (widgetType === "vpn")
            return vpnComponent;
        if (widgetType === "network")
            return networkComponent;
        if (widgetType === "bluetooth")
            return bluetoothComponent;
        if (widgetType === "audio")
            return audioComponent;
        if (widgetType === "music")
            return musicComponent;
        if (widgetType === "privacy")
            return privacyComponent;
        if (widgetType === "recording")
            return recordingComponent;
        if (widgetType === "battery")
            return batteryComponent;
        if (widgetType === "printer")
            return printerComponent;
        if (widgetType === "aiChat")
            return aiChatPillComponent;
        if (widgetType === "notepad")
            return notepadComponent;
        if (widgetType === "controlCenter")
            return controlCenterComponent;
        if (widgetType === "tray")
            return trayComponent;
        if (widgetType === "clipboard")
            return clipboardComponent;
        if (widgetType === "screenshot")
            return screenshotComponent;
        if (widgetType === "notifications")
            return notificationsComponent;
        if (widgetType === "spacer")
            return spacerComponent;
        if (widgetType === "separator")
            return separatorComponent;
        if (String(widgetType || "").indexOf("plugin:") === 0)
            return pluginComponent;
        return unknownComponent;
    }

    // ── Auto-hide logic ─────────────────────────
    Timer {
        id: autoHideTimer
        interval: root.autoHideDelay
        onTriggered: {
            if (root.autoHide && !root._hovered)
                root._autoHidden = true;
        }
    }

    onAutoHideChanged: {
        if (!autoHide)
            root._autoHidden = false;
    }

    on_HoveredChanged: {
        if (_hovered) {
            root._autoHidden = false;
            autoHideTimer.stop();
        } else if (root.autoHide) {
            autoHideTimer.restart();
        }
    }

    // Hover sensor for auto-hide (covers the full bar area)
    HoverHandler {
        id: barHoverHandler
        onHoveredChanged: root._hovered = barHoverHandler.hovered
    }

    // Auto-hide: slide bar off-screen and fade out
    property real _slideOffset: root._autoHidden ? (root.position === "bottom" ? root.thickness : -root.thickness) : 0

    Behavior on _slideOffset {
        NumberAnimation {
            duration: Colors.durationFast
            easing.type: Easing.InOutQuad
        }
    }

    opacity: root._autoHidden ? 0 : 1
    Behavior on opacity {
        NumberAnimation {
            duration: Colors.durationFast
            easing.type: Easing.InOutQuad
        }
    }

    transform: Translate {
        y: root._slideOffset
    }

    // ── Scroll behavior ───────────────────────────
    WheelHandler {
        enabled: root.scrollBehavior !== "none"
        onWheel: event => {
            var delta = event.angleDelta.y;
            if (delta === 0)
                return;
            if (root.scrollBehavior === "workspace") {
                if (delta > 0)
                    CompositorAdapter.focusWorkspace("e-1");
                else
                    CompositorAdapter.focusWorkspace("e+1");
            } else if (root.scrollBehavior === "volume") {
                var step = delta > 0 ? 0.02 : -0.02;
                AudioService.setVolume("@DEFAULT_AUDIO_SINK@", Math.max(0, Math.min(1, AudioService.outputVolume + step)));
            }
        }
    }

    // ── Shadow (layered for soft-shadow effect) ──
    Repeater {
        model: root.shadowEnabled ? 3 : 0
        Rectangle {
            readonly property real spread: [2, 5, 8][index]
            readonly property real baseAlpha: [0.5, 0.25, 0.1][index]
            visible: !root._autoHidden
            anchors.fill: parent
            anchors.margins: -spread
            z: -1 - index
            radius: floatingBar ? Colors.radiusMedium + spread : 0
            color: Qt.rgba(0, 0, 0, root.shadowOpacity * baseAlpha)
        }
    }

    // ── Background ────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: root.noBackground ? "transparent" : Colors.bgGlass
        radius: root.floatingBar ? Colors.radiusMedium : 0
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
    }

    Row {
        id: leftSection
        visible: !vertical
        anchors.left: parent.left
        anchors.leftMargin: outerPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: runtimeSpacing + sectionSpacing

        Repeater {
            model: root.leadingLauncherItems("left")
            delegate: widgetLoaderDelegate
        }

        Row {
            visible: root.trailingSectionItems("left").length > 0
            spacing: runtimeSpacing

            Repeater {
                model: root.trailingSectionItems("left")
                delegate: widgetLoaderDelegate
            }
        }
    }

    Row {
        id: centerSection
        visible: !vertical
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: root.centerClampedOffset
        anchors.verticalCenter: parent.verticalCenter
        spacing: runtimeSpacing
        Repeater {
            model: root.sectionItems("center")
            delegate: widgetLoaderDelegate
        }
    }

    Row {
        id: rightSection
        visible: !vertical
        anchors.right: parent.right
        anchors.rightMargin: outerPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: runtimeSpacing
        Repeater {
            model: root.sectionItems("right")
            delegate: widgetLoaderDelegate
        }
    }

    Column {
        id: leftColumn
        visible: vertical
        anchors.top: parent.top
        anchors.topMargin: outerPadding
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: runtimeSpacing + sectionSpacing

        Repeater {
            model: root.leadingLauncherItems("left")
            delegate: widgetLoaderDelegate
        }

        Column {
            visible: root.trailingSectionItems("left").length > 0
            spacing: runtimeSpacing

            Repeater {
                model: root.trailingSectionItems("left")
                delegate: widgetLoaderDelegate
            }
        }
    }

    Column {
        id: centerColumn
        visible: vertical
        anchors.centerIn: parent
        spacing: runtimeSpacing
        Repeater {
            model: root.sectionItems("center")
            delegate: widgetLoaderDelegate
        }
    }

    Column {
        id: rightColumn
        visible: vertical
        anchors.bottom: parent.bottom
        anchors.bottomMargin: outerPadding
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: runtimeSpacing
        Repeater {
            model: root.sectionItems("right")
            delegate: widgetLoaderDelegate
        }
    }

    Component {
        id: widgetLoaderDelegate
        Item {
            id: diagnosticWrapper
            required property var modelData
            property var widgetInstance: modelData
            property string deferredDiagnosticState: ""
            property string deferredDiagnosticDetail: ""
            readonly property bool occupiesSpace: root.itemOccupiesSpace(widgetLoader.item)
            readonly property bool diagnosticsReady: root.diagnosticsReady
            readonly property bool widgetEnabled: !!widgetInstance && widgetInstance.enabled !== false
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
                if (!occupiesSpace)
                    return "zero-footprint";
                return "ok";
            }
            implicitWidth: occupiesSpace ? widgetLoader.implicitWidth : 0
            implicitHeight: occupiesSpace ? (root.vertical ? widgetLoader.implicitHeight : root.thickness) : 0
            width: occupiesSpace ? (root.vertical ? Math.max(root.thickness, widgetLoader.implicitWidth) : widgetLoader.implicitWidth) : 0
            height: occupiesSpace ? (root.vertical ? widgetLoader.implicitHeight : root.thickness) : 0

            function refreshDiagnosticState() {
                var detail = "";
                if (diagnosticState === "load-error")
                    detail = "component failed to load";
                else if (diagnosticState === "zero-footprint")
                    detail = "widget is enabled but reports zero layout footprint";
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
                interval: 180
                repeat: false
                onTriggered: {
                    if (parent.diagnosticState !== parent.deferredDiagnosticState)
                        return;
                    root.reportWidgetDiagnostic(parent.widgetId, parent.deferredDiagnosticState, parent.deferredDiagnosticDetail);
                }
            }

            Loader {
                id: widgetLoader
                anchors.centerIn: parent
                active: !!parent.widgetInstance && parent.widgetInstance.enabled !== false
                sourceComponent: root.componentForWidget(parent.widgetInstance ? parent.widgetInstance.widgetType : "")
                onStatusChanged: diagnosticWrapper.refreshDiagnosticState()
                onLoaded: {
                    if (item && item.widgetInstance !== undefined)
                        item.widgetInstance = parent.widgetInstance;
                    diagnosticWrapper.refreshDiagnosticState();
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
        }
    }

    Component {
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

            Text {
                anchors.centerIn: parent
                text: "󰀪"
                color: Colors.error
                font.pixelSize: Colors.fontSizeLarge
                font.family: Colors.fontMono
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: 1.0
                        to: 0.3
                        duration: 500
                    }
                    NumberAnimation {
                        from: 0.3
                        to: 1.0
                        duration: 500
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
            showAddButton: root.widgetSettings(widgetInstance).showAddButton !== false
            showMiniMap: root.widgetSettings(widgetInstance).showMiniMap !== false
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
            anchorWindow: root.anchorWindow
        }
    }

    Component {
        id: cpuStatusComponent
        StatPill {
            property var widgetInstance: null
            statKey: "cpuStatus"
            icon: ""
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
            icon: "󰍛"
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
            icon: "󰢮"
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
                    icon: "󰛳",
                    action: () => root.requestSurface("networkMenu", this)
                }
            ]
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

            Row {
                spacing: Colors.spacingS
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
                    icon: AudioService.outputMuted ? "󰖁" : "󰕾",
                    action: () => AudioService.toggleMute("@DEFAULT_AUDIO_SINK@", AudioService.outputMuted)
                },
                {
                    separator: true
                },
                {
                    label: "Open Audio Menu",
                    icon: "󰕾",
                    action: () => root.requestSurface("audioMenu", this)
                }
            ]
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

            Row {
                spacing: Colors.spacingS
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
                    icon: "󰌪",
                    action: () => PowerProfileService.setProfile("power-saver")
                },
                {
                    label: "Balanced",
                    icon: "󰛲",
                    action: () => PowerProfileService.setProfile("balanced")
                },
                {
                    label: "Performance",
                    icon: "󱐋",
                    action: () => PowerProfileService.setProfile("performance")
                },
                {
                    separator: true
                },
                {
                    label: "Open Battery Menu",
                    icon: "󰁹",
                    action: () => root.requestSurface("batteryMenu", this)
                }
            ]
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

            Row {
                spacing: Colors.spacingXS
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
        SharedWidgets.BarPill {
            id: aiChatPill
            property var widgetInstance: null
            isActive: root.isSurfaceActive("aiChat")
            anchorWindow: root.anchorWindow
            tooltipText: "AI Chat"
            onClicked: root.requestSurface("aiChat", this)
            contextActions: [
                {
                    label: "Open AI Chat",
                    icon: "󰚩",
                    action: () => root.requestSurface("aiChat", this)
                }
            ]
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

            Row {
                spacing: Colors.spacingXS

                Text {
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeLarge
                    font.family: Colors.fontMono
                    text: "󰚩"
                }

                Text {
                    visible: !root.triggerWidgetIconOnly(aiChatPill.widgetInstance)
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.DemiBold
                    text: root.triggerWidgetLabel(aiChatPill.widgetInstance, "AI")
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Component {
        id: notepadComponent
        SharedWidgets.BarPill {
            id: notepadPill
            property var widgetInstance: null
            isActive: root.isSurfaceActive("notepad")
            anchorWindow: root.anchorWindow
            tooltipText: "Notepad"
            onClicked: root.requestSurface("notepad", this)
            contextActions: [
                {
                    label: "Open Notepad",
                    icon: "󰠮",
                    action: () => root.requestSurface("notepad", this)
                }
            ]
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

            Row {
                spacing: Colors.spacingXS

                Text {
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeLarge
                    font.family: Colors.fontMono
                    text: "󰠮"
                }

                Text {
                    visible: !root.triggerWidgetIconOnly(notepadPill.widgetInstance)
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.DemiBold
                    text: root.triggerWidgetLabel(notepadPill.widgetInstance, "Notes")
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Component {
        id: controlCenterComponent
        SharedWidgets.BarPill {
            id: controlCenterPill
            property var widgetInstance: null
            isActive: root.isSurfaceActive("controlCenter")
            anchorWindow: root.anchorWindow
            tooltipText: "System controls"
            onClicked: root.requestSurface("controlCenter", this)
            contextActions: [
                {
                    label: "Open Settings",
                    icon: "󰒓",
                    action: () => root.requestSurface("controlCenter", this)
                }
            ]
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

            Row {
                spacing: Colors.spacingXS

                Text {
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeXL
                    font.family: Colors.fontMono
                    text: "󰒓"
                }

                Text {
                    visible: !root.triggerWidgetIconOnly(controlCenterPill.widgetInstance)
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.DemiBold
                    text: root.triggerWidgetLabel(controlCenterPill.widgetInstance, "Controls")
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
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
            itemSpacing: root.widgetIntegerSetting(widgetInstance, "spacing", Colors.spacingS, 2, 16)
        }
    }

    Component {
        id: clipboardComponent
        SharedWidgets.BarPill {
            id: clipboardPill
            property var widgetInstance: null
            isActive: root.isSurfaceActive("clipboardMenu")
            anchorWindow: root.anchorWindow
            tooltipText: "Clipboard history"
            onClicked: root.requestSurface("clipboardMenu", this)
            contextActions: [
                {
                    label: "Clear History",
                    icon: "󰎟",
                    danger: true,
                    action: () => Quickshell.execDetached(["cliphist", "wipe"])
                },
                {
                    separator: true
                },
                {
                    label: "Open Clipboard",
                    icon: "󰅍",
                    action: () => root.requestSurface("clipboardMenu", this)
                }
            ]
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

            Row {
                spacing: Colors.spacingXS

                Text {
                    text: "󰅍"
                    color: Colors.text
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXL
                }

                Text {
                    visible: !root.triggerWidgetIconOnly(clipboardPill.widgetInstance)
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.DemiBold
                    text: root.triggerWidgetLabel(clipboardPill.widgetInstance, "Clipboard")
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Component {
        id: screenshotComponent
        SharedWidgets.BarPill {
            id: screenshotPill
            property var widgetInstance: null
            isActive: root.isSurfaceActive("screenshotMenu")
            anchorWindow: root.anchorWindow
            tooltipText: "Screenshot"
            onClicked: root.requestSurface("screenshotMenu", this)
            contextActions: [
                {
                    label: "Open Screenshot Menu",
                    icon: "󰩭",
                    action: () => root.requestSurface("screenshotMenu", this)
                }
            ]
            onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

            Row {
                spacing: Colors.spacingXS

                Text {
                    text: "󰩭"
                    color: Colors.text
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXL
                }

                Text {
                    visible: !root.triggerWidgetIconOnly(screenshotPill.widgetInstance)
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.DemiBold
                    text: root.triggerWidgetLabel(screenshotPill.widgetInstance, "Shot")
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
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
            radius: Colors.radiusXXXS
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
                    console.warn("BarWidgetRegistry: failed to load plugin widget " + widgetInstance.widgetType + " from " + source);
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
        id: unknownComponent
        SharedWidgets.BarPill {
            property var widgetInstance: null
            anchorWindow: root.anchorWindow
            enabled: false
            tooltipText: "Unknown widget: " + (widgetInstance ? widgetInstance.widgetType : "")
            Text {
                text: "?"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeMedium
            }
        }
    }
}
