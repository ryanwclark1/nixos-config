import QtQuick
import QtQuick.Layouts
import Quickshell
import "../modules"
import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
    id: root
    popupMaxWidth: 380
    compactThreshold: 360
    implicitHeight: compactMode ? 620 : 580
    title: "System"
    subtitle: compactMode ? "Actions first" : "Processes, services, and live telemetry"
    toggleMethod: "toggleSystemStatsMenu"

    Loader {
        active: root.visible
        sourceComponent: SharedWidgets.Ref {
            service: SystemStatus
        }
    }
    Loader {
        active: root.visible
        sourceComponent: SharedWidgets.Ref {
            service: ProcessService
        }
    }
    Loader {
        active: root.visible
        sourceComponent: SharedWidgets.Ref {
            service: ServiceUnitService
        }
    }

    // At-a-glance temp/usage card
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: atAGlanceColumn.implicitHeight + Colors.paddingSmall * 2
        radius: Colors.radiusMedium
        color: Colors.withAlpha(Colors.surface, 0.4)
        border.color: Colors.border
        border.width: 1

        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Colors.surfaceGradientStart }
            GradientStop { position: 1.0; color: Colors.surfaceGradientEnd }
        }

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

        ColumnLayout {
            id: atAGlanceColumn
            anchors.fill: parent
            anchors.margins: Colors.paddingSmall
            spacing: Colors.spacingS

            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingM

                RowLayout {
                    spacing: Colors.spacingXS
                    Text {
                        text: ""
                        color: Colors.primary
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeMedium
                    }
                    Text {
                        text: SystemStatus.cpuTemp
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: Font.Medium
                    }
                }

                RowLayout {
                    spacing: Colors.spacingXS
                    Text {
                        text: "󰢮"
                        color: Colors.accent
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeMedium
                    }
                    Text {
                        text: SystemStatus.gpuTemp
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: Font.Medium
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingS

                SharedWidgets.Chip {
                    icon: ""
                    iconColor: Colors.primary
                    text: "CPU " + SystemStatus.cpuUsage
                    textColor: Colors.primary
                }
                SharedWidgets.Chip {
                    icon: "󰍛"
                    iconColor: Colors.accent
                    text: "RAM " + SystemStatus.ramUsage
                    textColor: Colors.accent
                }
                SharedWidgets.Chip {
                    icon: "󰢮"
                    iconColor: Colors.secondary
                    text: "GPU " + SystemStatus.gpuUsage
                    textColor: Colors.secondary
                }
            }
        }
    }

    // Scrollable module area
    SharedWidgets.ScrollableContent {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columnSpacing: Colors.paddingSmall

        SharedWidgets.SectionLabel {
            label: "ACTIONS"
        }

        ProcessWidget {
            compactMode: root.compactMode
        }
        ServiceUnitWidget {
            compactMode: root.compactMode
        }

        SharedWidgets.SectionLabel {
            label: "TELEMETRY"
        }

        SystemGraphs {}
        DiskWidget {}
        NetworkGraphs {}
        GPUWidget {}
    }
}
