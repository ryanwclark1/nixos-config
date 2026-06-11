import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../shared"
import "../../../services"
import "../../../widgets" as SharedWidgets

Rectangle {
    id: root

    property var camera: null
    property string snapshotUrl: ""

    signal viewStreamRequested(var camera)

    Layout.fillWidth: true
    implicitHeight: cardLayout.implicitHeight + 20
    radius: Appearance.radiusMedium
    color: Colors.cardSurface
    border.color: Colors.border
    border.width: 1

    ColumnLayout {
        id: cardLayout
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Appearance.spacingM
        }
        spacing: Appearance.spacingS

        // ── Snapshot thumbnail ──────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            radius: Appearance.radiusSmall
            color: Colors.surfaceContainerLow
            clip: true
            visible: root.snapshotUrl !== "" || root.camera && root.camera.state === "CONNECTED"

            Image {
                id: snapshotImage
                anchors.fill: parent
                source: root.snapshotUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                visible: status === Image.Ready
            }

            // Placeholder when no snapshot yet
            SharedWidgets.SvgIcon {
                anchors.centerIn: parent
                source: "camera.svg"
                color: Colors.textDisabled
                size: 32
                visible: snapshotImage.status !== Image.Ready
            }

            // Click to view stream
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.camera) root.viewStreamRequested(root.camera);
                }
            }

            // Play button overlay
            Rectangle {
                anchors.centerIn: parent
                width: 40
                height: 40
                radius: 20
                color: Qt.rgba(0, 0, 0, 0.6)
                visible: snapshotImage.status === Image.Ready

                SharedWidgets.SvgIcon {
                    anchors.centerIn: parent
                    source: "play.svg"
                    color: "white"
                    size: 20
                }
            }
        }

        // ── Camera info ─────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SharedWidgets.SvgIcon {
                source: "camera.svg"
                color: root.camera && root.camera.state === "CONNECTED" ? Colors.primary : Colors.textDisabled
                size: Appearance.fontSizeLarge
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingXXS

                Text {
                    text: root.camera ? UnifiProtectService.cameraDisplayName(root.camera) : "Unknown"
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeMedium
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: Appearance.spacingS
                    Layout.fillWidth: true

                    Text {
                        text: root.camera ? UnifiProtectService.cameraStatusText(root.camera) : ""
                        color: root.camera && root.camera.state === "CONNECTED" ? Colors.primary : Colors.textDisabled
                        font.pixelSize: Appearance.fontSizeXXS
                        font.weight: Font.Bold
                    }

                    Text {
                        text: root.camera && root.camera.marketName ? String(root.camera.marketName) : ""
                        color: Colors.textDisabled
                        font.pixelSize: Appearance.fontSizeXXS
                        visible: text !== ""
                    }
                }
            }
        }
    }
}
