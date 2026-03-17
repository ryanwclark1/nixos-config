import QtQuick
import QtQuick.Layouts
import "../services"
import "../system/sections"

GridLayout {
  id: root
  columns: 2
  Layout.fillWidth: true
  rowSpacing: Colors.paddingSmall
  columnSpacing: Colors.paddingSmall

  property var manager: null
  property bool showContent: false
  property int baseIndex: 2
  property int staggerDelay: 35

  opacity: showContent ? 1.0 : 0.0
  scale: showContent ? 1.0 : 0.96
  transform: Translate { y: showContent ? 0 : 8 }
  visible: opacity > 0

  Behavior on opacity { SequentialAnimation { PauseAnimation { duration: showContent ? (root.baseIndex * root.staggerDelay) : 0 } NumberAnimation { duration: Colors.durationNormal + (root.baseIndex * 20); easing.type: Easing.OutCubic } } }
  Behavior on scale { SequentialAnimation { PauseAnimation { duration: showContent ? (root.baseIndex * root.staggerDelay) : 0 } NumberAnimation { duration: Colors.durationNormal + (root.baseIndex * 20); easing.type: Easing.OutBack } } }
  Behavior on transform { SequentialAnimation { PauseAnimation { duration: showContent ? (root.baseIndex * root.staggerDelay) : 0 } NumberAnimation { duration: Colors.durationNormal + (root.baseIndex * 20); easing.type: Easing.OutCubic } } }

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
