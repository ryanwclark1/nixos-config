import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../menu"
import "../../services"
import "../../widgets" as SharedWidgets

BasePopupMenu {
    id: root
    popupMinWidth: 260; popupMaxWidth: 300; compactThreshold: 280
    implicitHeight: 280
    title: "Screenshot"

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
                color: mouseArea.containsMouse ? Colors.primarySubtle : Colors.cardSurface
                border.color: mouseArea.containsMouse ? Colors.primary : Colors.border
                border.width: 1

                SharedWidgets.InnerHighlight { hoveredOpacity: 0.25; hovered: mouseArea.containsMouse }

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
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1
            clip: true

            // Inner highlight
            SharedWidgets.InnerHighlight { }

            Image {
                anchors.fill: parent
                source: ScreenshotService.lastScreenshotPath ? ("file://" + ScreenshotService.lastScreenshotPath) : ""
                sourceSize: Qt.size(400, 300)
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
