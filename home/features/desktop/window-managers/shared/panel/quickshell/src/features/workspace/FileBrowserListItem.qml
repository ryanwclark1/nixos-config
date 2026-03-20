import QtQuick
import QtQuick.Layouts
import "../../services"
import "FileBrowserHelpers.js" as FBH

Rectangle {
    id: root

    required property var modelData
    required property int index
    required property string selectedFile
    required property string browseMode
    required property bool showDetailColumns

    signal itemClicked(var entry)
    signal itemDoubleClicked(var entry)

    width: parent ? parent.width : 0
    height: Appearance.controlRowHeight

    color: {
        var isSel = (selectedFile === modelData.path);
        if (isSel) return Colors.primaryMarked;
        if (listItemHover.containsMouse) return Colors.textFaint;
        return index % 2 === 0 ? "transparent" : Colors.cardSurface;
    }
    Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationSnap } }

    // bottom separator
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Colors.borderMedium
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.spacingM
        anchors.rightMargin: Appearance.spacingM
        spacing: Appearance.spacingM

        // Icon
        Item {
            width: 22; height: 22

            Image {
                anchors.fill: parent
                visible: modelData.isImage
                source: modelData.isImage ? ("file://" + modelData.path) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 22
                sourceSize.height: 22
                cache: true
            }

            Text {
                anchors.centerIn: parent
                visible: !modelData.isImage
                text: FBH.fileIcon(modelData)
                color: modelData.isDir ? Colors.accent : Colors.textSecondary
                font.family: Appearance.fontMono
                font.pixelSize: Appearance.fontSizeLarge
            }
        }

        // Name
        Text {
            Layout.fillWidth: true
            text: modelData.name
            color: Colors.text
            font.pixelSize: Appearance.fontSizeMedium
            elide: Text.ElideRight
        }

        // Size
        Text {
            Layout.preferredWidth: 80
            text: modelData.isDir ? "—" : FBH.formatSize(modelData.size)
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeSmall
            horizontalAlignment: Text.AlignRight
        }

        // Date
        Text {
            visible: root.showDetailColumns
            Layout.preferredWidth: root.showDetailColumns ? 100 : 0
            text: FBH.formatDate(modelData.mtime)
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeSmall
            horizontalAlignment: Text.AlignRight
        }

        // Extension / type
        Text {
            visible: root.showDetailColumns
            Layout.preferredWidth: root.showDetailColumns ? 60 : 0
            text: modelData.isDir ? "folder" : (modelData.extension || "—")
            color: Colors.textDisabled
            font.pixelSize: Appearance.fontSizeSmall
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: listItemHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton

        onClicked: root.itemClicked(modelData)
        onDoubleClicked: root.itemDoubleClicked(modelData)
    }
}
