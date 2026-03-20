import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../../shared"
import "../../../widgets" as SharedWidgets

SharedWidgets.CardBase {
  id: root
  readonly property var allToplevels: CompositorAdapter.toplevels
  Layout.preferredHeight: root.specialWindows.length > 0 ? col.implicitHeight + root.pad * 2 : 0
  visible: CompositorAdapter.supportsScratchpad && root.specialWindows.length > 0

  readonly property var specialWindows: {
    var windows = [];
    if (!CompositorAdapter.supportsScratchpad) return windows;
    for (var i = 0; i < allToplevels.length; i++) {
      var win = allToplevels[i];
      if (!win) continue;
      var workspaceName = (win.workspace && win.workspace.name) ? win.workspace.name : "";
      if (workspaceName.startsWith("special:")) {
        windows.push({
          title: win.title || win.class || "Unknown Window",
          address: win.address || "",
          workspace: workspaceName.substring(8),
          class: win.class || ""
        });
      }
    }
    return windows;
  }

  function toggleWorkspace(wsName) {
    if (!CompositorAdapter.supportsScratchpad) return;
    Quickshell.execDetached(["hyprctl", "dispatch", "togglespecialworkspace", wsName]);
  }

  function summonWindow(address) {
    if (!CompositorAdapter.supportsScratchpad) return;
    var targetWorkspace = "1";
    CompositorAdapter.moveWindowToWorkspace(address, targetWorkspace);
    CompositorAdapter.focusWindow(address);
  }

  ColumnLayout {
    id: col
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Colors.paddingSmall

    Text {
      text: "SPECIAL WORKSPACES"
      color: Colors.textDisabled
      font.pixelSize: Colors.fontSizeXS
      font.weight: Font.Bold
      font.capitalization: Font.AllUppercase
    }

    ColumnLayout {
      id: contentCol
      Layout.fillWidth: true
      spacing: Colors.spacingSM

      Repeater {
        id: scratchRepeater
        model: root.specialWindows

        delegate: Rectangle {
          id: itemRect
          Layout.fillWidth: true
          color: scratchHover.containsMouse ? Colors.primarySubtle : Colors.cardSurface
          border.color: Colors.border
          border.width: 1
          radius: Colors.radiusXXS
          implicitHeight: scratchRow.implicitHeight + Colors.paddingSmall * 2
          Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }

          SharedWidgets.InnerHighlight { hoveredOpacity: 0.25; hovered: scratchHover.containsMouse }

          RowLayout {
            id: scratchRow
            anchors.fill: parent; anchors.margins: Colors.paddingSmall; spacing: Colors.paddingSmall
            Text { text: "󰐃"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium; Layout.alignment: Qt.AlignTop }
            ColumnLayout {
              Layout.fillWidth: true
              spacing: Colors.spacingXXS
              Text {
                text: modelData.title
                color: Colors.text
                font.pixelSize: Colors.fontSizeSmall
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
              }
              Text {
                text: modelData.workspace
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                font.capitalization: Font.Capitalize
              }
            }
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
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
              scratchStateLayer.burst(mouse.x, mouse.y);
              if (mouse.button === Qt.RightButton)
                root.toggleWorkspace(modelData.workspace);
              else
                root.summonWindow(modelData.address);
            }
          }
        }
      }
    }
  }
}
