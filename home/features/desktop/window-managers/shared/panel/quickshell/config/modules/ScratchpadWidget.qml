import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../widgets" as SharedWidgets

SharedWidgets.CardBase {
  id: root
  readonly property var allToplevels: CompositorAdapter.toplevels
  Layout.preferredHeight: root.scratchpadWindows.length > 0 ? col.implicitHeight + root.pad * 2 : 0
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
    CompositorAdapter.moveWindowToWorkspace(address, targetWorkspace);
    CompositorAdapter.focusWindowAddress(address);
  }

  ColumnLayout {
    id: col
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Colors.paddingSmall

    Text {
      text: "SCRATCHPAD WINDOWS"
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
        model: root.scratchpadWindows

        delegate: Rectangle {
          id: itemRect
          Layout.fillWidth: true
          color: scratchHover.containsMouse ? Colors.withAlpha(Colors.primary, 0.12) : Colors.cardSurface
          border.color: Colors.border
          border.width: 1
          radius: Colors.radiusXXS
          implicitHeight: scratchRow.implicitHeight + Colors.paddingSmall * 2
          Behavior on color { ColorAnimation { duration: Colors.durationFast } }

          SharedWidgets.InnerHighlight { hoveredOpacity: 0.25; hovered: scratchHover.containsMouse }

          RowLayout {
            id: scratchRow
            anchors.fill: parent; anchors.margins: Colors.paddingSmall; spacing: Colors.paddingSmall
            Text { text: "󱂬"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium; Layout.alignment: Qt.AlignTop }
            Text {
              text: modelData.title || modelData.class || "Unknown Window"
              color: Colors.text
              font.pixelSize: Colors.fontSizeSmall
              Layout.fillWidth: true
              wrapMode: Text.Wrap
              maximumLineCount: 2
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
