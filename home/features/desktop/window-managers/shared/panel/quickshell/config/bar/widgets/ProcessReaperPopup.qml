import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../../widgets" as SharedWidgets
import "../../menu/settings"

Rectangle {
    id: root
    width: 280
    implicitHeight: contentCol.implicitHeight + 24
    radius: Colors.radiusMedium
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1
    
    gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: Colors.surfaceGradientStart }
        GradientStop { position: 1.0; color: Colors.surfaceGradientEnd }
    }

    SharedWidgets.InnerHighlight { highlightOpacity: 0.15 }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        spacing: Colors.spacingM

        RowLayout {
            Layout.fillWidth: true
            Text { text: "RESOURCE REAPER"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Black; font.letterSpacing: Colors.letterSpacingWide; Layout.fillWidth: true }
            Text { text: ProcessService.sortBy.toUpperCase(); color: Colors.primary; font.pixelSize: 9; font.weight: Font.Bold }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingXS

            Repeater {
                model: ProcessService.processes ? ProcessService.processes.slice(0, 5) : []
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: Colors.radiusSmall
                    color: Colors.withAlpha(Colors.surface, 0.3)
                    
                    RowLayout {
                        anchors.fill: parent; anchors.margins: Colors.spacingS
                        spacing: Colors.spacingS
                        
                        ColumnLayout {
                            spacing: -2; Layout.fillWidth: true
                            Text { text: modelData.name; color: Colors.text; font.pixelSize: 11; font.weight: Font.Bold; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: "PID " + modelData.pid; color: Colors.textDisabled; font.pixelSize: 9 }
                        }
                        
                        Text { 
                            text: (ProcessService.sortBy === "cpu" ? modelData.cpu : modelData.mem) + "%"
                            color: Colors.primary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold
                        }
                        
                        SharedWidgets.IconButton {
                            icon: "󰅖"
                            size: 24; iconSize: 12
                            iconColor: Colors.error
                            onClicked: ProcessService.killProcess(modelData.pid)
                        }
                    }
                }
            }
        }

        SettingsActionButton {
            label: "Open Full Monitor"
            iconName: "󰓅"
            compact: true
            Layout.fillWidth: true
            onClicked: {
                Quickshell.execDetached(["quickshell", "ipc", "call", "SystemStatsMenu", "toggle"]);
            }
        }
    }
}
