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
    property bool showContent: false
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

            property string _quickLinkSurfaceId: ""
            Timer {
                id: openQuickLinkTimer
                interval: root.settingsOpenDelayMs
                repeat: false
                onTriggered: {
                    if (parent._quickLinkSurfaceId)
                        Quickshell.execDetached(SU.ipcCall("Shell", "openSurface", parent._quickLinkSurfaceId, ""));
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

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacingS
                                visible: Config.controlCenterShowQuickLinks

                                Repeater {
                                    model: ControlCenterRegistry.quickLinkItems
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
                                                _quickLinkSurfaceId = surfaceId;
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

                        // --- Group 2: Active Session ---
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacingLG
                            opacity: root.entranceOpacity(1)
                            scale: root.entranceScale(1)
                            transform: Translate { y: root.entranceY(1) }
                            layer.enabled: opacity > 0 && opacity < 1
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(5) } NumberAnimation { duration: root.entranceDuration(1); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(5) } NumberAnimation { duration: root.entranceDuration(1); easing.type: Easing.OutBack } } }

                            MediaWidget {
                                Layout.fillWidth: true
                            }

                            // Pomodoro Timer
                            PomodoroWidget {
                                Layout.fillWidth: true
                                visible: Config.controlCenterShowPomodoro && opacity > 0
                            }

                            // Todo List
                            TodoWidget {
                                Layout.fillWidth: true
                                visible: Config.controlCenterShowTodo && opacity > 0
                            }

                            // DevOps & Services
                            DevOpsSection {
                                visible: Config.controlCenterShowDevOps
                                showContent: root.showContent
                                baseIndex: 10
                                staggerDelay: root.staggerDelay
                            }
                        }

                        // --- Group 3: System Controls ---
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacingLG
                            opacity: root.entranceOpacity(2)
                            scale: root.entranceScale(2)
                            transform: Translate { y: root.entranceY(2) }
                            layer.enabled: opacity > 0 && opacity < 1
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(10) } NumberAnimation { duration: root.entranceDuration(2); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(10) } NumberAnimation { duration: root.entranceDuration(2); easing.type: Easing.OutBack } } }

                            // Sliders
                            ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.paddingMedium
                            opacity: root.entranceOpacity(7)
                            scale: root.entranceScale(7)
                            transform: Translate { y: root.entranceY(7) }
                            visible: (Config.controlCenterShowBrightness || Config.controlCenterShowAudioOutput || Config.controlCenterShowAudioInput) && opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(7) } NumberAnimation { duration: root.entranceDuration(7); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(7) } NumberAnimation { duration: root.entranceDuration(7); easing.type: Easing.OutBack } } }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacingSM
                                visible: Config.controlCenterShowBrightness

                                Repeater {
                                    model: BrightnessService.monitors
                                    delegate: ColumnLayout {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        spacing: Appearance.spacingSM
                                        RowLayout {
                                            Layout.fillWidth: true
                                            SharedWidgets.SvgIcon {
                                                source: "weather-sunny.svg"
                                                color: Colors.textDisabled
                                                size: Appearance.fontSizeXS
                                            }
                                            Text {
                                                text: BrightnessService.hasMultipleMonitors
                                                    ? modelData.name.toUpperCase() : "BRIGHTNESS"
                                                color: Colors.textDisabled
                                                font.pixelSize: Appearance.fontSizeXS
                                                font.weight: Font.Bold
                                            }
                                            Item { Layout.fillWidth: true }
                                            Text {
                                                text: modelData.available
                                                    ? Math.round(modelData.brightness * 100) + "%" : "Unavailable"
                                                color: modelData.available ? Colors.textSecondary : Colors.warning
                                                font.pixelSize: Appearance.fontSizeXS
                                            }
                                        }
                                        SharedWidgets.SliderTrack {
                                            Layout.fillWidth: true
                                            value: modelData.brightness
                                            icon: "weather-sunny.svg"
                                            enabled: modelData.available
                                            opacity: enabled ? 1.0 : 0.4
                                            onSliderMoved: v => BrightnessService.setBrightness(
                                                modelData.name, Math.max(0.01, v))
                                        }
                                    }
                                }

                                Text {
                                    visible: BrightnessService.monitors.length === 0
                                    text: "No brightness devices detected"
                                    color: Colors.textDisabled
                                    font.pixelSize: Appearance.fontSizeXS
                                    Layout.fillWidth: true
                                }

                                // Keyboard backlight slider
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.spacingSM
                                    visible: BrightnessService.kbdAvailable

                                    RowLayout {
                                        Layout.fillWidth: true
                                        SharedWidgets.SvgIcon {
                                            source: "keyboard.svg"
                                            color: Colors.textDisabled
                                            size: Appearance.fontSizeXS
                                        }
                                        Text {
                                            text: "KEYBOARD"
                                            color: Colors.textDisabled
                                            font.pixelSize: Appearance.fontSizeXS
                                            font.weight: Font.Bold
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: Math.round(BrightnessService.kbdDevice.brightness * 100) + "%"
                                            color: Colors.textSecondary
                                            font.pixelSize: Appearance.fontSizeXS
                                        }
                                    }
                                    SharedWidgets.SliderTrack {
                                        Layout.fillWidth: true
                                        value: BrightnessService.kbdDevice.brightness
                                        icon: "keyboard.svg"
                                        onSliderMoved: v => BrightnessService.setKbdBrightness(v)
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacingSM
                                visible: Config.controlCenterShowAudioOutput
                                RowLayout {
                                    Layout.fillWidth: true
                                    SharedWidgets.SvgIcon {
                                        source: "speaker.svg"
                                        color: Colors.textDisabled
                                        size: Appearance.fontSizeXS
                                    }
                                    Text {
                                        text: "OUTPUT"
                                        color: Colors.textDisabled
                                        font.pixelSize: Appearance.fontSizeXS
                                        font.weight: Font.Bold
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                    }
                                    SharedWidgets.NumericText {
                                        text: AudioService.outputMuted ? "Muted" : Math.round(AudioService.outputVolume * 100) + "%"
                                        color: Colors.textSecondary
                                        font.pixelSize: Appearance.fontSizeXS
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.paddingSmall
                                    SharedWidgets.MuteButton {
                                        target: "@DEFAULT_AUDIO_SINK@"
                                        muted: AudioService.outputMuted
                                        icon: "speaker.svg"
                                        mutedIcon: "speaker-mute.svg"
                                        size: Appearance.iconSizeMedium
                                        showBorder: true
                                    }
                                    SharedWidgets.SliderTrack {
                                        Layout.fillWidth: true
                                        value: AudioService.outputVolume
                                        muted: AudioService.outputMuted
                                        icon: "speaker.svg"
                                        mutedIcon: "speaker-mute.svg"
                                        onSliderMoved: v => AudioService.setVolume("@DEFAULT_AUDIO_SINK@", v)
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacingSM
                                visible: Config.controlCenterShowAudioInput
                                RowLayout {
                                    Layout.fillWidth: true
                                    SharedWidgets.SvgIcon {
                                        source: "mic.svg"
                                        color: Colors.textDisabled
                                        size: Appearance.fontSizeXS
                                    }
                                    Text {
                                        text: "INPUT"
                                        color: Colors.textDisabled
                                        font.pixelSize: Appearance.fontSizeXS
                                        font.weight: Font.Bold
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                    }
                                    SharedWidgets.NumericText {
                                        text: AudioService.inputMuted ? "Muted" : Math.round(AudioService.inputVolume * 100) + "%"
                                        color: Colors.textSecondary
                                        font.pixelSize: Appearance.fontSizeXS
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.paddingSmall
                                    SharedWidgets.MuteButton {
                                        target: "@DEFAULT_AUDIO_SOURCE@"
                                        muted: AudioService.inputMuted
                                        icon: "mic.svg"
                                        mutedIcon: "mic-off.svg"
                                        size: Appearance.iconSizeMedium
                                        showBorder: true
                                    }
                                    SharedWidgets.SliderTrack {
                                        Layout.fillWidth: true
                                        value: AudioService.inputVolume
                                        muted: AudioService.inputMuted
                                        icon: "mic.svg"
                                        mutedIcon: "mic-off.svg"
                                        onSliderMoved: v => AudioService.setVolume("@DEFAULT_AUDIO_SOURCE@", v)
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacingM
                            opacity: root.entranceOpacity(8)
                            scale: root.entranceScale(8)
                            transform: Translate { y: root.entranceY(8) }
                            visible: Config.controlCenterShowCpuGpuTemp && opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(8) } NumberAnimation { duration: root.entranceDuration(8); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(8) } NumberAnimation { duration: root.entranceDuration(8); easing.type: Easing.OutBack } } }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 60
                                color: Colors.bgWidget
                                radius: Appearance.radiusSmall
                                border.color: Colors.border
                                border.width: 1
                                Column {
                                    anchors.centerIn: parent
                                    spacing: Appearance.spacingXXS
                                    Text {
                                        text: "CPU TEMP"
                                        color: Colors.textDisabled
                                        font.pixelSize: Appearance.fontSizeXS
                                        font.weight: Font.Bold
                                    }
                                    Text {
                                        text: SystemStatus.cpuTemp
                                        color: Colors.primary
                                        font.pixelSize: Appearance.fontSizeLarge
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 60
                                color: Colors.bgWidget
                                radius: Appearance.radiusSmall
                                border.color: Colors.border
                                border.width: 1
                                Column {
                                    anchors.centerIn: parent
                                    spacing: Appearance.spacingXXS
                                    Text {
                                        text: "GPU TEMP"
                                        color: Colors.textDisabled
                                        font.pixelSize: Appearance.fontSizeXS
                                        font.weight: Font.Bold
                                    }
                                    Text {
                                        text: SystemStatus.gpuTemp
                                        color: Colors.accent
                                        font.pixelSize: Appearance.fontSizeLarge
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                        }

                        CpuWidget {
                            opacity: root.entranceOpacity(9)
                            scale: root.entranceScale(9)
                            transform: Translate { y: root.entranceY(9) }
                            visible: Config.controlCenterShowCpuWidget && opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(9) } NumberAnimation { duration: root.entranceDuration(9); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(9) } NumberAnimation { duration: root.entranceDuration(9); easing.type: Easing.OutBack } } }
                        }
                        SystemGraphs {
                            opacity: root.entranceOpacity(9)
                            scale: root.entranceScale(9)
                            transform: Translate { y: root.entranceY(9) }
                            visible: Config.controlCenterShowSystemGraphs && opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(9) } NumberAnimation { duration: root.entranceDuration(9); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(9) } NumberAnimation { duration: root.entranceDuration(9); easing.type: Easing.OutBack } } }
                        }
                        ProcessWidget {
                            opacity: root.entranceOpacity(10)
                            scale: root.entranceScale(10)
                            transform: Translate { y: root.entranceY(10) }
                            visible: Config.controlCenterShowProcessWidget && opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(10) } NumberAnimation { duration: root.entranceDuration(10); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(10) } NumberAnimation { duration: root.entranceDuration(10); easing.type: Easing.OutBack } } }
                        }
                        NetworkGraphs {
                            opacity: root.entranceOpacity(11)
                            scale: root.entranceScale(11)
                            transform: Translate { y: root.entranceY(11) }
                            visible: Config.controlCenterShowNetworkGraphs && opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(11) } NumberAnimation { duration: root.entranceDuration(11); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(11) } NumberAnimation { duration: root.entranceDuration(11); easing.type: Easing.OutBack } } }
                        }
                        RamWidget {
                            opacity: root.entranceOpacity(12)
                            scale: root.entranceScale(12)
                            transform: Translate { y: root.entranceY(12) }
                            visible: Config.controlCenterShowRamWidget && opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(12) } NumberAnimation { duration: root.entranceDuration(12); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(12) } NumberAnimation { duration: root.entranceDuration(12); easing.type: Easing.OutBack } } }
                        }
                        DiskWidget {
                            opacity: root.entranceOpacity(13)
                            scale: root.entranceScale(13)
                            transform: Translate { y: root.entranceY(13) }
                            visible: Config.controlCenterShowDiskWidget && opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(13) } NumberAnimation { duration: root.entranceDuration(13); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(13) } NumberAnimation { duration: root.entranceDuration(13); easing.type: Easing.OutBack } } }
                        }
                        GPUWidget {
                            opacity: root.entranceOpacity(14)
                            scale: root.entranceScale(14)
                            transform: Translate { y: root.entranceY(14) }
                            visible: Config.controlCenterShowGpuWidget && opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(14) } NumberAnimation { duration: root.entranceDuration(14); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(14) } NumberAnimation { duration: root.entranceDuration(14); easing.type: Easing.OutBack } } }
                        }
                        UpdateWidget {
                            opacity: root.entranceOpacity(15)
                            scale: root.entranceScale(15)
                            transform: Translate { y: root.entranceY(15) }
                            visible: Config.controlCenterShowUpdateWidget && opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(15) } NumberAnimation { duration: root.entranceDuration(15); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(15) } NumberAnimation { duration: root.entranceDuration(15); easing.type: Easing.OutBack } } }
                        }
                        ScratchpadWidget {
                            opacity: root.entranceOpacity(16)
                            scale: root.entranceScale(16)
                            transform: Translate { y: root.entranceY(16) }
                            visible: Config.controlCenterShowScratchpad && opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(16) } NumberAnimation { duration: root.entranceDuration(16); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(16) } NumberAnimation { duration: root.entranceDuration(16); easing.type: Easing.OutBack } } }
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

            PowerActionsRow {
                visible: Config.controlCenterShowPowerActions
                showContent: root.showContent
                baseIndex: 17
                staggerDelay: root.staggerDelay
            }
        }
    }
}
