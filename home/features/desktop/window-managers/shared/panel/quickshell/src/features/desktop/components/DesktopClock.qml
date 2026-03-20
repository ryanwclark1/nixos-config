import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../../widgets"

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
    anchors.margins: -Appearance.spacingL
    radius: Appearance.radiusLarge
    color: Colors.cardSurface
    border.color: Colors.withAlpha(Colors.border, 0.5)
    border.width: 1

    gradient: SurfaceGradient {}

    // Inner highlight
    InnerHighlight { }
  }

  ColumnLayout {
    id: col
    spacing: -12

    Text {
      text: Qt.formatDateTime(clock.date, "HH:mm")
      color: Colors.primary
      font.pixelSize: Appearance.fontSizeMassive
      font.weight: Font.Black
      font.letterSpacing: -4
    }

    Text {
      text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
      color: Colors.text
      font.pixelSize: Appearance.fontSizeXXL
      font.weight: Font.Bold
      opacity: 0.9
      Layout.leftMargin: 4
    }
  }
}
