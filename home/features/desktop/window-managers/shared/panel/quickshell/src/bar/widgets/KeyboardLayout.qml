import QtQuick
import "../../services"
import "../../widgets" as SharedWidgets

SharedWidgets.BarPill {
  id: root

  property var widgetInstance: null
  property bool vertical: false
  readonly property var widgetSettings: widgetInstance && widgetInstance.settings ? widgetInstance.settings : ({})
  readonly property string labelMode: {
    var mode = String(widgetSettings.labelMode || "short");
    return ["short", "full"].indexOf(mode) !== -1 ? mode : "short";
  }

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
    text: (root.vertical || root.labelMode !== "full") ? root.layoutName.substring(0, 3).toUpperCase() : root.layoutName
    color: Colors.text
    font.pixelSize: Appearance.fontSizeSmall
    font.family: Appearance.fontMono
    font.letterSpacing: Appearance.letterSpacingWide
  }
}
