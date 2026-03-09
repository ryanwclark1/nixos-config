import QtQuick
import Quickshell

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

  Column {
    anchors.fill: parent
    spacing: 4

    Text {
      text: "Activate Linux"
      color: "#80ffffff" // Semi-transparent white
      font.pixelSize: 24
      font.family: "Cantarell, sans-serif"
    }

    Text {
      text: "Go to Settings to activate Linux."
      color: "#80ffffff" // Semi-transparent white
      font.pixelSize: 14
      font.family: "Cantarell, sans-serif"
    }
  }
}
