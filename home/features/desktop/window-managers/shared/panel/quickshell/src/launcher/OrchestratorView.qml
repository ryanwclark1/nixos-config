import QtQuick
import QtQuick.Layouts
import "../services"
import "../features/system/sections" as Modules

ColumnLayout {
    id: root
    spacing: Colors.spacingXL
    Layout.fillWidth: true
    Layout.fillHeight: true

    // ── Header ─────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingM

        ColumnLayout {
            spacing: 0
            Text {
                text: "SYSTEM ORCHESTRATOR"
                color: Colors.primary
                font.pixelSize: Colors.fontSizeIcon
                font.weight: Font.Black
                font.letterSpacing: Colors.letterSpacingTight
            }
            Text {
                text: "Unified Command & Control • v7.0"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeSmall
                font.weight: Font.Bold
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Rectangle {
            width: 120
            height: 32
            radius: Colors.radiusPill
            color: Colors.withAlpha(SystemStatus.isCritical ? Colors.error : Colors.primary, 0.15)
            border.color: SystemStatus.isCritical ? Colors.error : Colors.primary
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: SystemStatus.overallStatus.toUpperCase()
                color: SystemStatus.isCritical ? Colors.error : Colors.text
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Colors.letterSpacingWide
            }
        }
    }

    // ── Main Dashboard ─────────────────────────
    GridLayout {
        columns: 2
        Layout.fillWidth: true
        Layout.fillHeight: true
        columnSpacing: Colors.spacingXL
        rowSpacing: Colors.spacingXL

        // Section 1: Fleet Workspaces
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Colors.radiusLarge
            color: Colors.withAlpha(Colors.surface, 0.2)
            border.color: Colors.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Colors.paddingLarge
                spacing: Colors.spacingM

                Text {
                    text: "WORKSPACE FLEET"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Black
                    font.letterSpacing: Colors.letterSpacingWide
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
                        columnSpacing: Colors.spacingM
                        rowSpacing: Colors.spacingM
                        width: parent.width

                        Repeater {
                            model: NiriService.allWorkspaces
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 140
                                radius: Colors.radiusMedium
                                color: modelData.is_focused ? Colors.highlightLight : Colors.withAlpha(Colors.surface, 0.3)
                                border.color: modelData.is_focused ? Colors.primary : Colors.border
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: Colors.spacingM
                                    spacing: Colors.spacingS
                                    RowLayout {
                                        Text {
                                            text: modelData.name || modelData.id
                                            color: modelData.is_focused ? Colors.primary : Colors.text
                                            font.pixelSize: Colors.fontSizeSmall
                                            font.weight: Font.Bold
                                        }
                                        Item {
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: modelData.windows + " windows"
                                            color: Colors.textDisabled
                                            font.pixelSize: Colors.fontSizeXXS
                                        }
                                    }

                                    // Mini-map visualization placeholder
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: Colors.radiusMicro
                                        color: Colors.withAlpha(Colors.background, 0.4)
                                        clip: true

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󱗼"
                                            color: Colors.textDisabled
                                            opacity: 0.2
                                            font.pixelSize: Colors.fontSizeIcon
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
            spacing: Colors.spacingXL

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Colors.radiusLarge
                color: Colors.withAlpha(Colors.surface, 0.2)
                border.color: Colors.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Colors.paddingLarge
                    spacing: Colors.spacingL
                    Text {
                        text: "TELEMETRY HEATMAP"
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXS
                        font.weight: Font.Black
                        font.letterSpacing: Colors.letterSpacingWide
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
                radius: Colors.radiusLarge
                color: Colors.withAlpha(Colors.surface, 0.2)
                border.color: Colors.accent
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Colors.paddingLarge
                    spacing: Colors.spacingM
                    Text {
                        text: "ACTIVE MISSION"
                        color: Colors.accent
                        font.pixelSize: Colors.fontSizeXS
                        font.weight: Font.Black
                        font.letterSpacing: Colors.letterSpacingWide
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Colors.radiusXS
                        color: Colors.withAlpha(Colors.background, 0.4)
                        Text {
                            anchors.fill: parent
                            anchors.margins: Colors.spacingM
                            text: AiService.isStreaming ? AiService.streamingContent : (AiService.activeMessages.length > 0 ? AiService.activeMessages[AiService.activeMessages.length - 1].content : "Listening for commands...")
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeXS
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
