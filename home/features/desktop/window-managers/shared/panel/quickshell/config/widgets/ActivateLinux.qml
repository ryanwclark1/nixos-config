import QtQuick
import Quickshell
import Quickshell.Widgets
import "../services"

PanelWindow {
  id: root
  property var screenRef: Quickshell.cursorScreen || Config.primaryScreen()
  screen: screenRef
  readonly property var edgeMargins: Config.reservedEdgesForScreen(screenRef, "")
  anchors {
    bottom: true
    right: true
  }
  margins.bottom: edgeMargins.bottom + 20
  margins.right: edgeMargins.right + 20

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
