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

  Rectangle {
    id: bg
    anchors.fill: parent
    anchors.margins: -Colors.spacingL
    radius: Colors.radiusLarge
    color: Colors.withAlpha(Colors.surface, 0.25)
    border.color: Colors.withAlpha(Colors.border, 0.5)
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
  }

  ColumnLayout {
    id: col
    spacing: -12

    Text {
      text: Qt.formatDateTime(clock.date, "HH:mm")
      color: Colors.primary
      font.pixelSize: 92
      font.weight: Font.Black
      font.letterSpacing: -4
    }

    Text {
      text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
      color: Colors.text
      font.pixelSize: Colors.fontSizeXXL
      font.weight: Font.Bold
      opacity: 0.9
      Layout.leftMargin: 4
    }
  }
}
