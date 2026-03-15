import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
    id: root
    popupMinWidth: 260; popupMaxWidth: 300; compactThreshold: 280
    implicitHeight: 280
    title: "Screenshot"
    toggleMethod: "toggleScreenshotMenu"

    // ── Mode buttons ─────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingS

        SharedWidgets.SectionLabel { label: "CAPTURE MODE" }

        Repeater {
            model: [
                { mode: "region", icon: "󰩭", label: "Select Region", desc: "Draw a rectangle to capture" },
                { mode: "screen", icon: "󰍹", label: "Current Screen", desc: "Capture the active monitor" },
                { mode: "fullscreen", icon: "󰹑", label: "All Screens", desc: "Capture everything" }
            ]
            delegate: Rectangle {
                Layout.fillWidth: true
                implicitHeight: 48
                radius: Colors.radiusMedium
                color: mouseArea.containsMouse ? Colors.withAlpha(Colors.primary, 0.12) : Colors.withAlpha(Colors.surface, 0.35)
                border.color: mouseArea.containsMouse ? Colors.primary : Colors.border
                border.width: 1

                // Inner highlight
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: parent.radius - 1
                    color: "transparent"
                    border.color: Colors.borderLight
                    border.width: 1
                    opacity: mouseArea.containsMouse ? 0.25 : 0.1
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Colors.spacingM
                    spacing: Colors.spacingM

                    Text {
                        text: modelData.icon
                        color: Colors.primary
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeXL
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: modelData.label
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeMedium
                            font.weight: Font.Medium
                        }

                        Text {
                            text: modelData.desc
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeXS
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.closeRequested();
                        if (modelData.mode === "region")
                            ScreenshotService.captureRegion();
                        else if (modelData.mode === "screen")
                            ScreenshotService.captureScreen("");
                        else
                            ScreenshotService.captureFullscreen();
                    }
                }
            }
        }
    }

    // ── Recent screenshot ────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingS
        visible: ScreenshotService.lastScreenshotPath !== ""

        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: Colors.radiusXS
            color: Colors.withAlpha(Colors.surface, 0.5)
            border.color: Colors.border
            border.width: 1
            clip: true

            // Inner highlight
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: parent.radius - 1
                color: "transparent"
                border.color: Colors.borderLight
                border.width: 1
                opacity: 0.1
            }

            Image {
                anchors.fill: parent
                source: ScreenshotService.lastScreenshotPath ? ("file://" + ScreenshotService.lastScreenshotPath) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Text {
            text: "Last capture"
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeSmall
            Layout.fillWidth: true
        }

        SharedWidgets.IconButton {
            icon: "󰉋"
            iconSize: Colors.fontSizeLarge
            onClicked: ScreenshotService.openScreenshotsFolder()
        }
    }
}
