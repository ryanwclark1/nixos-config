import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../services"

Rectangle {
  id: taskItem
  width: 32; height: 32; radius: 8
  color: isFocused ? Colors.highlight : (mouseArea.containsMouse ? Colors.highlightLight : "transparent")
  border.color: isFocused ? Colors.primary : "transparent"; border.width: 1
  clip: true

  property string appClass: ""
  property string appAddress: ""
  property string appExec: ""
  property string appName: ""
  property bool isFocused: false
  property bool isPinned: false
  
  // Find running instance if it's a pinned app
  property var runningInstance: {
    if (!isPinned) return null;
    for (var i = 0; i < Hyprland.toplevels.count; i++) {
      var t = Hyprland.toplevels.get(i);
      if (t.class === appClass) return t;
    }
    return null;
  }
  
  readonly property bool isRunning: isPinned ? runningInstance !== null : true
  readonly property bool actualFocused: isPinned ? (runningInstance && runningInstance.focused) : isFocused

  // Running indicator dot
  Rectangle {
    width: 4; height: 4; radius: 2; color: taskItem.actualFocused ? Colors.primary : Colors.textDisabled
    anchors.bottom: parent.bottom; anchors.bottomMargin: 2; anchors.horizontalCenter: parent.horizontalCenter
    visible: isRunning
  }

  IconImage {
    id: taskIcon
    anchors.centerIn: parent; implicitWidth: 20; implicitHeight: 20
    property string iconPath: {
        var cls = (appClass || "").toLowerCase();
        var path = Quickshell.iconPath(cls);
        if (!path) path = Quickshell.iconPath("application-x-executable");
        return path || "";
    }
    source: iconPath; visible: status === IconImage.Ready && source != ""
    Text {
      anchors.centerIn: parent; text: appClass ? appClass.charAt(0).toUpperCase() : "?"; color: Colors.fgMain; font.pixelSize: 14; visible: !taskIcon.visible
    }
  }

  MouseArea {
    id: mouseArea; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (mouse) => {
      if (mouse.button === Qt.LeftButton) {
        if (isRunning) {
          var addr = isPinned ? runningInstance.address : appAddress;
          Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + addr]);
        } else if (isPinned && appExec) {
          Quickshell.execDetached(appExec.split(" "));
        }
      } else if (mouse.button === Qt.RightButton) {
        root.togglePin({ class: appClass, title: appName });
      }
    }
  }
}
