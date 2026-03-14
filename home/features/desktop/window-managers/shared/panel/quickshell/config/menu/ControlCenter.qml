import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland
import Quickshell.Widgets
import "."
import "../modules"
import "../services"
import "../widgets" as SharedWidgets

PanelWindow {
    id: root

    property string surfaceEdge: "right"
    property int panelWidth: Config.controlCenterWidth
    property int panelHeight: 640
    property real panelX: 0
    readonly property var edgeMargins: Config.reservedEdgesForScreen(screen, "")
    property int reservedTop: edgeMargins.top
    property int reservedRight: edgeMargins.right
    property int reservedBottom: edgeMargins.bottom
    property int reservedLeft: edgeMargins.left
    anchors {
        top: surfaceEdge === "right" || surfaceEdge === "left" || surfaceEdge === "top"
        right: surfaceEdge === "right"
        bottom: surfaceEdge === "right" || surfaceEdge === "left" || surfaceEdge === "bottom"
        left: surfaceEdge === "left" || surfaceEdge === "top" || surfaceEdge === "bottom"
    }
    margins.top: surfaceEdge === "right" || surfaceEdge === "left" || surfaceEdge === "top" ? reservedTop : 0
    margins.right: surfaceEdge === "right" ? reservedRight : 0
    margins.bottom: surfaceEdge === "right" || surfaceEdge === "left" || surfaceEdge === "bottom" ? reservedBottom : 0
    margins.left: surfaceEdge === "left" ? reservedLeft : ((surfaceEdge === "top" || surfaceEdge === "bottom") ? panelX : 0)

    implicitWidth: panelWidth
    implicitHeight: surfaceEdge === "top" || surfaceEdge === "bottom" ? panelHeight : 0
    color: "transparent"
    mask: Region {
        item: sidebarContent
    }
    WlrLayershell.layer: WlrLayer.Top
    // Command center has no text inputs; keep keyboard with focused app (e.g. Ghostty).
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell"

    property var manager: null
    property bool showContent: false
    property int pendingPowerIndex: -1
    signal closeRequested

    onShowContentChanged: {
        if (!showContent) {
            if (sidebarContent.activeFocus)
                sidebarContent.focus = false;
        }
    }

    Timer {
        id: powerConfirmTimer
        interval: 3000
        onTriggered: root.pendingPowerIndex = -1
    }
    visible: showContent || ccSlideAnim.running || ccFadeAnim.running

    SharedWidgets.Ref {
        service: AudioService
    }
    Loader {
        active: root.showContent
        sourceComponent: SharedWidgets.Ref {
            service: SystemStatus
        }
    }
    Loader {
        active: root.showContent
        sourceComponent: SharedWidgets.Ref {
            service: RecordingService
        }
    }
    Loader {
        active: root.showContent
        sourceComponent: SharedWidgets.Ref {
            service: BrightnessService
        }
    }

    Rectangle {
        id: sidebarContent
        width: root.panelWidth
        height: root.surfaceEdge === "top" || root.surfaceEdge === "bottom" ? root.panelHeight : parent.height
        color: Colors.bgGlass
        border.color: Colors.border
        border.width: 1
        radius: Colors.radiusLarge
        x: {
            if (root.surfaceEdge === "right")
                return root.showContent ? 0 : root.panelWidth + 10;
            if (root.surfaceEdge === "left")
                return root.showContent ? 0 : -root.panelWidth - 10;
            return 0;
        }
        y: {
            if (root.surfaceEdge === "top")
                return root.showContent ? 0 : -height - 10;
            if (root.surfaceEdge === "bottom")
                return root.showContent ? 0 : height + 10;
            return 0;
        }
        opacity: root.showContent ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on x {
            NumberAnimation {
                id: ccSlideAnim
                duration: Colors.durationSlow
                easing.type: Easing.OutCubic
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: Colors.durationSlow
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                id: ccFadeAnim
                duration: Colors.durationNormal
            }
        }
        layer.enabled: ccSlideAnim.running || ccFadeAnim.running

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
                    font.letterSpacing: -0.5
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
                        Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "toggle"]);
                    }
                }
                SharedWidgets.IconButton {
                    icon: "󰅖"
                    size: 32
                    iconSize: Colors.fontSizeXL
                    onClicked: root.closeRequested()
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
                        spacing: Colors.spacingLG

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingS
                            visible: Config.controlCenterShowQuickLinks

                            Repeater {
                                model: ControlCenterRegistry.quickLinkItems
                                delegate: QuickLinkCard {
                                    required property var modelData
                                    icon: modelData.icon
                                    title: modelData.title
                                    subtitle: modelData.subtitle
                                    clickCommand: modelData.clickCommand
                                }
                            }
                        }

                        UserWidget {
                            opacity: root.showContent ? 1 : 0
                            visible: opacity > 0
                            scale: root.showContent ? 1 : 0.95
                            layer.enabled: opacity > 0 && opacity < 1
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 400
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 400
                                    easing.type: Easing.OutBack
                                }
                            }
                        }

                        // Quick Toggles Grid
                        GridLayout {
                            columns: 2
                            Layout.fillWidth: true
                            rowSpacing: 10
                            columnSpacing: 10
                            opacity: root.showContent ? 1 : 0
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 450
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Repeater {
                                model: ControlCenterRegistry.visibleQuickToggleItems
                                delegate: QuickToggle {
                                    required property var modelData
                                    icon: modelData.icon
                                    label: modelData.label
                                    active: modelData.id === "recording" ? RecordingService.isRecording : ControlCenterRegistry.quickToggleActive(modelData.id, root.manager)
                                    onClicked: {
                                        if (modelData.id === "recording") {
                                            if (RecordingService.isRecording)
                                                RecordingService.stopRecording();
                                            else
                                                RecordingService.startRecording("fullscreen");
                                        } else {
                                            ControlCenterRegistry.toggleQuickToggle(modelData.id, root.manager);
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingS
                            visible: PluginService.visibleControlCenterPlugins.length > 0
                            opacity: root.showContent ? 1 : 0
                            layer.enabled: opacity > 0 && opacity < 1
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 480
                                    easing.type: Easing.OutCubic
                                }
                            }

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
                            opacity: root.showContent ? 1 : 0
                            layer.enabled: opacity > 0 && opacity < 1
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 500
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        // Sliders
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Colors.paddingMedium
                            opacity: root.showContent ? 1 : 0
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 550
                                    easing.type: Easing.OutCubic
                                }
                            }

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
                            opacity: root.showContent ? 1 : 0
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 600
                                    easing.type: Easing.OutCubic
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
                            opacity: root.showContent ? 1 : 0
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 650
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                        ProcessWidget {
                            opacity: root.showContent ? 1 : 0
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 700
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                        NetworkGraphs {
                            opacity: root.showContent ? 1 : 0
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 750
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                        DiskWidget {
                            opacity: root.showContent ? 1 : 0
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 800
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                        GPUWidget {
                            opacity: root.showContent ? 1 : 0
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 850
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                        UpdateWidget {
                            opacity: root.showContent ? 1 : 0
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 900
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                        ScratchpadWidget {
                            opacity: root.showContent ? 1 : 0
                            visible: opacity > 0
                            layer.enabled: opacity > 0 && opacity < 1
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 950
                                    easing.type: Easing.OutCubic
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

            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.paddingSmall
                Repeater {
                    model: [
                        {
                            icon: "󰐥",
                            cmd: ["systemctl", "poweroff"],
                            confirm: true
                        },
                        {
                            icon: "󰑐",
                            cmd: ["systemctl", "reboot"],
                            confirm: true
                        },
                        {
                            icon: "󰌾",
                            cmd: CompositorAdapter.lockCommand(),
                            confirm: false
                        }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        height: 40
                        color: root.pendingPowerIndex === index ? Colors.error : Colors.surface
                        radius: Colors.radiusXS
                        Behavior on color {
                            ColorAnimation {
                                duration: Colors.durationFast
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.pendingPowerIndex === index ? "Confirm?" : modelData.icon
                            color: root.pendingPowerIndex === index ? Colors.background : Colors.text
                            font.family: root.pendingPowerIndex === index ? undefined : Colors.fontMono
                            font.pixelSize: root.pendingPowerIndex === index ? Colors.fontSizeSmall : Colors.fontSizeXL
                            font.weight: root.pendingPowerIndex === index ? Font.Bold : Font.Normal
                        }

                        SharedWidgets.StateLayer {
                            id: powerStateLayer
                            hovered: powerHover.containsMouse
                            pressed: powerHover.pressed
                        }

                        MouseArea {
                            id: powerHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                powerStateLayer.burst(mouse.x, mouse.y);
                                if (!modelData.confirm) {
                                    // Lock doesn't need confirmation
                                    Quickshell.execDetached(modelData.cmd);
                                    return;
                                }
                                if (root.pendingPowerIndex === index) {
                                    Quickshell.execDetached(modelData.cmd);
                                    root.pendingPowerIndex = -1;
                                    powerConfirmTimer.stop();
                                } else {
                                    root.pendingPowerIndex = index;
                                    powerConfirmTimer.restart();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component QuickLinkCard: Rectangle {
        property string icon
        property string title
        property string subtitle
        property var clickCommand: []

        Layout.fillWidth: true
        implicitHeight: 68
        radius: Colors.radiusMedium
        color: Colors.bgWidget
        border.color: Colors.border
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: Colors.spacingM
            spacing: Colors.spacingM

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: height / 2
                color: Colors.withAlpha(Colors.primary, 0.12)

                Text {
                    anchors.centerIn: parent
                    text: icon
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXL
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: title
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: subtitle
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            Text {
                text: "󰄮"
                color: Colors.textSecondary
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeMedium
            }
        }

        SharedWidgets.StateLayer {
            id: stateLayer
            hovered: quickLinkHover.containsMouse
            pressed: quickLinkHover.pressed
        }

        MouseArea {
            id: quickLinkHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                stateLayer.burst(mouse.x, mouse.y);
                Quickshell.execDetached(clickCommand);
            }
        }
    }
}
