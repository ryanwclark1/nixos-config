import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../services"
import "../../widgets" as SharedWidgets

Rectangle {
  id: taskItem
  width: 32; height: 32; radius: Colors.radiusXS
  color: actualFocused ? Colors.highlight : "transparent"
  border.color: actualFocused ? Colors.primary : "transparent"; border.width: 1
  clip: true
  scale: mouseArea.containsMouse ? 1.06 : 1.0

  property string appClass: ""
  property string appAddress: ""
  property string appExec: ""
  property string appName: ""
  property bool isFocused: false
  property bool isPinned: false
  property var anchorWindow: null
  property var iconMap: ({})
  
  signal pinToggled(var app)

  // Find running instance if it's a pinned app
  property var runningInstance: {
    if (!isPinned) return null;
    for (var i = 0; i < Hyprland.toplevels.count; i++) {
      var t = Hyprland.toplevels.get(i);
      if (!t) continue;
      if (t.class === appClass) return t;
    }
    return null;
  }
  
  readonly property bool isRunning: isPinned ? runningInstance !== null : true
  readonly property bool actualFocused: isPinned ? (runningInstance && runningInstance.focused) : isFocused
  readonly property string tooltipText: {
    if ((appName || "").trim().length > 0) return appName;
    if ((appClass || "").trim().length > 0) return appClass;
    if ((appExec || "").trim().length > 0) return appExec;
    return isPinned ? "Pinned app" : "Running app";
  }

  Behavior on color { ColorAnimation { duration: 160 } }
  Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

  // Running indicator dot
  Rectangle {
    width: 4; height: 4; radius: 2; color: taskItem.actualFocused ? Colors.primary : Colors.textDisabled
    anchors.bottom: parent.bottom; anchors.bottomMargin: 2; anchors.horizontalCenter: parent.horizontalCenter
    visible: isRunning
  }

  SharedWidgets.AppIcon {
    anchors.centerIn: parent
    iconName: taskItem.appClass || taskItem.appExec || ""
    appName: taskItem.appName || taskItem.appClass || ""
    iconSize: 20
    iconMap: taskItem.iconMap
    fallbackIcon: "󰀻"
  }

  SharedWidgets.StateLayer {
    id: stateLayer
    hovered: mouseArea.containsMouse
    pressed: mouseArea.pressed
    stateColor: Colors.primary
  }

  MouseArea {
    id: mouseArea; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: (mouse) => {
      stateLayer.burst(mouse.x, mouse.y);
      if (mouse.button === Qt.LeftButton) {
        if (isRunning) {
          var addr = isPinned ? runningInstance.address : appAddress;
          Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + addr]);
        } else if (isPinned && appExec) {
          Quickshell.execDetached(["sh", "-c", appExec]);
        }
      } else if (mouse.button === Qt.RightButton) {
        taskItem.pinToggled({ class: appClass, title: appName, exec: appExec });
      }
    }
  }

  SharedWidgets.BarTooltip {
    anchorItem: taskItem
    anchorWindow: taskItem.anchorWindow
    hovered: mouseArea.containsMouse
    text: taskItem.tooltipText
  }
}
