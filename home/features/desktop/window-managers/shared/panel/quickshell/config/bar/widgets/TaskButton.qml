import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../services"
import "../../widgets" as SharedWidgets

Rectangle {
  id: taskItem
  width: 32; height: 32; radius: 8
  color: isFocused ? Colors.highlight : (mouseArea.containsMouse ? Colors.highlightLight : "transparent")
  border.color: isFocused ? Colors.primary : "transparent"; border.width: 1
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
  readonly property var iconAliases: ({
    "alacritty": ["utilities-terminal", "terminal", "org.gnome.Console"],
    "org.alacritty.alacritty": ["utilities-terminal", "terminal", "org.gnome.Console"],
    "org.gnome.nautilus": ["system-file-manager", "folder", "inode-directory"],
    "nautilus": ["system-file-manager", "folder", "inode-directory"],
    "com.mitchellh.ghostty": ["com.mitchellh.ghostty"],
    "ghostty": ["com.mitchellh.ghostty"]
  })
  
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
  Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

  // Running indicator dot
  Rectangle {
    width: 4; height: 4; radius: 2; color: taskItem.actualFocused ? Colors.primary : Colors.textDisabled
    anchors.bottom: parent.bottom; anchors.bottomMargin: 2; anchors.horizontalCenter: parent.horizontalCenter
    visible: isRunning
  }

  Image {
    id: taskIcon
    anchors.centerIn: parent; width: 20; height: 20
    sourceSize.width: 64; sourceSize.height: 64
    fillMode: Image.PreserveAspectFit
    property string sourceUrl: {
        if (!resolvedPath) return "";
        if (resolvedPath.startsWith("/") || resolvedPath.startsWith("file://")) return resolvedPath.startsWith("file://") ? resolvedPath : "file://" + resolvedPath;
        return resolvedPath;
    }
    property string resolvedPath: {
        var cls = (appClass || "").toLowerCase();
        var execName = (appExec || "").toLowerCase();
        var aliases = iconAliases[cls] || iconAliases[execName] || [];
        // Prefer stable alias icons before app-specific SVGs that may be broken.
        for (var i = 0; i < aliases.length; ++i) {
            var alias = aliases[i];
            if (iconMap[alias]) return iconMap[alias];
        }
        // Try icon map from qs-icon-resolver (class, exec, various keys)
        if (cls && iconMap[cls]) return iconMap[cls];
        if (execName && iconMap[execName]) return iconMap[execName];
        // Try Quickshell.iconPath as fallback
        for (var j = 0; j < aliases.length; ++j) {
            var p3 = Config.resolveIconPath(aliases[j]);
            if (p3) return p3;
        }
        if (cls) { var p = Config.resolveIconPath(cls); if (p) return p; }
        if (execName && execName !== cls) { var p2 = Config.resolveIconPath(execName); if (p2) return p2; }
        return "";
    }
    source: sourceUrl
    visible: status === Image.Ready && source != ""
  }

  Text {
    anchors.centerIn: parent
    text: "󰀻"
    color: Colors.fgMain
    font.family: Colors.fontMono
    font.pixelSize: 16
    visible: !taskIcon.visible
  }

  MouseArea {
    id: mouseArea; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton
    
    onClicked: (mouse) => {
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
