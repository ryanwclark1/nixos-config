import Quickshell
import QtQuick
import QtQuick.Layouts
import "../modules"
import "../services"
import "../widgets" as SharedWidgets

PopupWindow {
  id: root
  implicitWidth: 380
  implicitHeight: 580

  Component.onCompleted: SystemStatus.subscribe()
  Component.onDestruction: SystemStatus.unsubscribe()

  Rectangle {
    anchors.fill: parent
    color: Colors.popupSurface
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusMedium
    clip: true

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Colors.paddingLarge
      spacing: 14

      // Header
      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "System"
          color: Colors.fgMain
          font.pixelSize: 18
          font.weight: Font.DemiBold
        }
        Item { Layout.fillWidth: true }
        SharedWidgets.MenuCloseButton { toggleMethod: "toggleSystemStatsMenu" }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.border
      }

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
          anchors.margins: 10
          spacing: 12

          // CPU Temp
          RowLayout {
            spacing: 4
            Text { text: ""; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 14 }
            Text { text: SystemStatus.cpuTemp; color: Colors.fgMain; font.pixelSize: 12; font.weight: Font.Medium }
          }

          // GPU Temp
          RowLayout {
            spacing: 4
            Text { text: "󰢮"; color: Colors.accent; font.family: Colors.fontMono; font.pixelSize: 14 }
            Text { text: SystemStatus.gpuTemp; color: Colors.fgMain; font.pixelSize: 12; font.weight: Font.Medium }
          }

          Item { Layout.fillWidth: true }

          // CPU% chip
          Rectangle {
            radius: 10
            color: Colors.withAlpha(Colors.primary, 0.16)
            implicitWidth: cpuChipText.implicitWidth + 12
            implicitHeight: 22
            Text {
              id: cpuChipText
              anchors.centerIn: parent
              text: "CPU " + SystemStatus.cpuUsage
              color: Colors.primary
              font.pixelSize: 9
              font.weight: Font.Bold
            }
          }

          // RAM% chip
          Rectangle {
            radius: 10
            color: Colors.withAlpha(Colors.accent, 0.16)
            implicitWidth: ramChipText.implicitWidth + 12
            implicitHeight: 22
            Text {
              id: ramChipText
              anchors.centerIn: parent
              text: "RAM " + SystemStatus.ramUsage
              color: Colors.accent
              font.pixelSize: 9
              font.weight: Font.Bold
            }
          }

          // GPU% chip
          Rectangle {
            radius: 10
            color: Colors.withAlpha(Colors.secondary, 0.16)
            implicitWidth: gpuChipText.implicitWidth + 12
            implicitHeight: 22
            Text {
              id: gpuChipText
              anchors.centerIn: parent
              text: "GPU " + SystemStatus.gpuUsage
              color: Colors.secondary
              font.pixelSize: 9
              font.weight: Font.Bold
            }
          }
        }
      }

      // Scrollable module area
      Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: modulesColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
          id: modulesColumn
          width: parent.width
          spacing: 10

          SystemGraphs {}
          GPUWidget {}
          NetworkGraphs {}
          DiskWidget {}
          ProcessWidget {}
        }
      }
    }
  }
}
