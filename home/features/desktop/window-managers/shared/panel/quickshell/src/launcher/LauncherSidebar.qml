import QtQuick
import QtQuick.Layouts
import "../services"
import "../shared"
import "../widgets" as SharedWidgets
import "LauncherModeData.js" as ModeData

Rectangle {
    id: root

    required property var launcher

    radius: Colors.radiusLarge
    color: Colors.withAlpha("#000000", 0.15)
    border.color: Colors.border
    border.width: 1

    // Depth highlight
    SharedWidgets.InnerHighlight {
        highlightOpacity: 0.1
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
                    text: "Quick Hub"
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
                spacing: root.launcher.sidebarCompact ? Colors.spacingS : Colors.spacingS

                Repeater {
                    model: root.launcher.primaryModes
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: root.launcher.sidebarCompact ? 44 : 46
                        radius: Colors.radiusMedium
                        readonly property bool isCurrent: root.launcher.mode === modelData
                        readonly property bool isHovered: modeHover.containsMouse
                        
                        color: isCurrent ? Colors.highlight : (isHovered ? Colors.withAlpha("#ffffff", 0.04) : "transparent")
                        Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
                        
                        border.color: isCurrent ? Colors.withAlpha(Colors.primary, 0.4) : (isHovered ? Colors.withAlpha(Colors.border, 0.5) : "transparent")
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: root.launcher.sidebarCompact ? Colors.spacingXS : Colors.paddingSmall
                            spacing: root.launcher.sidebarCompact ? Colors.spacingXS : Colors.paddingMedium
                            
                            Rectangle {
                                Layout.preferredWidth: 30; Layout.preferredHeight: 30
                                radius: Colors.radiusSmall
                                color: isCurrent ? Colors.surface : "transparent"
                                visible: !root.launcher.sidebarCompact
                                Text {
                                    anchors.centerIn: parent
                                    text: root.launcher.modeIcons[modelData] || "•"
                                    color: isCurrent ? Colors.primary : Colors.textSecondary
                                    font.family: Colors.fontMono
                                    font.pixelSize: Colors.fontSizeLarge
                                }
                            }

                            Text {
                                visible: root.launcher.sidebarCompact
                                Layout.alignment: Qt.AlignHCenter
                                text: root.launcher.modeIcons[modelData] || "•"
                                color: isCurrent ? Colors.primary : Colors.textSecondary
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeXL
                            }

                            Text {
                                visible: !root.launcher.sidebarCompact
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: ModeData.modeInfo(modelData).label
                                color: isCurrent ? Colors.primary : Colors.textSecondary
                                font.pixelSize: Colors.fontSizeSmall
                                font.weight: isCurrent ? Font.Black : Font.Medium
                                font.capitalization: isCurrent ? Font.AllUppercase : Font.MixedCase
                                font.letterSpacing: isCurrent ? 0.5 : 0
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: modeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
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
                    text: "SHORTCUTS"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Black
                    font.letterSpacing: Colors.letterSpacingWide
                }
                Text {
                    Layout.fillWidth: true
                    text: root.launcher.tabControlHintText
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Bold
                    wrapMode: Text.WordWrap
                }
                Text {
                    Layout.fillWidth: true
                    text: root.launcher.launcherControlHintText
                    color: Colors.textDisabled
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
