import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets

Rectangle {
    id: root
    Layout.fillWidth: true

    required property var modelData
    required property bool isActive
    property bool actionPending: false

    signal actionClicked()

    implicitHeight: 56
    radius: Appearance.radiusMedium
    color: Colors.cardSurface
    border.color: Colors.border
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.spacingM
        anchors.rightMargin: Appearance.spacingM
        spacing: Appearance.spacingS

        SharedWidgets.SvgIcon {
            source: "wifi-off.svg"
            color: root.isActive ? Colors.accent : Colors.textSecondary
            size: Appearance.fontSizeLarge
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingXXS

            Text {
                text: root.modelData.name || "VPN"
                color: Colors.text
                font.pixelSize: Appearance.fontSizeMedium
                font.weight: Font.Medium
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: root.isActive
                    ? (root.modelData.device !== "" ? (root.modelData.type + " • " + root.modelData.device) : root.modelData.type)
                    : (root.modelData.type || "vpn")
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeXS
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        Rectangle {
            readonly property color actionColor: root.isActive ? Colors.error : Colors.primary
            radius: Appearance.radiusPill
            color: root.actionPending
                ? Colors.withAlpha(Colors.textSecondary, 0.12)
                : (root.isActive ? Colors.withAlpha(Colors.error, 0.12) : Colors.primaryAccent)
            border.color: root.actionPending ? Colors.border : actionColor
            border.width: 1
            implicitHeight: 28
            implicitWidth: actionLabel.implicitWidth + 20

            Text {
                id: actionLabel
                anchors.centerIn: parent
                text: root.actionPending
                    ? (root.isActive ? "Disconnecting" : "Connecting")
                    : (root.isActive ? "Disconnect" : "Connect")
                color: root.actionPending ? Colors.textSecondary : parent.actionColor
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.DemiBold
            }

            MouseArea {
                anchors.fill: parent
                enabled: !root.actionPending && NetworkService.pendingVpnProfileUuid === ""
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.BusyCursor
                onClicked: root.actionClicked()
            }
        }
    }
}
