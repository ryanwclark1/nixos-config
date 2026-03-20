import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../../shared" as Shared
import "../../../widgets" as SharedWidgets

Rectangle {
    id: root
    property string icon
    property string title
    property string subtitle
    property var clickCommand: []
    property var clickAction: null

    Layout.fillWidth: true
    implicitHeight: 68
    radius: Appearance.radiusMedium
    color: Colors.bgWidget
    border.color: Colors.border
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: Appearance.spacingM
        spacing: Appearance.spacingM

        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: height / 2
            color: Colors.primarySubtle

            Loader {
                anchors.centerIn: parent
                sourceComponent: String(root.icon).endsWith(".svg") ? _qlSvg : _qlNerd
            }
            Component { id: _qlSvg; Shared.SvgIcon { source: root.icon; color: Colors.primary; size: Appearance.fontSizeXL } }
            Component { id: _qlNerd; Text { text: root.icon; color: Colors.primary; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeXL } }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: title
                color: Colors.text
                font.pixelSize: Appearance.fontSizeMedium
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: subtitle
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeXS
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        SharedWidgets.SvgIcon {
            source: "arrow-up-left.svg"
            color: Colors.textSecondary
            size: Appearance.fontSizeMedium
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
            if (typeof root.clickAction === "function")
                root.clickAction();
            else if (Array.isArray(root.clickCommand) && root.clickCommand.length > 0)
                Quickshell.execDetached(root.clickCommand);
        }
    }
}
