import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../../widgets" as SharedWidgets
import "../../features/settings/components"

Rectangle {
    id: root
    implicitWidth: 280
    implicitHeight: contentCol.implicitHeight + Appearance.paddingLarge
    width: implicitWidth
    radius: Appearance.radiusMedium
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
        anchors.margins: Appearance.spacingM
        spacing: Appearance.spacingM

        RowLayout {
            Layout.fillWidth: true
            Text { text: "RESOURCE REAPER"; color: Colors.textDisabled; font.pixelSize: Appearance.fontSizeXS; font.weight: Font.Black; font.letterSpacing: Appearance.letterSpacingWide; Layout.fillWidth: true }
            Text { text: ProcessService.sortBy.toUpperCase(); color: Colors.primary; font.pixelSize: Appearance.fontSizeXXS; font.weight: Font.Bold }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingXS

            Repeater {
                model: ProcessService.processes ? ProcessService.processes.slice(0, 5) : []
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: Appearance.radiusSmall
                    color: Colors.cardSurface
                    
                    RowLayout {
                        anchors.fill: parent; anchors.margins: Appearance.spacingS
                        spacing: Appearance.spacingS
                        
                        ColumnLayout {
                            spacing: -2; Layout.fillWidth: true
                            Text { text: modelData.name; color: Colors.text; font.pixelSize: Appearance.fontSizeXS; font.weight: Font.Bold; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: "PID " + modelData.pid; color: Colors.textDisabled; font.pixelSize: Appearance.fontSizeXXS }
                        }
                        
                        Text { 
                            text: (ProcessService.sortBy === "cpu" ? modelData.cpu : modelData.mem) + "%"
                            color: Colors.primary; font.pixelSize: Appearance.fontSizeXS; font.weight: Font.Bold
                        }
                        
                        SharedWidgets.IconButton {
                            icon: "dismiss.svg"
                            size: Appearance.iconSizeSmall; iconSize: 12
                            iconColor: Colors.error
                            tooltipText: "Kill process"
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
