import QtQuick
import "../../../services"
import "../../../widgets" as SharedWidgets

Item {
  id: root
  implicitWidth: mainRow.width
  implicitHeight: mainRow.height
  property var anchorWindow: null
  property bool isActive: false
  signal statsClicked()

  SharedWidgets.Ref { service: SystemStatus }

  Row {
    id: mainRow
    spacing: Appearance.spacingS
    anchors.verticalCenter: parent.verticalCenter

    // CPU Pill
    SharedWidgets.BarPill {
      anchorWindow: root.anchorWindow
      isActive: root.isActive
      tooltipText: "CPU " + SystemStatus.cpuUsage + " • " + SystemStatus.cpuTemp
      anchors.verticalCenter: parent.verticalCenter
      onClicked: root.statsClicked()

      Row {
        spacing: Appearance.spacingSM
        SharedWidgets.SvgIcon {
          source: "chevron-left.svg"
          color: Colors.primary
          size: Appearance.fontSizeLarge
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          text: "CPU " + SystemStatus.cpuUsage
          color: Colors.text
          font.pixelSize: Appearance.fontSizeMedium
          font.weight: Font.DemiBold
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    // Memory Pill
    SharedWidgets.BarPill {
      anchorWindow: root.anchorWindow
      isActive: root.isActive
      tooltipText: "RAM " + SystemStatus.ramUsage + " • GPU " + SystemStatus.gpuUsage
      anchors.verticalCenter: parent.verticalCenter
      onClicked: root.statsClicked()

      Row {
        spacing: Appearance.spacingSM
        SharedWidgets.SvgIcon {
          source: "chevron-right.svg"
          color: Colors.accent
          size: Appearance.fontSizeLarge
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          text: "RAM " + SystemStatus.ramUsage
          color: Colors.text
          font.pixelSize: Appearance.fontSizeMedium
          font.weight: Font.DemiBold
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }
}
