import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "."
import "../system/sections"
import "../services"
import "../widgets" as SharedWidgets

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

    margins.top: reservedTop + Colors.spacingS
    margins.right: reservedRight + Colors.spacingS
    margins.bottom: reservedBottom + Colors.spacingS

    implicitWidth: panelWidth + 20 // Extra room for shadow/animation
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-control-center"

    property var manager: null
    property bool showContent: false
    readonly property int maxLayerTextureSize: 4096
    readonly property int staggerDelay: 35
    readonly property int settingsOpenDelayMs: 130
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
        return Colors.durationSlow
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

    visible: showContent || ccSlideAnim.running || ccFadeAnim.running

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
        radius: Colors.radiusLarge
        clip: true

        // Slide animation from right
        transform: Translate {
            x: root.showContent ? 0 : root.panelWidth + 40
            Behavior on x {
                NumberAnimation {
                    id: ccSlideAnim
                    duration: Colors.durationSlow
                    easing.type: Easing.OutQuint
                }
            }
        }

        opacity: root.showContent ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                id: ccFadeAnim
                duration: Colors.durationNormal
            }
        }

        SharedWidgets.InnerHighlight { highlightOpacity: 0.12 }
        SharedWidgets.SurfaceGradient {}

        Keys.onEscapePressed: root.closeRequested()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.paddingLarge
            spacing: Colors.spacingXL
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Command Center"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeHuge
                    font.weight: Font.DemiBold
                    font.letterSpacing: Colors.letterSpacingTight
                }
                Item {
                    Layout.fillWidth: true
                }
                SharedWidgets.IconButton {
                    icon: "󰒓"
                    size: 32
                    iconSize: Colors.fontSizeXL
                    onClicked: {
                        root.closeRequested();
                        openSettingsTimer.restart();
                    }
                }
                SharedWidgets.IconButton {
                    icon: "󰅖"
                    size: 32
                    iconSize: Colors.fontSizeXL
                    onClicked: root.closeRequested()
                }
            }

            Timer {
                id: openSettingsTimer
                interval: root.settingsOpenDelayMs
                repeat: false
                onTriggered: Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "open"])
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
                        spacing: Colors.spacingLG

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingS
                            visible: Config.controlCenterShowQuickLinks
                            opacity: root.entranceOpacity(0)
                            scale: root.entranceScale(0)
                            transform: Translate { y: root.entranceY(0) }
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(0) } NumberAnimation { duration: root.entranceDuration(0); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(0) } NumberAnimation { duration: root.entranceDuration(0); easing.type: Easing.OutBack } } }

                            Repeater {
                                model: ControlCenterRegistry.quickLinkItems
                                delegate: QuickLinkCard {
                                    icon: modelData.icon
                                    title: modelData.title
                                    subtitle: modelData.subtitle
                                    clickCommand: modelData.clickCommand
                                }
                            }
                        }

                        UserWidget {
                            opacity: root.entranceOpacity(1)
                            scale: root.entranceScale(1)
                            transform: Translate { y: root.entranceY(1) }
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(1) } NumberAnimation { duration: root.entranceDuration(1); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(1) } NumberAnimation { duration: root.entranceDuration(1); easing.type: Easing.OutBack } } }
                        }

                        // Quick Toggles Grid
                        QuickToggleGrid {
                            manager: root.manager
                            showContent: root.showContent
                            baseIndex: 2
                            staggerDelay: root.staggerDelay
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingS
                            visible: PluginService.visibleControlCenterPlugins.length > 0
                            opacity: root.entranceOpacity(3)
                            scale: root.entranceScale(3)
                            transform: Translate { y: root.entranceY(3) }
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(3) } NumberAnimation { duration: root.entranceDuration(3); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(3) } NumberAnimation { duration: root.entranceDuration(3); easing.type: Easing.OutBack } } }

                            Text {
                                text: "PLUGINS"
                                color: Colors.textDisabled
                                font.pixelSize: Colors.fontSizeXS
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
                                            console.warn("ControlCenter: failed to load control-center plugin widget " + modelData.id + " from " + source);
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

                        MediaWidget {
                            opacity: root.entranceOpacity(4)
                            scale: root.entranceScale(4)
                            transform: Translate { y: root.entranceY(4) }
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(4) } NumberAnimation { duration: root.entranceDuration(4); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(4) } NumberAnimation { duration: root.entranceDuration(4); easing.type: Easing.OutBack } } }
                        }

                        // DevOps & Services
                        DevOpsSection {
                            showContent: root.showContent
                            baseIndex: 15
                            staggerDelay: root.staggerDelay
                        }

                        // Sliders
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Colors.paddingMedium
                            opacity: root.entranceOpacity(5)
                            scale: root.entranceScale(5)
                            transform: Translate { y: root.entranceY(5) }
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(5) } NumberAnimation { duration: root.entranceDuration(5); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(5) } NumberAnimation { duration: root.entranceDuration(5); easing.type: Easing.OutBack } } }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Colors.spacingSM

                                Repeater {
                                    model: BrightnessService.monitors
                                    delegate: ColumnLayout {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        spacing: Colors.spacingSM
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text {
                                                text: "󰃠  " + (BrightnessService.hasMultipleMonitors
                                                    ? modelData.name.toUpperCase() : "BRIGHTNESS")
                                                color: Colors.textDisabled
                                                font.pixelSize: Colors.fontSizeXS
                                                font.weight: Font.Bold
                                            }
                                            Item { Layout.fillWidth: true }
                                            Text {
                                                text: modelData.available
                                                    ? Math.round(modelData.brightness * 100) + "%" : "Unavailable"
                                                color: modelData.available ? Colors.textSecondary : Colors.warning
                                                font.pixelSize: Colors.fontSizeXS
                                            }
                                        }
                                        SharedWidgets.SliderTrack {
                                            Layout.fillWidth: true
                                            value: modelData.brightness
                                            icon: "󰃠"
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
                                    font.pixelSize: Colors.fontSizeXS
                                    Layout.fillWidth: true
                                }

                                // Keyboard backlight slider
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Colors.spacingSM
                                    visible: BrightnessService.kbdAvailable

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "󰌌  KEYBOARD"
                                            color: Colors.textDisabled
                                            font.pixelSize: Colors.fontSizeXS
                                            font.weight: Font.Bold
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: Math.round(BrightnessService.kbdDevice.brightness * 100) + "%"
                                            color: Colors.textSecondary
                                            font.pixelSize: Colors.fontSizeXS
                                        }
                                    }
                                    SharedWidgets.SliderTrack {
                                        Layout.fillWidth: true
                                        value: BrightnessService.kbdDevice.brightness
                                        icon: "󰌌"
                                        onSliderMoved: v => BrightnessService.setKbdBrightness(v)
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Colors.spacingSM
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "󰕾  OUTPUT"
                                        color: Colors.textDisabled
                                        font.pixelSize: Colors.fontSizeXS
                                        font.weight: Font.Bold
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: AudioService.outputMuted ? "Muted" : Math.round(AudioService.outputVolume * 100) + "%"
                                        color: Colors.textSecondary
                                        font.pixelSize: Colors.fontSizeXS
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Colors.paddingSmall
                                    SharedWidgets.MuteButton {
                                        target: "@DEFAULT_AUDIO_SINK@"
                                        muted: AudioService.outputMuted
                                        icon: "󰕾"
                                        mutedIcon: "󰝟"
                                        size: 32
                                        showBorder: true
                                    }
                                    SharedWidgets.SliderTrack {
                                        Layout.fillWidth: true
                                        value: AudioService.outputVolume
                                        muted: AudioService.outputMuted
                                        icon: "󰕾"
                                        mutedIcon: "󰝟"
                                        onSliderMoved: v => AudioService.setVolume("@DEFAULT_AUDIO_SINK@", v)
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Colors.spacingSM
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "󰍬  INPUT"
                                        color: Colors.textDisabled
                                        font.pixelSize: Colors.fontSizeXS
                                        font.weight: Font.Bold
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: AudioService.inputMuted ? "Muted" : Math.round(AudioService.inputVolume * 100) + "%"
                                        color: Colors.textSecondary
                                        font.pixelSize: Colors.fontSizeXS
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Colors.paddingSmall
                                    SharedWidgets.MuteButton {
                                        target: "@DEFAULT_AUDIO_SOURCE@"
                                        muted: AudioService.inputMuted
                                        icon: "󰍬"
                                        mutedIcon: "󰍭"
                                        size: 32
                                        showBorder: true
                                    }
                                    SharedWidgets.SliderTrack {
                                        Layout.fillWidth: true
                                        value: AudioService.inputVolume
                                        muted: AudioService.inputMuted
                                        icon: "󰍬"
                                        mutedIcon: "󰍭"
                                        onSliderMoved: v => AudioService.setVolume("@DEFAULT_AUDIO_SOURCE@", v)
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingM
                            opacity: root.entranceOpacity(6)
                            scale: root.entranceScale(6)
                            transform: Translate { y: root.entranceY(6) }
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(6) } NumberAnimation { duration: root.entranceDuration(6); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(6) } NumberAnimation { duration: root.entranceDuration(6); easing.type: Easing.OutBack } } }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 60
                                color: Colors.bgWidget
                                radius: Colors.radiusSmall
                                border.color: Colors.border
                                border.width: 1
                                Column {
                                    anchors.centerIn: parent
                                    spacing: Colors.spacingXXS
                                    Text {
                                        text: "CPU TEMP"
                                        color: Colors.textDisabled
                                        font.pixelSize: Colors.fontSizeXS
                                        font.weight: Font.Bold
                                    }
                                    Text {
                                        text: SystemStatus.cpuTemp
                                        color: Colors.primary
                                        font.pixelSize: Colors.fontSizeLarge
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 60
                                color: Colors.bgWidget
                                radius: Colors.radiusSmall
                                border.color: Colors.border
                                border.width: 1
                                Column {
                                    anchors.centerIn: parent
                                    spacing: Colors.spacingXXS
                                    Text {
                                        text: "GPU TEMP"
                                        color: Colors.textDisabled
                                        font.pixelSize: Colors.fontSizeXS
                                        font.weight: Font.Bold
                                    }
                                    Text {
                                        text: SystemStatus.gpuTemp
                                        color: Colors.accent
                                        font.pixelSize: Colors.fontSizeLarge
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                        }

                        SystemGraphs {
                            opacity: root.entranceOpacity(7)
                            scale: root.entranceScale(7)
                            transform: Translate { y: root.entranceY(7) }
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(7) } NumberAnimation { duration: root.entranceDuration(7); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(7) } NumberAnimation { duration: root.entranceDuration(7); easing.type: Easing.OutBack } } }
                        }
                        ProcessWidget {
                            opacity: root.entranceOpacity(8)
                            scale: root.entranceScale(8)
                            transform: Translate { y: root.entranceY(8) }
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(8) } NumberAnimation { duration: root.entranceDuration(8); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(8) } NumberAnimation { duration: root.entranceDuration(8); easing.type: Easing.OutBack } } }
                        }
                        NetworkGraphs {
                            opacity: root.entranceOpacity(9)
                            scale: root.entranceScale(9)
                            transform: Translate { y: root.entranceY(9) }
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(9) } NumberAnimation { duration: root.entranceDuration(9); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(9) } NumberAnimation { duration: root.entranceDuration(9); easing.type: Easing.OutBack } } }
                        }
                        DiskWidget {
                            opacity: root.entranceOpacity(10)
                            scale: root.entranceScale(10)
                            transform: Translate { y: root.entranceY(10) }
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(10) } NumberAnimation { duration: root.entranceDuration(10); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(10) } NumberAnimation { duration: root.entranceDuration(10); easing.type: Easing.OutBack } } }
                        }
                        GPUWidget {
                            opacity: root.entranceOpacity(11)
                            scale: root.entranceScale(11)
                            transform: Translate { y: root.entranceY(11) }
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(11) } NumberAnimation { duration: root.entranceDuration(11); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(11) } NumberAnimation { duration: root.entranceDuration(11); easing.type: Easing.OutBack } } }
                        }
                        UpdateWidget {
                            opacity: root.entranceOpacity(12)
                            scale: root.entranceScale(12)
                            transform: Translate { y: root.entranceY(12) }
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(12) } NumberAnimation { duration: root.entranceDuration(12); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(12) } NumberAnimation { duration: root.entranceDuration(12); easing.type: Easing.OutBack } } }
                        }
                        ScratchpadWidget {
                            opacity: root.entranceOpacity(13)
                            scale: root.entranceScale(13)
                            transform: Translate { y: root.entranceY(13) }
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1 && root.allowLayer(width, height)
                            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(13) } NumberAnimation { duration: root.entranceDuration(13); easing.type: Easing.OutCubic } } }
                            Behavior on scale { SequentialAnimation { PauseAnimation { duration: root.entranceDelay(13) } NumberAnimation { duration: root.entranceDuration(13); easing.type: Easing.OutBack } } }
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
                showContent: root.showContent
                baseIndex: 14
                staggerDelay: root.staggerDelay
            }
        }
    }
}
