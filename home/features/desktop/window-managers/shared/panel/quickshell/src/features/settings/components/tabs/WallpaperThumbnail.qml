import QtQuick
import "../../../../services"
import "../../../../shared"
import "../../../../widgets" as SharedWidgets

Item {
    id: thumbDelegate
    required property var modelData
    required property int index
    required property string selectedMonitor
    required property var unsupportedImagePaths
    required property bool compactMode

    signal wallpaperSelected(string path)
    signal imageUnsupported(string path)

    readonly property string activePath: {
        var key = selectedMonitor || "__all__";
        return WallpaperService.wallpapers[key] || WallpaperService.wallpapers["__all__"] || "";
    }
    readonly property bool isActive: modelData.path === activePath

    width: compactMode ? 92 : 108
    height: compactMode ? 72 : 80
    scale: 1.0

    SequentialAnimation {
        id: thumbPulse
        NumberAnimation {
            target: thumbDelegate
            property: "scale"
            to: 0.92
            duration: Appearance.durationSnap
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: thumbDelegate
            property: "scale"
            to: 1.0
            duration: Appearance.durationSnap
            easing.type: Easing.OutQuad
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radiusSmall
        color: isActive ? Colors.highlight : Colors.bgWidget
        border.color: isActive ? Colors.primary : Colors.border
        border.width: isActive ? 2 : 1
        clip: true

        Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }
        Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }

        SharedWidgets.WallpaperThumbImage {
            id: thumbImage
            anchors.fill: parent
            imagePath: modelData.path
            fileMtime: modelData.mtime || 0
            unsupportedMap: unsupportedImagePaths
            opacity: status === Image.Ready ? 1.0 : 0.0
            onImageUnsupported: path => thumbDelegate.imageUnsupported(path)
            Behavior on opacity {
                NumberAnimation { duration: Appearance.durationNormal }
            }
        }

        SharedWidgets.SvgIcon {
            anchors.centerIn: parent
            source: "image.svg"
            color: Colors.textDisabled
            size: Appearance.fontSizeHuge
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

            SharedWidgets.SvgIcon {
                anchors.centerIn: parent
                source: "checkmark.svg"
                color: Colors.text
                size: Appearance.fontSizeXS
            }
        }

        Rectangle {
            anchors.fill: parent
            color: thumbMouse.containsMouse ? Qt.rgba(0, 0, 0, 0.35) : "transparent"
            Behavior on color {
                enabled: !Colors.isTransitioning
                ColorAnimation { duration: Appearance.durationSnap }
            }
        }

        Text {
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: Appearance.spacingXS
            }
            text: modelData.filename
            color: "#ffffff"
            font.pixelSize: Appearance.fontSizeXS
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
                thumbDelegate.wallpaperSelected(modelData.path);
            }
        }
    }
}
