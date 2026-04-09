import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../system/sections"
import "../pomodoro"
import "../todo"
import "../../services"
import "../../services/ShellUtils.js" as SU
import "../../widgets" as SharedWidgets

PanelWindow {
    id: root

    property int panelWidth: Config.controlCenterWidth
    readonly property var edgeMargins: Config.reservedEdgesForScreen(screen, "")
    property int reservedTop: edgeMargins.top
    property int reservedRight: edgeMargins.right
    property int reservedBottom: edgeMargins.bottom

    anchors {
        top: true
        right: true
        bottom: true
    }

    margins.top: reservedTop + Appearance.spacingS
    margins.right: reservedRight + Appearance.spacingS
    margins.bottom: reservedBottom + Appearance.spacingS

    implicitWidth: panelWidth + 20 // Extra room for shadow/animation
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-control-center"

    property var manager: null
    property var shellRoot: null
    property bool showContent: false
    property string pendingSurfaceId: ""
    property var pendingSurfaceContext: null
    property string _quickLinkSurfaceId: ""
    readonly property int maxLayerTextureSize: 4096
    readonly property int staggerDelay: 35
    readonly property int settingsOpenDelayMs: 130
    readonly property int screenshotOpenDelayMs: 130
    signal closeRequested

    function entranceOpacity(index) {
        return showContent ? 1.0 : 0.0
    }

    function entranceScale(index) {
        return showContent ? 1.0 : 0.97
    }

    function entranceY(index) {
        return showContent ? 0 : 12
    }

    function entranceDuration(index) {
        return Appearance.durationSlow
    }

    function entranceDelay(index) {
        return showContent ? (index * staggerDelay) : 0
    }

    function allowLayer(width, height) {
        return width > 0 && height > 0
            && width <= maxLayerTextureSize
            && height <= maxLayerTextureSize;
    }

    function requestSurfaceAfterClose(surfaceId, context) {
        root.pendingSurfaceId = String(surfaceId || "");
        root.pendingSurfaceContext = context || null;
        root.closeRequested();
        openSurfaceTimer.restart();
    }

    // Widget ID → component source mapping for the Repeater+Loader
    function widgetSource(widgetId) {
        switch (String(widgetId || "")) {
        case "mediaWidget":    return "../system/sections/MediaWidget.qml";
        case "pomodoro":       return "../pomodoro/PomodoroWidget.qml";
        case "todo":           return "../todo/TodoWidget.qml";
        case "devOps":         return "../system/sections/DevOpsSection.qml";
        case "brightness":     return "../system/sections/BrightnessSection.qml";
        case "audioOutput":    return "../system/sections/AudioOutputSection.qml";
        case "audioInput":     return "../system/sections/AudioInputSection.qml";
        case "cpuGpuTemp":     return "../system/sections/CpuGpuTempSection.qml";
        case "cpuWidget":      return "../system/sections/CpuWidget.qml";
        case "systemGraphs":   return "../system/sections/SystemGraphs.qml";
        case "processWidget":  return "../system/sections/ProcessWidget.qml";
        case "networkGraphs":  return "../system/sections/NetworkGraphs.qml";
        case "ramWidget":      return "../system/sections/RamWidget.qml";
        case "diskWidget":     return "../system/sections/DiskWidget.qml";
        case "gpuWidget":      return "../system/sections/GPUWidget.qml";
        case "updateWidget":   return "../system/sections/UpdateWidget.qml";
        case "scratchpad":     return "../system/sections/ScratchpadWidget.qml";
        case "powerActions":   return "../system/sections/PowerActionsRow.qml";
        default: return "";
        }
    }

    onShowContentChanged: {
        if (!showContent) {
            if (sidebarContent.activeFocus)
                sidebarContent.focus = false;
        }
    }

    visible: root.showContent || ccSlideAnim.running || ccFadeAnim.running

    // --- Services ---
    SharedWidgets.Ref { service: AudioService }
    SharedWidgets.Ref { service: SystemStatus; active: root.showContent }
    SharedWidgets.Ref { service: RecordingService; active: root.showContent }
    SharedWidgets.Ref { service: BrightnessService; active: root.showContent }
    SharedWidgets.Ref { service: ServiceUnitService; active: root.showContent }

    // Use a shadow widget if available or just the rectangle's properties
    SharedWidgets.ElevationShadow {
        anchors.fill: sidebarContent
        visible: sidebarContent.visible && sidebarContent.opacity > 0.5
    }

    Rectangle {
        id: sidebarContent
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.panelWidth

        color: Colors.bgGlass
        border.color: Colors.border
        border.width: 1
        radius: Appearance.radiusLarge
        clip: true

        // Slide animation from right
        transform: Translate {
            x: root.showContent ? 0 : root.panelWidth + 40
            Behavior on x {
                NumberAnimation {
                    id: ccSlideAnim
                    duration: Appearance.durationSlow
                    easing.type: Easing.OutQuint
                }
            }
        }

        opacity: root.showContent ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                id: ccFadeAnim
                duration: Appearance.durationNormal
            }
        }

        SharedWidgets.InnerHighlight { highlightOpacity: 0.12 }
        SharedWidgets.SurfaceGradient {}

        Keys.onEscapePressed: root.closeRequested()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.paddingLarge
            spacing: Appearance.spacingXL
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Command Center"
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeHuge
                    font.weight: Font.DemiBold
                    font.letterSpacing: Appearance.letterSpacingTight
                }
                Item {
                    Layout.fillWidth: true
                }
                SharedWidgets.IconButton {
                    icon: "settings.svg"
                    size: Appearance.iconSizeMedium
                    iconSize: Appearance.fontSizeXL
                    tooltipText: "Settings"
                    tooltipShortcut: "Meta+S"
                    onClicked: {
                        root.closeRequested();
                        openSettingsTimer.restart();
                    }
                }
                SharedWidgets.IconButton {
                    icon: "dismiss.svg"
                    size: Appearance.iconSizeMedium
                    iconSize: Appearance.fontSizeXL
                    tooltipText: "Close"
                    onClicked: root.closeRequested()
                }
            }

            Timer {
                id: openSettingsTimer
                interval: root.settingsOpenDelayMs
                repeat: false
                onTriggered: Quickshell.execDetached(SU.ipcCall("SettingsHub", "open"))
            }

            Timer {
                id: openScreenshotTimer
                interval: root.screenshotOpenDelayMs
                repeat: false
                onTriggered: Quickshell.execDetached(SU.ipcCall("Shell", "openSurface", "screenshotMenu", ""))
            }

            Timer {
                id: openQuickLinkTimer
                interval: root.settingsOpenDelayMs
                repeat: false
                onTriggered: {
                    if (root._quickLinkSurfaceId)
                        Quickshell.execDetached(SU.ipcCall("Shell", "openSurface", root._quickLinkSurfaceId, ""));
                }
            }
            Timer {
                id: openSurfaceTimer
                interval: root.settingsOpenDelayMs
                repeat: false
                onTriggered: {
                    if (!root.shellRoot || !root.pendingSurfaceId)
                        return;
                    var nextContext = root.pendingSurfaceContext || ({});
                    if (root.screen && !nextContext.screen)
                        nextContext.screen = root.screen;
                    if (root.screen && !nextContext.screenName)
                        nextContext.screenName = Config.screenName(root.screen);
                    root.shellRoot.openSurface(root.pendingSurfaceId, nextContext);
                    root.pendingSurfaceId = "";
                    root.pendingSurfaceContext = null;
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Flickable {
                    id: ccFlick
                    anchors.fill: parent
                    contentHeight: mainCol.height
                    clip: true
                    boundsBehavior: Flickable.DragOverBounds
                    flickableDirection: Flickable.VerticalFlick

                    ColumnLayout {
                        id: mainCol
                        width: parent.width
                        spacing: Appearance.spacingXL

                        // --- Group 1: Essential Tools ---
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacingLG
                            opacity: root.entranceOpacity(0)
                            scale: root.entranceScale(0)
                            transform: Translate { y: root.entranceY(0) }
                            layer.enabled: opacity > 0 && opacity < 1
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(0) } NumberAnimation { duration: root.entranceDuration(0); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(0) } NumberAnimation { duration: root.entranceDuration(0); easing.type: Easing.OutBack } } }

                            UserWidget {
                                Layout.fillWidth: true
                            }

                            // Quick Links (ordered, filtered by visibility)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacingS
                                visible: ControlCenterRegistry.visibleQuickLinkItems.length > 0

                                Repeater {
                                    model: ControlCenterRegistry.visibleQuickLinkItems
                                    delegate: QuickLinkCard {
                                        required property var modelData
                                        icon: modelData.icon
                                        title: modelData.title
                                        subtitle: modelData.subtitle
                                        clickAction: function() {
                                            root.closeRequested();
                                            if (modelData.id === "screenshotControls") {
                                                openScreenshotTimer.restart();
                                            } else if (modelData.ipcTarget && modelData.ipcAction) {
                                                var surfaceId = (modelData.clickCommand && modelData.clickCommand.length > 5) ? modelData.clickCommand[5] : "";
                                                root._quickLinkSurfaceId = surfaceId;
                                                openQuickLinkTimer.restart();
                                            } else if (Array.isArray(modelData.clickCommand) && modelData.clickCommand.length > 0) {
                                                Quickshell.execDetached(modelData.clickCommand);
                                            }
                                        }
                                    }
                                }
                            }

                            // Quick Toggles Grid
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacingS

                                SharedWidgets.SectionLabel {
                                    label: "QUICK TOGGLES"
                                }

                                QuickToggleGrid {
                                    manager: root.manager
                                    showContent: root.showContent
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacingS
                                visible: PluginService.visibleControlCenterPlugins.length > 0

                                Text {
                                    text: "PLUGINS"
                                    color: Colors.textDisabled
                                    font.pixelSize: Appearance.fontSizeXS
                                    font.weight: Font.Bold
                                }

                                Repeater {
                                    model: PluginService.visibleControlCenterPlugins

                                    delegate: Loader {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        source: (modelData.path || "") + (modelData.entryPoints && modelData.entryPoints.controlCenterWidget ? modelData.entryPoints.controlCenterWidget : "")

                                        onStatusChanged: {
                                            if (status === Loader.Error)
                                                Logger.w("ControlCenter", "failed to load control-center plugin widget " + modelData.id + " from " + source);
                                            if (status === Loader.Ready && item) {
                                                var api = PluginService.getPluginAPI(modelData.id);
                                                if (api && item.hasOwnProperty("pluginApi"))
                                                    item.pluginApi = api;
                                                if (item.hasOwnProperty("pluginManifest"))
                                                    item.pluginManifest = modelData;
                                                if (item.hasOwnProperty("pluginService"))
                                                    item.pluginService = PluginService;
                                                if (item.hasOwnProperty("controlCenterRoot"))
                                                    item.controlCenterRoot = root;
                                                if (item.hasOwnProperty("manager"))
                                                    item.manager = root.manager;
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // --- Command Center Widgets (data-driven, user-ordered) ---
                        Repeater {
                            model: ControlCenterRegistry.visibleWidgetItems

                            delegate: Loader {
                                id: widgetLoader
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true

                                readonly property int animIndex: 5 + index
                                source: root.widgetSource(modelData.id)
                                active: true

                                opacity: root.entranceOpacity(animIndex)
                                scale: root.entranceScale(animIndex)
                                transform: Translate { y: root.entranceY(animIndex) }
                                layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                                Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(animIndex) } NumberAnimation { duration: root.entranceDuration(animIndex); easing.type: Easing.OutCubic } } }
                                Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(animIndex) } NumberAnimation { duration: root.entranceDuration(animIndex); easing.type: Easing.OutBack } } }

                                onLoaded: {
                                    if (!item) return;
                                    // Inject common properties where supported
                                    if (item.hasOwnProperty("showContent"))
                                        item.showContent = Qt.binding(function() { return root.showContent; });
                                    if (item.hasOwnProperty("showSystemMonitorLauncher"))
                                        item.showSystemMonitorLauncher = true;
                                    if (item.hasOwnProperty("baseIndex"))
                                        item.baseIndex = Qt.binding(function() { return widgetLoader.animIndex; });
                                    if (item.hasOwnProperty("staggerDelay"))
                                        item.staggerDelay = root.staggerDelay;
                                    // DevOpsSection menu routing
                                    if (item.hasOwnProperty("menuRequested"))
                                        item.menuRequested.connect(function(surfaceId, surfaceContext) {
                                            root.requestSurfaceAfterClose(surfaceId, surfaceContext);
                                        });
                                }
                            }
                        }
                    }
                }

                SharedWidgets.Scrollbar {
                    flickable: ccFlick
                }
                SharedWidgets.OverscrollGlow {
                    flickable: ccFlick
                }
            }
        }
    }
}
