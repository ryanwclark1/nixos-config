import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

Rectangle {
    id: root

    required property var launcher

    radius: Colors.radiusLarge
    color: Colors.popupSurface
    border.color: Colors.primaryStrong
    border.width: 1

    // Depth highlight
    SharedWidgets.InnerHighlight {
        highlightOpacity: 0.2
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
                width: 30
                height: 30
                radius: Colors.radiusMedium
                color: Colors.primarySubtle
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
                    text: "Launcher"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeXL
                    font.weight: Font.DemiBold
                }
                Text {
                    text: "Application Hub"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Medium
                }
            }
        }

        Item {
            Layout.preferredHeight: Colors.spacingS
            visible: !root.launcher.sidebarCompact
        }
        SharedWidgets.SectionLabel {
            visible: !root.launcher.sidebarCompact
            label: "MODES"
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
                spacing: root.launcher.sidebarCompact ? Colors.spacingXS : Colors.paddingSmall

                Repeater {
                    model: root.launcher.primaryModes
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: root.launcher.sidebarCompact ? 40 : 44
                        radius: Colors.radiusMedium
                        color: root.launcher.mode === modelData ? Colors.primaryAccent : Colors.withAlpha(Colors.surface, 0.12)
                        Behavior on color {
                            ColorAnimation {
                                duration: Colors.durationFast
                            }
                        }
                        border.color: root.launcher.mode === modelData ? Colors.primary : Colors.withAlpha(Colors.border, 0.28)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: root.launcher.sidebarCompact ? Colors.spacingXS : Colors.paddingSmall
                            spacing: root.launcher.sidebarCompact ? Colors.spacingXS : Colors.paddingSmall
                            Text {
                                text: root.launcher.modeIcons[modelData] || "•"
                                color: root.launcher.mode === modelData ? Colors.primary : Colors.textSecondary
                                font.family: Colors.fontMono
                                font.pixelSize: root.launcher.sidebarCompact ? Colors.fontSizeXL : Colors.fontSizeLarge
                                Layout.alignment: Qt.AlignVCenter | (root.launcher.sidebarCompact ? Qt.AlignHCenter : Qt.AlignLeft)
                            }
                            Text {
                                visible: !root.launcher.sidebarCompact
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: root.launcher.modeInfo(modelData).label
                                color: root.launcher.mode === modelData ? Colors.text : Colors.textSecondary
                                font.pixelSize: Colors.fontSizeSmall
                                font.weight: root.launcher.mode === modelData ? Font.Bold : Font.Medium
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        SharedWidgets.StateLayer {
                            id: modeStateLayer
                            hovered: modeHover.containsMouse
                            pressed: modeHover.pressed
                            visible: root.launcher.mode !== modelData
                        }
                        MouseArea {
                            id: modeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                modeStateLayer.burst(mouse.x, mouse.y);
                                root.launcher.open(modelData, true);
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: controlsBox
            Layout.fillWidth: true
            Layout.topMargin: Colors.spacingS
            implicitHeight: controlsLayout.implicitHeight + (Colors.spacingM * 2)
            radius: Colors.radiusMedium
            color: Colors.withAlpha(Colors.surface, 0.2)
            border.color: Colors.primaryAccent
            border.width: 1
            visible: Config.launcherShowModeHints && !root.launcher.sidebarCompact

            ColumnLayout {
                id: controlsLayout
                anchors.fill: parent
                anchors.margins: Colors.spacingM
                spacing: Colors.spacingXXS
                SharedWidgets.SectionLabel {
                    label: "CONTROLS"
                }
                Text {
                    Layout.fillWidth: true
                    text: root.launcher.tabControlHintText
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
                Text {
                    Layout.fillWidth: true
                    text: root.launcher.launcherControlHintText
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
