import Quickshell
import QtQuick
import QtQuick.Layouts
import "../modules"
import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMaxWidth: 380; compactThreshold: 360
  implicitHeight: compactMode ? 620 : 580
  title: "System"
  toggleMethod: "toggleSystemStatsMenu"

  Loader { active: root.visible; sourceComponent: SharedWidgets.Ref { service: SystemStatus } }

  // At-a-glance temp/usage card
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: atAGlanceColumn.implicitHeight + Colors.paddingSmall * 2
    radius: Colors.radiusMedium
    color: Colors.cardSurface
    border.color: Colors.border
    border.width: 1

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
          Text { text: ""; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium }
          Text { text: SystemStatus.cpuTemp; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium }
        }

        RowLayout {
          spacing: Colors.spacingXS
          Text { text: "󰢮"; color: Colors.accent; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium }
          Text { text: SystemStatus.gpuTemp; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium }
        }

        Item { Layout.fillWidth: true }
      }

      Flow {
        Layout.fillWidth: true
        width: parent.width
        spacing: Colors.spacingS

        SharedWidgets.Chip { icon: ""; iconColor: Colors.primary; text: "CPU " + SystemStatus.cpuUsage; textColor: Colors.primary }
        SharedWidgets.Chip { icon: "󰍛"; iconColor: Colors.accent; text: "RAM " + SystemStatus.ramUsage; textColor: Colors.accent }
        SharedWidgets.Chip { icon: "󰢮"; iconColor: Colors.secondary; text: "GPU " + SystemStatus.gpuUsage; textColor: Colors.secondary }
      }
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
