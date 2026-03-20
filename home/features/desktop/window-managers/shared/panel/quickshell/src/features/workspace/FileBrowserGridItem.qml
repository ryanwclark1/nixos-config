import QtQuick
import QtQuick.Layouts
import "../../services"
import "FileBrowserHelpers.js" as FBH

Rectangle {
    id: root

    required property var modelData
    required property int index
    required property real cellWidth
    required property string selectedFile
    required property string browseMode

    signal itemClicked(var entry)
    signal itemDoubleClicked(var entry)

    width: cellWidth
    height: cellWidth + 28

    radius: Colors.radiusSmall
    color: {
        var isSel = (selectedFile === modelData.path);
        if (isSel) return Colors.withAlpha(Colors.primary, 0.28);
        if (gridItemHover.containsMouse) return Colors.textWash;
        return "transparent";
    }
    Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Colors.durationSnap } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingXS
        spacing: Colors.spacingXS

        // Icon area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Image {
                anchors.fill: parent
                anchors.margins: Colors.spacingXS
                visible: modelData.isImage
                source: modelData.isImage ? ("file://" + modelData.path) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 120
                sourceSize.height: 120
                cache: true
                smooth: true
                mipmap: true

                Rectangle {
                    anchors.fill: parent
                    radius: Colors.radiusSmall - 4
                    color: "transparent"
                    border.color: Colors.withAlpha(Colors.border, 0.5)
                    border.width: 1
                    clip: true
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !modelData.isImage
                text: FBH.fileIcon(modelData)
                color: modelData.isDir ? Colors.accent : Colors.textSecondary
                font.family: Colors.fontMono
                font.pixelSize: root.cellWidth < 80 ? 28 : 36
            }
        }

        // Filename
        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text: modelData.name
            color: Colors.text
            font.pixelSize: Colors.fontSizeSmall
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    MouseArea {
        id: gridItemHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton

        drag.target: modelData.isDir ? null : dragRect
        drag.axis: Drag.XAndYAxis

        onClicked: root.itemClicked(modelData)
        onDoubleClicked: root.itemDoubleClicked(modelData)
    }

    // Hidden proxy for dragging
    Rectangle {
        id: dragRect
        visible: Drag.active
        width: 48; height: 48; radius: Colors.radiusXS
        color: Colors.primary
        opacity: 0.8
        z: 999

        Drag.active: gridItemHover.drag.active
        Drag.source: ({ type: "file", path: modelData.path, name: modelData.name, isImage: modelData.isImage })
        Drag.hotSpot.x: 24; Drag.hotSpot.y: 24

        Text {
            anchors.centerIn: parent
            text: FBH.fileIcon(modelData)
            color: "white"; font.pixelSize: Colors.iconSizeSmall; font.family: Colors.fontMono
        }
    }
}
