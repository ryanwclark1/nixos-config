import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../services"

Row {
  id: root
  spacing: 10
  anchors.verticalCenter: parent.verticalCenter

  Repeater {
    model: Hyprland.toplevels

    Rectangle {
      // Only show windows on current workspace
      visible: modelData.workspace && modelData.workspace.active
      width: visible ? 32 : 0
      height: 32
      radius: 8
      color: modelData.focused ? Colors.highlight : "transparent"
      border.color: modelData.focused ? Colors.primary : "transparent"
      border.width: 1
      clip: true

      IconImage {
        id: taskIcon
        anchors.centerIn: parent
        implicitWidth: 20
        implicitHeight: 20
        
        // Use a function to safely check for the icon path
        property string iconPath: {
            var cls = (modelData.class || "").toLowerCase();
            var path = Quickshell.iconPath(cls);
            if (!path) path = Quickshell.iconPath("application-x-executable");
            return path || "";
        }
        
        source: iconPath
        
        // When source is empty or status is not ready, hide the IconImage 
        // to prevent pink checkerboards in some Quickshell versions.
        visible: status === IconImage.Ready && source != ""

        // Fallback to initial if icon not found
        Text {
          anchors.centerIn: parent
          text: modelData.class ? modelData.class.charAt(0).toUpperCase() : "?"
          color: Colors.fgMain
          font.pixelSize: 14
          visible: !taskIcon.visible
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
          if (modelData.address) {
            Quickshell.execDetached([
              "hyprctl",
              "dispatch",
              "focuswindow",
              "address:" + modelData.address
            ]);
          }
        }
        
        onEntered: parent.color = Colors.highlightLight
        onExited: parent.color = modelData.focused ? Colors.highlight : "transparent"
      }
    }
  }
}
