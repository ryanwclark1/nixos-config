import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "WallpaperTabHelpers.js" as WTH

Rectangle {
    id: previewContainer
    required property string selectedMonitor
    required property var unsupportedImagePaths

    signal imageUnsupported(string path)

    Layout.fillWidth: true
    height: 160
    radius: Colors.radiusMedium
    color: Colors.bgWidget
    border.color: Colors.border
    border.width: 1
    clip: true

    readonly property string previewPath: {
        var key = selectedMonitor || "__all__";
        return WallpaperService.wallpapers[key] || WallpaperService.wallpapers["__all__"] || "";
    }
    readonly property string _previewMonitor: selectedMonitor === "__all__" ? "" : selectedMonitor
    readonly property string solidHex: WallpaperService.solidColorForMonitor(_previewMonitor)
    readonly property bool solidPreview: solidHex.length > 0

    property bool _previewFlip: false

    onPreviewPathChanged: {
        if (!previewPath || unsupportedImagePaths[previewPath]) {
            previewA.source = "";
            previewB.source = "";
            return;
        }
        var src = WTH.imageSource(previewPath, unsupportedImagePaths);
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
                duration: Colors.durationEmphasis
                easing.type: Easing.InOutQuad
            }
        }
        onStatusChanged: {
            if (status === Image.Ready && previewContainer._previewFlip) {
                previewContainer._previewFlip = false;
            } else if (status === Image.Error && previewPath.length > 0) {
                previewContainer.imageUnsupported(previewPath);
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
                duration: Colors.durationEmphasis
                easing.type: Easing.InOutQuad
            }
        }
        onStatusChanged: {
            if (status === Image.Ready && !previewContainer._previewFlip) {
                previewContainer._previewFlip = true;
            } else if (status === Image.Error && previewPath.length > 0) {
                previewContainer.imageUnsupported(previewPath);
                source = "";
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Colors.spacingS
        visible: !previewContainer.solidPreview
            && (previewContainer.previewPath === "" || (previewA.status !== Image.Ready && previewB.status !== Image.Ready))

        Text {
            text: "󰸉"
            color: Colors.textDisabled
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeHuge
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            text: previewContainer.previewPath !== "" ? "Loading preview…" : "No wallpaper set"
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeMedium
            Layout.alignment: Qt.AlignHCenter
        }
    }

    Rectangle {
        anchors.centerIn: parent
        visible: previewContainer.solidPreview
        width: Math.min(previewContainer.width - Colors.spacingM * 4, 220)
        height: 96
        radius: Colors.radiusMedium
        color: "#" + previewContainer.solidHex.slice(0, 6)
        border.color: Colors.border
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "Solid #" + previewContainer.solidHex.slice(0, 6).toUpperCase()
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            font.weight: Font.Medium
        }
    }

    Rectangle {
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: Colors.spacingM
        }
        visible: previewContainer.previewPath !== "" || previewContainer.solidPreview
        width: Math.min(previewContainer.width - Colors.spacingM * 2, previewName.implicitWidth + 16)
        height: 22
        radius: Colors.radiusPill
        color: Qt.rgba(0, 0, 0, 0.55)

        Text {
            id: previewName
            anchors.centerIn: parent
            text: {
                var p = previewContainer.previewPath;
                if (previewContainer.solidPreview)
                    return "Solid #" + previewContainer.solidHex.slice(0, 6).toUpperCase();
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
