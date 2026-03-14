import QtQuick
import QtQuick.Layouts
import "../services"

Item {
  id: root
  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  Ref { service: SystemStatus }

  RowLayout {
    id: row
    spacing: 30

    ColumnLayout {
      spacing: Colors.spacingXS
      Text { text: "CPU"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.letterSpacing: 1 }
      RowLayout {
        spacing: Colors.spacingSM
        Text { text: ""; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
        Text { text: SystemStatus.cpuUsage; color: Colors.text; font.pixelSize: Colors.fontSizeLarge; font.weight: Font.Bold }
      }
    }

    ColumnLayout {
      spacing: Colors.spacingXS
      Text { text: "RAM"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.letterSpacing: 1 }
      RowLayout {
        spacing: Colors.spacingSM
        Text { text: ""; color: Colors.secondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
        Text { text: SystemStatus.ramUsage; color: Colors.text; font.pixelSize: Colors.fontSizeLarge; font.weight: Font.Bold }
      }
    }

    ColumnLayout {
      spacing: Colors.spacingXS
      Text { text: "TEMP"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.letterSpacing: 1 }
      RowLayout {
        spacing: Colors.spacingSM
        Text { text: "󰔏"; color: Colors.warning; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
        Text { text: SystemStatus.cpuTemp || "--"; color: Colors.text; font.pixelSize: Colors.fontSizeLarge; font.weight: Font.Bold }
      }
    }
  }
}
