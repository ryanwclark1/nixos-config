import QtQuick
import QtQuick.Layouts
import "../services"

Item {
  id: root
  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  RowLayout {
    id: row
    spacing: 30

    ColumnLayout {
      spacing: 4
      Text { text: "CPU"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
      RowLayout {
        spacing: 6
        Text { text: ""; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 18 }
        Text { text: SystemStatus.cpuUsage; color: Colors.text; font.pixelSize: 16; font.weight: Font.Bold }
      }
    }

    ColumnLayout {
      spacing: 4
      Text { text: "RAM"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
      RowLayout {
        spacing: 6
        Text { text: ""; color: Colors.secondary; font.family: Colors.fontMono; font.pixelSize: 18 }
        Text { text: SystemStatus.ramUsage; color: Colors.text; font.pixelSize: 16; font.weight: Font.Bold }
      }
    }

    ColumnLayout {
      spacing: 4
      Text { text: "TEMP"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
      RowLayout {
        spacing: 6
        Text { text: "󰔏"; color: Colors.warning; font.family: Colors.fontMono; font.pixelSize: 18 }
        Text { text: SystemStatus.cpuTemp || "--"; color: Colors.text; font.pixelSize: 16; font.weight: Font.Bold }
      }
    }
  }
}
