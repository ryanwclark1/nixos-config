import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../services"
import "../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""

    property string wallpaperSelectedMonitor: ""
    property var wallpaperMonitorNames: []
    property string wallpaperFolderInput: Config.wallpaperDefaultFolder
    property string wallpaperFolderError: ""
    property var _unsupportedImagePaths: ({})

    function isWallpaperFolderPathValid(path) {
        var p = (path || "").trim();
        return p.length > 0 && (p.indexOf("/") === 0 || p === "~" || p.indexOf("~/") === 0);
    }

    function applyWallpaperFolder() {
        var trimmed = (wallpaperFolderInput || "").trim();
        if (!isWallpaperFolderPathValid(trimmed)) {
            wallpaperFolderError = "Use an absolute path, ~, or ~/path.";
            return;
        }
        wallpaperFolderError = "";
        Config.wallpaperDefaultFolder = trimmed;
        WallpaperService.scanWallpapers();
    }

    function _imageSource(path) {
        if (!path || _unsupportedImagePaths[path])
            return "";
        return "file://" + path;
    }

    function _markUnsupportedImage(path) {
        if (!path || _unsupportedImagePaths[path])
            return;
        _unsupportedImagePaths[path] = true;
        _unsupportedImagePaths = Object.assign({}, _unsupportedImagePaths);
    }

    Process {
        id: wallpaperMonProc
        command: ["hyprctl", "monitors", "-j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var mons = JSON.parse(this.text || "[]");
                    var names = [];
                    for (var i = 0; i < mons.length; i++) {
                        if (mons[i].name)
                            names.push(mons[i].name);
                    }
                    root.wallpaperMonitorNames = names;
                    if (root.wallpaperSelectedMonitor === "" && names.length > 0)
                        root.wallpaperSelectedMonitor = names[0];
                } catch (e) {
                    console.error("Failed to parse hyprctl monitors: " + e);
                }
            }
        }
    }

    Component.onCompleted: {
        if (!wallpaperMonProc.running)
            wallpaperMonProc.running = true;
        if (WallpaperService.availableWallpapers.length === 0)
            WallpaperService.scanWallpapers();
    }

    Connections {
        target: Config
        function onWallpaperDefaultFolderChanged() {
            root.wallpaperFolderInput = Config.wallpaperDefaultFolder;
            root.wallpaperFolderError = "";
        }
    }

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Wallpaper"
        iconName: "󰸉"

        // Monitor selector (shown only when >1 monitor)
        ColumnLayout {
            visible: root.wallpaperMonitorNames.length > 1
            spacing: Colors.spacingS
            Layout.fillWidth: true

            SettingsSectionLabel {
                text: "MONITOR"
            }

            Flow {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                SharedWidgets.FilterChip {
                    label: "All"
                    selected: root.wallpaperSelectedMonitor === "__all__"
                    onClicked: root.wallpaperSelectedMonitor = "__all__"
                }

                Repeater {
                    model: root.wallpaperMonitorNames
                    delegate: SharedWidgets.FilterChip {
                        required property string modelData
                        label: modelData
                        selected: root.wallpaperSelectedMonitor === modelData
                        onClicked: root.wallpaperSelectedMonitor = modelData
                    }
                }
            }
        }

        // Current wallpaper preview
        SettingsSectionLabel {
            text: "CURRENT WALLPAPER"
        }

        Rectangle {
            id: previewContainer
            Layout.fillWidth: true
            height: 160
            radius: Colors.radiusMedium
            color: Colors.bgWidget
            border.color: Colors.border
            border.width: 1
            clip: true

            readonly property string previewPath: {
                var key = root.wallpaperSelectedMonitor || "__all__";
                return WallpaperService.wallpapers[key] || WallpaperService.wallpapers["__all__"] || "";
            }

            property bool _previewFlip: false

            onPreviewPathChanged: {
                if (!previewPath || root._unsupportedImagePaths[previewPath]) {
                    previewA.source = "";
                    previewB.source = "";
                    return;
                }
                var src = root._imageSource(previewPath);
                if (_previewFlip) {
                    previewA.previewPath = previewPath;
                    previewA.source = src;
                } else {
                    previewB.previewPath = previewPath;
                    previewB.source = src;
                }
            }

            Image {
                id: previewA
                property string previewPath: ""
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                sourceSize: Qt.size(previewContainer.width * 2, previewContainer.height * 2)
                opacity: previewContainer._previewFlip ? 0.0 : 1.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.InOutQuad
                    }
                }
                onStatusChanged: {
                    if (status === Image.Ready && previewContainer._previewFlip) {
                        previewContainer._previewFlip = false;
                    } else if (status === Image.Error && previewPath.length > 0) {
                        root._markUnsupportedImage(previewPath);
                        source = "";
                    }
                }
            }

            Image {
                id: previewB
                property string previewPath: ""
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                sourceSize: Qt.size(previewContainer.width * 2, previewContainer.height * 2)
                opacity: previewContainer._previewFlip ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.InOutQuad
                    }
                }
                onStatusChanged: {
                    if (status === Image.Ready && !previewContainer._previewFlip) {
                        previewContainer._previewFlip = true;
                    } else if (status === Image.Error && previewPath.length > 0) {
                        root._markUnsupportedImage(previewPath);
                        source = "";
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Colors.spacingS
                visible: previewContainer.previewPath === "" || (previewA.status !== Image.Ready && previewB.status !== Image.Ready)

                Text {
                    text: "󰸉"
                    color: Colors.fgDim
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeHuge
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: previewContainer.previewPath !== "" ? "Loading preview…" : "No wallpaper set"
                    color: Colors.fgDim
                    font.pixelSize: Colors.fontSizeMedium
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            Rectangle {
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                    margins: Colors.spacingM
                }
                visible: previewContainer.previewPath !== ""
                implicitWidth: previewName.implicitWidth + 16
                height: 22
                radius: Colors.radiusPill
                color: Qt.rgba(0, 0, 0, 0.55)

                Text {
                    id: previewName
                    anchors.centerIn: parent
                    text: {
                        var p = previewContainer.previewPath;
                        if (!p)
                            return "";
                        var parts = p.split("/");
                        return parts[parts.length - 1];
                    }
                    color: "#ffffff"
                    font.pixelSize: Colors.fontSizeXS
                    font.family: Colors.fontMono
                    elide: Text.ElideLeft
                    maximumLineCount: 1
                }
            }
        }

        // Quick action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingM

            Repeater {
                model: [
                    {
                        icon: "󰒭",
                        label: "Next",
                        action: "next"
                    },
                    {
                        icon: "󰒝",
                        label: "Random",
                        action: "random"
                    },
                    {
                        icon: "󰝰",
                        label: "Open Folder",
                        action: "folder"
                    },
                    {
                        icon: "󰉋",
                        label: "Browse...",
                        action: "browse"
                    }
                ]

                delegate: SettingsActionButton {
                    Layout.fillWidth: true
                    label: modelData.label
                    iconName: modelData.icon
                    onClicked: {
                        var mon = root.wallpaperSelectedMonitor === "__all__" ? "" : root.wallpaperSelectedMonitor;
                        if (modelData.action === "next")
                            WallpaperService.nextWallpaper(mon);
                        else if (modelData.action === "random")
                            WallpaperService.randomWallpaper(mon);
                        else if (modelData.action === "folder")
                            WallpaperService.openWallpaperFolder();
                        else if (modelData.action === "browse" && root.settingsRoot)
                            root.settingsRoot.browseWallpaper(mon);
                    }
                }
            }
        }

        // Settings
        SettingsSectionLabel {
            text: "SETTINGS"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            SettingsTextInputRow {
                id: wallpaperFolderField
                Layout.fillWidth: true
                label: "Default wallpaper folder"
                placeholderText: "~/.config/wallpapers"
                leadingIcon: "󰉋"
                text: root.wallpaperFolderInput
                errorText: root.wallpaperFolderError
                onTextEdited: value => root.wallpaperFolderInput = value
                onSubmitted: root.applyWallpaperFolder()

                SettingsActionButton {
                    label: "Apply"
                    compact: true
                    emphasized: true
                    onClicked: root.applyWallpaperFolder()
                }

                SettingsActionButton {
                    label: "Pick Folder"
                    compact: true
                    onClicked: if (root.settingsRoot)
                        root.settingsRoot.pickWallpaperFolder()
                }
            }
        }

        SettingsFieldGrid {
            SettingsToggleRow {
                visible: !Config.themeName
                label: "Run pywal on change"
                icon: "󰏘"
                configKey: "wallpaperRunPywal"
            }
        }

        // Auto-cycle interval slider
        ColumnLayout {
            spacing: Colors.spacingM
            Layout.fillWidth: true

            RowLayout {
                Text {
                    text: "Auto-Cycle Interval"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Font.Medium
                }
                Item {
                    Layout.fillWidth: true
                }
                Text {
                    text: Config.wallpaperCycleInterval === 0 ? "Off" : Config.wallpaperCycleInterval + " min"
                    color: Colors.fgSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    font.family: Colors.fontMono
                }
            }

            Item {
                Layout.fillWidth: true
                height: 24

                Rectangle {
                    id: cycleTrack
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 6
                    color: Colors.surface
                    radius: 3

                    Rectangle {
                        width: parent.width * (Config.wallpaperCycleInterval / 60)
                        height: parent.height
                        color: Config.wallpaperCycleInterval > 0 ? Colors.primary : Colors.border
                        radius: 3
                        Behavior on width {
                            NumberAnimation {
                                duration: 100
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                    }
                }

                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    color: Config.wallpaperCycleInterval > 0 ? Colors.primary : Colors.border
                    border.color: Colors.bgWidget
                    border.width: 2
                    x: Math.max(0, Math.min(parent.width - width, parent.width * (Config.wallpaperCycleInterval / 60) - width / 2))
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on x {
                        NumberAnimation {
                            duration: 100
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.topMargin: -4
                    anchors.bottomMargin: -4
                    cursorShape: Qt.PointingHandCursor
                    function updateCycle(mouse) {
                        var raw = (mouse.x / width) * 60;
                        if (raw < 2) {
                            Config.wallpaperCycleInterval = 0;
                            return;
                        }
                        var snapped = Math.round(raw / 5) * 5;
                        Config.wallpaperCycleInterval = Math.max(5, Math.min(60, snapped));
                    }
                    onPressed: mouse => updateCycle(mouse)
                    onPositionChanged: mouse => {
                        if (pressed)
                            updateCycle(mouse);
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Off"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                }
                Item {
                    Layout.fillWidth: true
                }
                Text {
                    text: "60 min"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                }
            }
        }

        // Wallpaper grid
        SettingsSectionLabel {
            text: WallpaperService.scanning ? "SCANNING…" : ("WALLPAPERS  (" + WallpaperService.availableWallpapers.length + ")")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingM
            visible: !WallpaperService.scanning

            SharedWidgets.EmptyState {
                visible: WallpaperService.availableWallpapers.length === 0
                icon: "󰸉"
                message: "No wallpapers found in search directories"
                Layout.fillWidth: true
            }

            Item {
                Layout.fillWidth: true
                visible: WallpaperService.availableWallpapers.length > 0
            }

            SettingsActionButton {
                label: "Rescan"
                iconName: "󰑐"
                compact: true
                onClicked: WallpaperService.scanWallpapers()
            }
        }

        ColumnLayout {
            visible: WallpaperService.scanning
            Layout.fillWidth: true
            spacing: Colors.spacingS

            SharedWidgets.LoadingSpinner {
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: "Scanning directories…"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeMedium
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Flow {
            visible: !WallpaperService.scanning && WallpaperService.availableWallpapers.length > 0
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Repeater {
                model: WallpaperService.availableWallpapers

                delegate: Item {
                    id: thumbDelegate
                    required property var modelData
                    required property int index

                    readonly property string activePath: {
                        var key = root.wallpaperSelectedMonitor || "__all__";
                        return WallpaperService.wallpapers[key] || WallpaperService.wallpapers["__all__"] || "";
                    }
                    readonly property bool isActive: modelData.path === activePath

                    width: 108
                    height: 80
                    scale: 1.0

                    SequentialAnimation {
                        id: thumbPulse
                        NumberAnimation {
                            target: thumbDelegate
                            property: "scale"
                            to: 0.92
                            duration: 100
                            easing.type: Easing.InQuad
                        }
                        NumberAnimation {
                            target: thumbDelegate
                            property: "scale"
                            to: 1.0
                            duration: 100
                            easing.type: Easing.OutQuad
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Colors.radiusSmall
                        color: isActive ? Colors.highlight : Colors.bgWidget
                        border.color: isActive ? Colors.primary : Colors.border
                        border.width: isActive ? 2 : 1
                        clip: true

                        Behavior on border.color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        Image {
                            id: thumbImage
                            anchors.fill: parent
                            source: root._imageSource(modelData.path)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                            cache: false
                            sourceSize: Qt.size(216, 160)
                            opacity: status === Image.Ready ? 1.0 : 0.0
                            onStatusChanged: {
                                if (status === Image.Error)
                                    root._markUnsupportedImage(modelData.path);
                            }
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰸉"
                            color: Colors.fgDim
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeHuge
                            visible: thumbImage.status !== Image.Ready
                        }

                        Rectangle {
                            anchors {
                                top: parent.top
                                right: parent.right
                                margins: 5
                            }
                            visible: isActive
                            width: 18
                            height: 18
                            radius: height / 2
                            color: Colors.primary

                            Text {
                                anchors.centerIn: parent
                                text: "󰄬"
                                color: Colors.text
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeXS
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: thumbMouse.containsMouse ? Qt.rgba(0, 0, 0, 0.35) : "transparent"
                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }
                        }

                        Text {
                            anchors {
                                bottom: parent.bottom
                                left: parent.left
                                right: parent.right
                                margins: 4
                            }
                            text: modelData.filename
                            color: "#ffffff"
                            font.pixelSize: Colors.fontSizeXS
                            elide: Text.ElideLeft
                            visible: thumbMouse.containsMouse
                        }

                        MouseArea {
                            id: thumbMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                thumbPulse.restart();
                                var mon = root.wallpaperSelectedMonitor === "__all__" ? "" : root.wallpaperSelectedMonitor;
                                WallpaperService.setWallpaper(modelData.path, mon);
                            }
                        }
                    }
                }
            }
        }

        // Info callout
        SettingsInfoCallout {
            iconName: "󰋗"
            title: "Wallpaper search directories"
            body: "Requires swww, hyprctl hyprpaper, or swaybg to apply wallpapers."

            Repeater {
                model: WallpaperService.wallpaperSearchDirs
                delegate: Text {
                    required property string modelData
                    text: "  " + modelData
                    color: Colors.fgSecondary
                    font.pixelSize: Colors.fontSizeXS
                    font.family: Colors.fontMono
                    Layout.fillWidth: true
                    elide: Text.ElideLeft
                }
            }
        }
    }
}
