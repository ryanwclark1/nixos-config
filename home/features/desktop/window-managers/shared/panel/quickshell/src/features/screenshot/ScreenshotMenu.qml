import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../shared"
import "../../services"
import "../../widgets" as SharedWidgets

BasePopupMenu {
    id: root
    popupMinWidth: 280; popupMaxWidth: 320; compactThreshold: 300
    implicitHeight: contentCol.implicitHeight + 40
    title: "Screenshot"

    readonly property var _historyModel: {
        var hist = Config.screenshotHistory || [];
        return hist.slice(0, 5);
    }

    function _relativeTime(ts) {
        if (!ts) return "";
        var diff = Math.floor((Date.now() - ts) / 1000);
        if (diff < 60) return "Just now";
        if (diff < 3600) return Math.floor(diff / 60) + "m ago";
        if (diff < 86400) return Math.floor(diff / 3600) + "h ago";
        return Math.floor(diff / 86400) + "d ago";
    }

    function _modeLabel(mode) {
        var labels = { region: "Region", window: "Window", screen: "Screen", fullscreen: "All screens", area: "Area" };
        return labels[mode] || mode;
    }

    ColumnLayout {
        id: contentCol
        Layout.fillWidth: true
        spacing: Colors.spacingS

        // ── Capture mode buttons ──────────────────
        SharedWidgets.SectionLabel { label: "CAPTURE MODE" }

        Repeater {
            model: [
                { mode: "region", icon: "󰩭", label: "Select Region", desc: "Draw a rectangle to capture" },
                { mode: "window", icon: "󰖯", label: "Active Window", desc: "Capture the focused window" },
                { mode: "screen", icon: "󰍹", label: "Current Screen", desc: "Capture the active monitor" },
                { mode: "fullscreen", icon: "󰹑", label: "All Screens", desc: "Capture everything" }
            ]
            delegate: Rectangle {
                Layout.fillWidth: true
                implicitHeight: 48
                radius: Colors.radiusMedium
                color: modeArea.containsMouse ? Colors.primarySubtle : Colors.cardSurface
                border.color: modeArea.containsMouse ? Colors.primary : Colors.border
                border.width: 1

                SharedWidgets.InnerHighlight { hoveredOpacity: 0.25; hovered: modeArea.containsMouse }

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
                    id: modeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.closeRequested();
                        if (modelData.mode === "region")
                            ScreenshotService.captureRegion();
                        else if (modelData.mode === "window")
                            ScreenshotService.captureWindow();
                        else if (modelData.mode === "screen")
                            ScreenshotService.captureScreen("");
                        else
                            ScreenshotService.captureFullscreen();
                    }
                }
            }
        }

        // ── OCR button ────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: Colors.radiusMedium
            color: ocrArea.containsMouse ? Colors.primarySubtle : Colors.cardSurface
            border.color: ocrArea.containsMouse ? Colors.primary : Colors.border
            border.width: 1
            visible: OcrService.isAvailable

            SharedWidgets.InnerHighlight { hoveredOpacity: 0.25; hovered: ocrArea.containsMouse }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Colors.spacingM
                spacing: Colors.spacingM

                Text {
                    text: "󰗊"
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXL
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "Extract Text (OCR)"
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeMedium
                        font.weight: Font.Medium
                    }

                    Text {
                        text: "Select region and copy text"
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeXS
                    }
                }
            }

            MouseArea {
                id: ocrArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.closeRequested();
                    OcrService.ocrRegion();
                }
            }
        }

        // ── OCR language selector ────────────────
        SharedWidgets.SectionLabel {
            label: "OCR LANGUAGE"
            visible: OcrService.isAvailable
        }

        Flow {
            Layout.fillWidth: true
            spacing: Colors.spacingXS
            visible: OcrService.isAvailable

            Repeater {
                model: [
                    { code: "eng", label: "English" },
                    { code: "deu", label: "German" },
                    { code: "fra", label: "French" },
                    { code: "spa", label: "Spanish" },
                    { code: "jpn", label: "Japanese" },
                    { code: "chi_sim", label: "Chinese" }
                ]
                delegate: SharedWidgets.FilterChip {
                    label: modelData.label
                    selected: Config.ocrLanguage === modelData.code
                    onClicked: Config.ocrLanguage = modelData.code
                }
            }
        }

        // ── Delay selector ────────────────────────
        SharedWidgets.SectionLabel { label: "DELAY" }

        Row {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Repeater {
                model: [0, 3, 5, 10]
                delegate: SharedWidgets.FilterChip {
                    label: modelData === 0 ? "None" : modelData + "s"
                    selected: Config.screenshotDelay === modelData
                    onClicked: Config.screenshotDelay = modelData
                }
            }
        }

        // ── Editor settings ───────────────────────
        SharedWidgets.SectionLabel { label: "EDITOR" }

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingM

            Text {
                text: "Edit after capture"
                color: Colors.text
                font.pixelSize: Colors.fontSizeSmall
                Layout.fillWidth: true
            }

            SharedWidgets.ToggleSwitch {
                checked: Config.screenshotEditAfterCapture
                onToggled: Config.screenshotEditAfterCapture = !Config.screenshotEditAfterCapture
            }
        }

        Row {
            Layout.fillWidth: true
            spacing: Colors.spacingS
            visible: Config.screenshotEditAfterCapture

            Repeater {
                model: [
                    { key: "swappy", label: "Swappy" },
                    { key: "satty", label: "Satty" }
                ]
                delegate: SharedWidgets.FilterChip {
                    label: modelData.label
                    selected: Config.screenshotEditor === modelData.key
                    onClicked: Config.screenshotEditor = modelData.key
                }
            }
        }

        // ── AI tools ──────────────────────────────
        SharedWidgets.SectionLabel { label: "AI TOOLS" }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: Colors.radiusMedium
            color: analyzeArea.containsMouse ? Colors.primarySubtle : Colors.cardSurface
            border.color: analyzeArea.containsMouse ? Colors.primary : Colors.border
            border.width: 1

            SharedWidgets.InnerHighlight { hoveredOpacity: 0.25; hovered: analyzeArea.containsMouse }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Colors.spacingM
                spacing: Colors.spacingM

                Text {
                    text: "󰍉"
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXL
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "Analyze with AI"
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeMedium
                        font.weight: Font.Medium
                    }

                    Text {
                        text: "Select region and ask AI about it"
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeXS
                    }
                }
            }

            MouseArea {
                id: analyzeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.closeRequested();
                    ScreenshotService.analyzeRegion();
                }
            }
        }

        // ── Recent screenshots ────────────────────
        SharedWidgets.SectionLabel {
            label: "RECENT"
            visible: _historyModel.length > 0
        }

        Repeater {
            model: _historyModel

            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: Colors.radiusXS
                    color: Colors.cardSurface
                    border.color: Colors.border
                    border.width: 1
                    clip: true

                    SharedWidgets.InnerHighlight { }

                    Image {
                        anchors.fill: parent
                        source: modelData.path ? ("file://" + modelData.path) : ""
                        sourceSize: Qt.size(64, 48)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: root._relativeTime(modelData.timestamp)
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root._modeLabel(modelData.mode || "")
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeXS
                    }
                }

                SharedWidgets.IconButton {
                    icon: "󰈙"
                    iconSize: Colors.fontSizeMedium
                    onClicked: Quickshell.execDetached(["xdg-open", modelData.path])
                }
            }
        }

        // ── Open folder ──────────────────────────
        RowLayout {
            Layout.fillWidth: true
            visible: _historyModel.length > 0

            Item { Layout.fillWidth: true }

            SharedWidgets.IconButton {
                icon: "󰉋"
                iconSize: Colors.fontSizeLarge
                onClicked: ScreenshotService.openScreenshotsFolder()
            }
        }
    }
}
