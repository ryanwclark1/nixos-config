import Quickshell
import QtQuick
import QtQuick.Layouts
import "../modules"
import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  implicitWidth: 380
  implicitHeight: 580
  title: "System"
  toggleMethod: "toggleSystemStatsMenu"

  Loader { active: root.visible; sourceComponent: SharedWidgets.Ref { service: SystemStatus } }

  // At-a-glance temp/usage card
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 52
    radius: Colors.radiusMedium
    color: Colors.cardSurface
    border.color: Colors.border
    border.width: 1

    RowLayout {
      anchors.fill: parent
      anchors.margins: Colors.paddingSmall
      spacing: Colors.spacingM

      // CPU Temp
      RowLayout {
        spacing: Colors.spacingXS
        Text { text: ""; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium }
        Text { text: SystemStatus.cpuTemp; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium }
      }

      // GPU Temp
      RowLayout {
        spacing: Colors.spacingXS
        Text { text: "󰢮"; color: Colors.accent; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium }
        Text { text: SystemStatus.gpuTemp; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium }
      }

      Item { Layout.fillWidth: true }

      SharedWidgets.Chip { icon: ""; iconColor: Colors.primary; text: "CPU " + SystemStatus.cpuUsage; textColor: Colors.primary }
      SharedWidgets.Chip { icon: "󰍛"; iconColor: Colors.accent; text: "RAM " + SystemStatus.ramUsage; textColor: Colors.accent }
      SharedWidgets.Chip { icon: "󰢮"; iconColor: Colors.secondary; text: "GPU " + SystemStatus.gpuUsage; textColor: Colors.secondary }
    }
  }

  // Scrollable module area
  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Colors.paddingSmall

    SystemGraphs {}
    GPUWidget {}
    NetworkGraphs {}
    DiskWidget {}
    ProcessWidget {}
  }
}
