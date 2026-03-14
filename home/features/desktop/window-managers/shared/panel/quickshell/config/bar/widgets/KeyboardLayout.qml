import QtQuick
import "../../services"
import "../../widgets" as SharedWidgets

SharedWidgets.BarPill {
  id: root

  property var widgetInstance: null

  visible: CompositorAdapter.supportsKeyboardLayouts
           && CompositorAdapter.niriKeyboardLayoutNames.length > 1

  tooltipText: "Keyboard layout: " + layoutName + "\nClick to switch"
  onClicked: CompositorAdapter.switchKeyboardLayout()

  readonly property string layoutName: {
    var idx = CompositorAdapter.niriKeyboardLayoutIndex;
    var names = CompositorAdapter.niriKeyboardLayoutNames;
    return (idx >= 0 && idx < names.length) ? names[idx] : "";
  }

  Text {
    anchors.centerIn: parent
    text: root.layoutName.substring(0, 3).toUpperCase()
    color: Colors.text
    font.pixelSize: Colors.fontSizeSmall
    font.family: Colors.fontMono
    font.letterSpacing: Colors.letterSpacingWide
  }
}
