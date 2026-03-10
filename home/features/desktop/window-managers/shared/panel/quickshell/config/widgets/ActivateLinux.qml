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
    spacing: 4

    Text {
      text: "Activate Linux"
      color: Colors.withAlpha(Colors.text, 0.5)
      font.pixelSize: 24
      font.family: "Cantarell, sans-serif"
    }

    Text {
      text: "Go to Settings to activate Linux."
      color: Colors.withAlpha(Colors.text, 0.5)
      font.pixelSize: 14
      font.family: "Cantarell, sans-serif"
    }
  }
}
