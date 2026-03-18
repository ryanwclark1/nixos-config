import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets
import "LauncherModeData.js" as ModeData

Rectangle {
    id: root

    required property bool tightMode
    required property string mode
    required property real parentRadius

    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: tightMode ? 34 : 44
    radius: parentRadius
    color: Colors.withAlpha(Colors.surface, 0.98)
    border.color: Colors.border
    border.width: 1

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Colors.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.tightMode ? Colors.spacingS : Colors.spacingM
        anchors.rightMargin: root.tightMode ? Colors.spacingS : Colors.spacingM
        spacing: root.tightMode ? Colors.spacingXS : Colors.spacingS

        Row {
            spacing: Colors.spacingS
            Repeater {
                model: [Qt.rgba(0.98, 0.36, 0.31, 0.9), Qt.rgba(0.96, 0.74, 0.28, 0.9), Qt.rgba(0.18, 0.8, 0.44, 0.9)]
                delegate: Rectangle {
                    required property color modelData
                    width: 12
                    height: 12
                    radius: width / 2
                    color: modelData
                    opacity: 0.9
                    SharedWidgets.InnerHighlight { highlightOpacity: 0.2 }
                }
            }
        }

        Item { Layout.preferredWidth: Colors.spacingS }

        Text {
            text: "Launcher"
            color: Colors.text
            font.pixelSize: root.tightMode ? Colors.fontSizeSmall : Colors.fontSizeMedium
            font.weight: Font.Black
            font.capitalization: Font.AllUppercase
            font.letterSpacing: Colors.letterSpacingWide
        }

        Rectangle {
            radius: Colors.radiusPill
            color: Colors.primaryMarked
            border.color: Colors.withAlpha(Colors.primary, 0.35)
            border.width: 1
            implicitHeight: root.tightMode ? 22 : 24
            implicitWidth: chromeModeLabel.implicitWidth + 16

            Text {
                id: chromeModeLabel
                anchors.centerIn: parent
                text: ModeData.modeInfo(root.mode).label
                color: Colors.primary
                font.pixelSize: Colors.fontSizeXXS
                font.weight: Font.Black
                font.capitalization: Font.AllUppercase
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Text {
            visible: !root.tightMode
            text: "V3.0"
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXXS
            font.weight: Font.Black
        }
    }
}
