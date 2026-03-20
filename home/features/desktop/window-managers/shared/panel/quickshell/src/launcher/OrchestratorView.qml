import QtQuick
import QtQuick.Layouts
import "../services"
import "../features/system/sections" as Modules

ColumnLayout {
    id: root
    spacing: Appearance.spacingXL
    Layout.fillWidth: true
    Layout.fillHeight: true

    // ── Header ─────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingM

        ColumnLayout {
            spacing: 0
            Text {
                text: "SYSTEM ORCHESTRATOR"
                color: Colors.primary
                font.pixelSize: Appearance.fontSizeIcon
                font.weight: Font.Black
                font.letterSpacing: Appearance.letterSpacingTight
            }
            Text {
                text: "Unified Command & Control • v7.0"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeSmall
                font.weight: Font.Bold
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Rectangle {
            width: 120
            height: 32
            radius: Appearance.radiusPill
            color: Colors.withAlpha(SystemStatus.isCritical ? Colors.error : Colors.primary, 0.15)
            border.color: SystemStatus.isCritical ? Colors.error : Colors.primary
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: SystemStatus.overallStatus.toUpperCase()
                color: SystemStatus.isCritical ? Colors.error : Colors.text
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Appearance.letterSpacingWide
            }
        }
    }

    // ── Main Dashboard ─────────────────────────
    GridLayout {
        columns: 2
        Layout.fillWidth: true
        Layout.fillHeight: true
        columnSpacing: Appearance.spacingXL
        rowSpacing: Appearance.spacingXL

        // Section 1: Fleet Workspaces
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.radiusLarge
            color: Colors.withAlpha(Colors.surface, 0.2)
            border.color: Colors.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Appearance.paddingLarge
                spacing: Appearance.spacingM

                Text {
                    text: "WORKSPACE FLEET"
                    color: Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeXS
                    font.weight: Font.Black
                    font.letterSpacing: Appearance.letterSpacingWide
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: wsGrid.implicitHeight
                    clip: true

                    GridLayout {
                        id: wsGrid
                        columns: 2
                        columnSpacing: Appearance.spacingM
                        rowSpacing: Appearance.spacingM
                        width: parent.width

                        Repeater {
                            model: NiriService.allWorkspaces
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 140
                                radius: Appearance.radiusMedium
                                color: modelData.is_focused ? Colors.highlightLight : Colors.withAlpha(Colors.surface, 0.3)
                                border.color: modelData.is_focused ? Colors.primary : Colors.border
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: Appearance.spacingM
                                    spacing: Appearance.spacingS
                                    RowLayout {
                                        Text {
                                            text: modelData.name || modelData.id
                                            color: modelData.is_focused ? Colors.primary : Colors.text
                                            font.pixelSize: Appearance.fontSizeSmall
                                            font.weight: Font.Bold
                                        }
                                        Item {
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: modelData.windows + " windows"
                                            color: Colors.textDisabled
                                            font.pixelSize: Appearance.fontSizeXXS
                                        }
                                    }

                                    // Mini-map visualization placeholder
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: Appearance.radiusMicro
                                        color: Colors.withAlpha(Colors.background, 0.4)
                                        clip: true

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󱗼"
                                            color: Colors.textDisabled
                                            opacity: 0.2
                                            font.pixelSize: Appearance.fontSizeIcon
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Section 2: Core Telemetry
        ColumnLayout {
            Layout.preferredWidth: 380
            Layout.fillHeight: true
            spacing: Appearance.spacingXL

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.radiusLarge
                color: Colors.withAlpha(Colors.surface, 0.2)
                border.color: Colors.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.paddingLarge
                    spacing: Appearance.spacingL
                    Text {
                        text: "TELEMETRY HEATMAP"
                        color: Colors.textDisabled
                        font.pixelSize: Appearance.fontSizeXS
                        font.weight: Font.Black
                        font.letterSpacing: Appearance.letterSpacingWide
                    }

                    Modules.SystemGraphs {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 160
                    }
                    Modules.GPUWidget {
                        Layout.fillWidth: true
                    }
                    Modules.DiskWidget {
                        Layout.fillWidth: true
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                radius: Appearance.radiusLarge
                color: Colors.withAlpha(Colors.surface, 0.2)
                border.color: Colors.accent
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.paddingLarge
                    spacing: Appearance.spacingM
                    Text {
                        text: "ACTIVE MISSION"
                        color: Colors.accent
                        font.pixelSize: Appearance.fontSizeXS
                        font.weight: Font.Black
                        font.letterSpacing: Appearance.letterSpacingWide
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Appearance.radiusXS
                        color: Colors.withAlpha(Colors.background, 0.4)
                        Text {
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingM
                            text: AiService.isStreaming ? AiService.streamingContent : (AiService.activeMessages.length > 0 ? AiService.activeMessages[AiService.activeMessages.length - 1].content : "Listening for commands...")
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeXS
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
