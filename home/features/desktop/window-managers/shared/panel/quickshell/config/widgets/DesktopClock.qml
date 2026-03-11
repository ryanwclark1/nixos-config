import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"

Item {
  id: root
  implicitWidth: col.implicitWidth
  implicitHeight: col.implicitHeight

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  ColumnLayout {
    id: col
    spacing: -8

    Text {
      text: Qt.formatDateTime(clock.date, "HH:mm")
      color: Colors.primary
      font.pixelSize: 80
      font.weight: Font.Bold
      font.letterSpacing: -3
    }

    Text {
      text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
      color: Colors.text
      font.pixelSize: 20
      font.weight: Font.Medium
      Layout.leftMargin: 4
    }
  }
}
