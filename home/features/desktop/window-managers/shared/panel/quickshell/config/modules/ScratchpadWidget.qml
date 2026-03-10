import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../services"

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: root.scratchpadWindows.length > 0 ? col.implicitHeight + 30 : 0
  visible: root.scratchpadWindows.length > 0
  color: Colors.bgWidget
  radius: Colors.radiusMedium
  border.color: Colors.border
  clip: true

  readonly property var scratchpadWindows: {
    var windows = [];
    for (var i = 0; i < Hyprland.toplevels.count; i++) {
      var win = Hyprland.toplevels.get(i);
      var workspaceName = (win.workspace && win.workspace.name) ? win.workspace.name : "";
      if (workspaceName === "special:scratchpad") {
        windows.push(win);
      }
    }
    return windows;
  }

  function summonWindow(address) {
    var targetWorkspace = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.name : "1";
    Quickshell.execDetached(["hyprctl", "dispatch", "movetoworkspace", targetWorkspace + ",address:" + address]);
    Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + address]);
  }

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
      id: contentCol
      Layout.fillWidth: true
      spacing: 6

      Repeater {
        id: scratchRepeater
        model: root.scratchpadWindows

        delegate: Rectangle {
          id: itemRect
          Layout.fillWidth: true; height: 35; color: Colors.highlightLight; radius: 6

          RowLayout {
            anchors.fill: parent; anchors.margins: Colors.paddingSmall; spacing: 10
            Text { text: "󱂬"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 14 }
            Text { text: modelData.title || modelData.class || "Unknown Window"; color: Colors.text; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
            Text { text: "󰁔"; color: Colors.textDisabled; font.family: Colors.fontMono }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.color = Colors.surface
            onExited: parent.color = Colors.highlightLight
            onClicked: root.summonWindow(modelData.address)
          }
        }
      }
    }
  }
}
