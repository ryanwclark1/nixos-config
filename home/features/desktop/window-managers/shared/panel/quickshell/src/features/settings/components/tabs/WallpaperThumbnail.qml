import QtQuick
import "../../../../services"
import "../../../../shared"
import "../../../../widgets" as SharedWidgets
import "WallpaperTabHelpers.js" as WTH

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
            duration: Colors.durationSnap
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: thumbDelegate
            property: "scale"
            to: 1.0
            duration: Colors.durationSnap
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

        Behavior on border.color { CAnim {} }
        Behavior on color { CAnim {} }

        Image {
            id: thumbImage
            anchors.fill: parent
            source: WTH.imageSource(modelData.path, unsupportedImagePaths)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            cache: false
            sourceSize: Qt.size(216, 160)
            opacity: status === Image.Ready ? 1.0 : 0.0
            onStatusChanged: {
                if (status === Image.Error)
                    thumbDelegate.imageUnsupported(modelData.path);
            }
            Behavior on opacity {
                NumberAnimation { duration: Colors.durationNormal }
            }
        }

        Text {
            anchors.centerIn: parent
            text: "󰸉"
            color: Colors.textDisabled
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
                ColorAnimation { duration: Colors.durationSnap }
            }
        }

        Text {
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: Colors.spacingXS
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
                thumbDelegate.wallpaperSelected(modelData.path);
            }
        }
    }
}
