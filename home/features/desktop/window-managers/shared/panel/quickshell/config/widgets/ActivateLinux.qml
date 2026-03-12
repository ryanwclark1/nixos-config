import QtQuick
import Quickshell
import Quickshell.Widgets
import "../services"

PanelWindow {
  id: root
  anchors {
    bottom: true
    right: true
  }
  margins.bottom: 60
  margins.right: 60

  implicitWidth: 250
  implicitHeight: 80
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  mask: Region {
    item: content
  }

  Column {
    id: content
    anchors.fill: parent
    spacing: Colors.spacingXS

    Text {
      text: "Activate Linux"
      color: Colors.withAlpha(Colors.text, 0.5)
      font.pixelSize: Colors.fontSizeHuge
      font.family: "Cantarell, sans-serif"
    }

    Text {
      text: "Go to Settings to activate Linux."
      color: Colors.withAlpha(Colors.text, 0.5)
      font.pixelSize: Colors.fontSizeMedium
      font.family: "Cantarell, sans-serif"
    }
  }
}
