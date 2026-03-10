import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../services"

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: scratchRepeater.count > 0 ? col.implicitHeight + 30 : 0
  visible: scratchRepeater.count > 0
  color: Colors.bgWidget
  radius: Colors.radiusMedium
  border.color: Colors.border
  clip: true

  ColumnLayout {
    id: col
    anchors.fill: parent
    anchors.margins: Colors.paddingMedium
    spacing: 10

    Text { 
      text: "SCRATCHPAD WINDOWS"
      color: Colors.textDisabled
      font.pixelSize: 8
      font.weight: Font.Bold
      font.capitalization: Font.AllUppercase
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      Repeater {
        id: scratchRepeater
        model: Hyprland.toplevels
        
        delegate: Rectangle {
          // Filter for windows in the 'special' workspace
          visible: modelData.workspace && modelData.workspace.name.startsWith("special")
          width: parent.width; height: visible ? 35 : 0
          color: Colors.highlightLight; radius: 6
          
          RowLayout {
            anchors.fill: parent; anchors.margins: Colors.paddingSmall; spacing: 10
            Text { text: "󱂬"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 14 }
            Text { text: modelData.title || "Unknown Window"; color: Colors.text; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
            Text { text: "󰁔"; color: Colors.textDisabled; font.family: Colors.fontMono }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.color = Colors.surface
            onExited: parent.color = Colors.highlightLight
            onClicked: {
               // Summon the window to the current workspace
               Quickshell.execDetached(["hyprctl", "dispatch", "movetoworkspace", "current,address:" + modelData.address]);
               Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + modelData.address]);
            }
          }
        }
      }
    }
  }
}
