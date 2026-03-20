import QtQuick
import QtQuick.Layouts
import "../../../services"
import "."

GridLayout {
  id: root
  columns: 2
  Layout.fillWidth: true
  rowSpacing: Appearance.paddingSmall
  columnSpacing: Appearance.paddingSmall

  property var manager: null
  property bool showContent: false

  Repeater {
    model: ControlCenterRegistry.visibleQuickToggleItems
    delegate: QuickToggle {
      required property var modelData
      icon: modelData.icon
      label: modelData.label
      active: !!root.manager && ControlCenterRegistry.quickToggleActive(modelData.id, root.manager)
      onClicked: {
        if (!root.manager)
          return;
        ControlCenterRegistry.toggleQuickToggle(modelData.id, root.manager);
      }
    }
  }
}
