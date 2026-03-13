import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../widgets" as SharedWidgets

SharedWidgets.CardBase {
  id: root
  readonly property var allToplevels: (typeof ToplevelManager !== "undefined" && ToplevelManager.toplevels) ? (ToplevelManager.toplevels.values || []) : []
  Layout.preferredHeight: root.scratchpadWindows.length > 0 ? col.implicitHeight + 30 : 0
  visible: CompositorAdapter.supportsScratchpad && root.scratchpadWindows.length > 0

  readonly property var scratchpadWindows: {
    var windows = [];
    if (!CompositorAdapter.supportsScratchpad) return windows;
    for (var i = 0; i < allToplevels.length; i++) {
      var win = allToplevels[i];
      if (!win) continue;
      var workspaceName = (win.workspace && win.workspace.name) ? win.workspace.name : "";
      if (workspaceName === "special:scratchpad") {
        windows.push(win);
      }
    }
    return windows;
  }

  function summonWindow(address) {
    if (!CompositorAdapter.supportsScratchpad) return;
    var targetWorkspace = "1";
    Quickshell.execDetached(["hyprctl", "dispatch", "movetoworkspace", targetWorkspace + ",address:" + address]);
    Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + address]);
  }

  ColumnLayout {
    id: col
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Colors.paddingSmall

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
          Layout.fillWidth: true; height: 35
          color: Colors.highlightLight
          radius: 6

          RowLayout {
            anchors.fill: parent; anchors.margins: Colors.paddingSmall; spacing: Colors.paddingSmall
            Text { text: "󱂬"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium }
            Text { text: modelData.title || modelData.class || "Unknown Window"; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; Layout.fillWidth: true; elide: Text.ElideRight }
            Text { text: "󰁔"; color: Colors.textDisabled; font.family: Colors.fontMono }
          }

          SharedWidgets.StateLayer {
            id: scratchStateLayer
            anchors.fill: parent
            radius: parent.radius
            hovered: scratchHover.containsMouse
            pressed: scratchHover.pressed
          }

          MouseArea {
            id: scratchHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
              scratchStateLayer.burst(mouse.x, mouse.y);
              root.summonWindow(modelData.address);
            }
          }
        }
      }
    }
  }
}
