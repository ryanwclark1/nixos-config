import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Row {
  id: root
  spacing: 10
  anchors.verticalCenter: parent.verticalCenter

  Repeater {
    model: Hyprland.toplevels

    Rectangle {
      // Only show windows on current workspace to keep bar clean
      visible: modelData.workspace && modelData.workspace.active
      width: visible ? 28 : 0
      height: 28
      radius: 6
      color: modelData.focused ? "#334caf50" : "#1affffff"
      border.color: modelData.focused ? "#4caf50" : "transparent"
      border.width: 1
      clip: true

      // Icon placeholder (Ideally we'd map class names to icons)
      Text {
        anchors.centerIn: parent
        text: {
           var cls = (modelData.class || "").toLowerCase();
           if (cls.includes("kitty")) return "";
           if (cls.includes("firefox")) return "󰈹";
           if (cls.includes("discord")) return "";
           if (cls.includes("spotify")) return "󰓇";
           if (cls.includes("nemo")) return "󰉋";
           if (cls.includes("code")) return "󰨞";
           return "󰖲";
        }
        color: modelData.focused ? "#ffffff" : "#aaaaaa"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: modelData.focus()
        
        onEntered: {
           // We could show a tiny tooltip or preview here
        }
      }
    }
  }
}
