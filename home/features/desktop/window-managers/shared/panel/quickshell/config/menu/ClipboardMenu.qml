import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMaxWidth: 360; compactThreshold: 350
  implicitHeight: compactMode ? 520 : 480
  title: "Clipboard"
  toggleMethod: "toggleClipboardMenu"
  contentSpacing: Colors.spacingM
  focusOnOpen: true
  initialFocusTarget: searchInput

  property var clipboardItems: []
  property string searchQuery: ""

  function refresh() {
    clipPoll.poll();
  }

  readonly property var filteredItemsResult: {
    if (!searchQuery) return clipboardItems;
    var q = searchQuery.toLowerCase();
    var result = [];
    for (var i = 0; i < clipboardItems.length; i++) {
      if (clipboardItems[i] && clipboardItems[i].content && clipboardItems[i].content.toLowerCase().indexOf(q) !== -1)
        result.push(clipboardItems[i]);
    }
    return result;
  }

  SharedWidgets.CommandPoll {
    id: clipPoll
    interval: 5000
    running: root.visible
    command: ["qs-clip"]
    parse: function(out) { try { return JSON.parse(out || "[]") } catch(e) { return [] } }
    onUpdated: root.clipboardItems = clipPoll.value || []
  }

  onVisibleChanged: {
    if (visible) refresh();
    else if (searchInput.activeFocus) searchInput.focus = false;
  }

  headerExtras: [
    SharedWidgets.IconButton {
      icon: "󰃢"
      onClicked: {
        Quickshell.execDetached(["sh", "-c", "cliphist wipe"]);
        root.clipboardItems = [];
      }
    }
  ]

  // Search bar
  Rectangle {
    Layout.fillWidth: true
    height: root.compactMode ? 34 : 36
    radius: height / 2
    color: Colors.bgWidget
    border.color: searchInput.activeFocus ? Colors.primary : Colors.border
    border.width: 1

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Colors.spacingM
      anchors.rightMargin: Colors.spacingM
      spacing: Colors.spacingS

      Text {
        text: "󰍉"
        color: Colors.textDisabled
        font.family: Colors.fontMono
        font.pixelSize: Colors.fontSizeMedium
      }

      TextInput {
        id: searchInput
        Layout.fillWidth: true
        color: Colors.text
        font.pixelSize: Colors.fontSizeMedium
        clip: true
        Keys.onEscapePressed: root.closeRequested()
        onTextChanged: root.searchQuery = text

        Text {
          anchors.fill: parent
          text: "Search clipboard..."
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeMedium
          visible: !searchInput.text && !searchInput.activeFocus
          verticalAlignment: Text.AlignVCenter
        }
      }
    }
  }

  Rectangle {
    Layout.fillWidth: true
    height: 1
    color: Colors.border
  }

  // Clipboard items list
  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Colors.spacingS

      Repeater {
        model: root.filteredItemsResult
        delegate: Rectangle {
          id: clipCard
          Layout.fillWidth: true
          implicitHeight: clipContent.implicitHeight + 20
          radius: Colors.radiusSmall
          color: Colors.cardSurface
          border.color: Colors.border
          border.width: 1

          SharedWidgets.StateLayer {
            id: clipStateLayer
            hovered: clipMouse.containsMouse
            pressed: clipMouse.pressed
          }

          RowLayout {
            id: clipContent
            anchors.fill: parent
            anchors.margins: Colors.paddingSmall
            spacing: Colors.spacingS

            Text {
              text: modelData.content || ""
              color: Colors.text
              font.pixelSize: Colors.fontSizeSmall
              Layout.fillWidth: true
              maximumLineCount: 2
              elide: Text.ElideRight
              wrapMode: Text.WrapAnywhere
            }

            Rectangle {
              width: 24; height: 24; radius: Colors.radiusCard
              color: "transparent"
              Text {
                anchors.centerIn: parent
                text: "󰅖"
                color: deleteHover.containsMouse ? Colors.error : Colors.textDisabled
                Behavior on color { ColorAnimation { duration: Colors.durationFast } }
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeSmall
              }
              SharedWidgets.StateLayer {
                id: deleteStateLayer
                hovered: deleteHover.containsMouse
                pressed: deleteHover.pressed
                stateColor: Colors.error
              }
              MouseArea {
                id: deleteHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                  deleteStateLayer.burst(mouse.x, mouse.y);
                  Quickshell.execDetached(["sh", "-c", "cliphist list | grep -F -- \"$1\" | head -1 | cliphist delete", "--", modelData.content || ""]);
                  root.refresh();
                }
              }
            }
          }

          MouseArea {
            id: clipMouse
            anchors.fill: parent
            anchors.rightMargin: 36
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
              clipStateLayer.burst(mouse.x, mouse.y);
              var safeId = parseInt(modelData.id, 10);
              if (!isNaN(safeId)) Quickshell.execDetached(["sh", "-c", "cliphist decode " + safeId + " | wl-copy"]);
              Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "toggleClipboardMenu"]);
            }
          }
        }
      }

      // Empty state
      SharedWidgets.EmptyState {
        Layout.fillWidth: true
        Layout.topMargin: Colors.spacingS
        Layout.bottomMargin: Colors.spacingS
        visible: root.filteredItemsResult.length === 0
        icon: root.searchQuery ? "󰍉" : "󰅗"
        message: root.searchQuery ? "No matching items" : "Clipboard is empty"
      }
  }
}
