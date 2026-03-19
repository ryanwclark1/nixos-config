import QtQuick
import QtQuick.Layouts
import "../services"
import "../shared"
import "../widgets" as SharedWidgets

Rectangle {
    id: root

    required property var launcher
    readonly property var _primaryModes: Array.isArray(root.launcher && root.launcher.primaryModes) ? root.launcher.primaryModes : []
    readonly property var _overflowModes: Array.isArray(root.launcher && root.launcher.overflowModes) ? root.launcher.overflowModes : []

    radius: Colors.radiusLarge
    color: Colors.withAlpha("#000000", 0.15)
    border.color: Colors.border
    border.width: 1

    SharedWidgets.InnerHighlight {
        highlightOpacity: 0.1
    }

    component ModeButton: Rectangle {
        required property string modeKey
        required property string label
        required property string iconText
        required property bool compact
        property bool active: false
        property bool hovered: hoverArea.containsMouse
        signal clicked

        Layout.fillWidth: true
        implicitHeight: compact ? 44 : 46
        radius: Colors.radiusMedium
        color: active ? Colors.highlight : (hovered ? Colors.withAlpha("#ffffff", 0.04) : "transparent")
        border.color: active ? Colors.withAlpha(Colors.primary, 0.4) : (hovered ? Colors.withAlpha(Colors.border, 0.5) : "transparent")
        border.width: 1

        Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }

        RowLayout {
            anchors.fill: parent
            anchors.margins: compact ? Colors.spacingXS : Colors.paddingSmall
            spacing: compact ? Colors.spacingXS : Colors.paddingMedium

            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: Colors.radiusSmall
                color: active ? Colors.surface : "transparent"
                visible: !compact

                Text {
                    anchors.centerIn: parent
                    text: iconText || "•"
                    color: active ? Colors.primary : Colors.textSecondary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeLarge
                }
            }

            Text {
                visible: compact
                Layout.alignment: Qt.AlignHCenter
                text: iconText || "•"
                color: active ? Colors.primary : Colors.textSecondary
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeXL
            }

            Text {
                visible: !compact
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: label
                color: active ? Colors.primary : Colors.textSecondary
                font.pixelSize: Colors.fontSizeSmall
                font.weight: active ? Font.Black : Font.Medium
                font.capitalization: active ? Font.AllUppercase : Font.MixedCase
                font.letterSpacing: active ? 0.5 : 0
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.launcher.sidebarCompact ? Colors.spacingS : Colors.spacingM
        spacing: root.launcher.sidebarCompact ? Colors.spacingXS : Colors.paddingSmall

        RowLayout {
            visible: !root.launcher.sidebarCompact
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Rectangle {
                width: 32
                height: 32
                radius: Colors.radiusMedium
                color: Colors.primaryMarked
                border.color: Colors.withAlpha(Colors.primary, 0.24)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰍉"
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXL
                }
            }

            ColumnLayout {
                spacing: 0

                Text {
                    text: "NAVIGATE"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Black
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: Colors.letterSpacingWide
                }

                Text {
                    text: root.launcher.sidebarOverflowExpanded ? "Advanced Modes" : "Quick Hub"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Bold
                }
            }
        }

        Item {
            Layout.preferredHeight: Colors.spacingS
            visible: !root.launcher.sidebarCompact
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentHeight: modeColumn.implicitHeight

            ColumnLayout {
                id: modeColumn
                width: parent.width
                spacing: Colors.spacingS

                Repeater {
                    model: root._primaryModes

                    delegate: ModeButton {
                        required property string modelData
                        modeKey: modelData
                        label: root.launcher.modeMeta(modelData).label
                        iconText: root.launcher.modeIcons[modelData] || "•"
                        compact: root.launcher.sidebarCompact
                        active: root.launcher.mode === modelData
                        onClicked: root.launcher.open(modelData, true)
                    }
                }

                ModeButton {
                    visible: root._overflowModes.length > 0
                    modeKey: "__more__"
                    label: root.launcher.sidebarOverflowExpanded ? "Hide More" : "More"
                    iconText: root.launcher.sidebarOverflowExpanded ? "󰅀" : "󰅂"
                    compact: root.launcher.sidebarCompact
                    active: root.launcher.sidebarOverflowExpanded || root._overflowModes.indexOf(root.launcher.mode) !== -1
                    onClicked: root.launcher.sidebarOverflowExpanded = !root.launcher.sidebarOverflowExpanded
                }

                ColumnLayout {
                    visible: root.launcher.sidebarOverflowExpanded && root._overflowModes.length > 0
                    Layout.fillWidth: true
                    spacing: Colors.spacingS

                    Repeater {
                        model: root._overflowModes

                        delegate: ModeButton {
                            required property string modelData
                            modeKey: modelData
                            label: root.launcher.modeMeta(modelData).label
                            iconText: root.launcher.modeIcons[modelData] || "•"
                            compact: root.launcher.sidebarCompact
                            active: root.launcher.mode === modelData
                            onClicked: root.launcher.open(modelData, true)
                        }
                    }
                }
            }
        }

        Rectangle {
            id: controlsBox
            Layout.fillWidth: true
            Layout.topMargin: Colors.spacingS
            implicitHeight: controlsLayout.implicitHeight + (Colors.paddingMedium * 2)
            radius: Colors.radiusMedium
            color: Colors.withAlpha("#000000", 0.1)
            border.color: Colors.border
            border.width: 1
            visible: Config.launcherShowModeHints && !root.launcher.sidebarCompact

            ColumnLayout {
                id: controlsLayout
                anchors.fill: parent
                anchors.margins: Colors.paddingMedium
                spacing: Colors.spacingXXS

                Text {
                    text: "MODE"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Black
                    font.letterSpacing: Colors.letterSpacingWide
                }

                Text {
                    Layout.fillWidth: true
                    text: String(root.launcher.modeSummaryText || "")
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Bold
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: String(root.launcher.overflowHintText || "")
                    color: Colors.textDisabled
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
