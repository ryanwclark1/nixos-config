import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../services"

PopupWindow {
  id: root
  implicitWidth: 360
  implicitHeight: 480
  readonly property color panelSurface: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.96)
  readonly property color cardSurface: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.82)

  property var clipboardItems: []
  property string searchQuery: ""

  function refresh() {
    if (!clipProcess.running) clipProcess.running = true;
  }

  readonly property var filteredItemsResult: {
    if (!searchQuery) return clipboardItems;
    var q = searchQuery.toLowerCase();
    var result = [];
    for (var i = 0; i < clipboardItems.length; i++) {
      if (clipboardItems[i].content.toLowerCase().indexOf(q) !== -1)
        result.push(clipboardItems[i]);
    }
    return result;
  }

  Process {
    id: clipProcess
    command: ["qs-clip"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var parsed = JSON.parse(this.text || "[]");
          root.clipboardItems = parsed;
        } catch (e) {
          root.clipboardItems = [];
        }
      }
    }
  }

  Timer {
    interval: 5000
    running: root.visible
    repeat: true
    onTriggered: root.refresh()
  }

  onVisibleChanged: if (visible) refresh()

  Rectangle {
    anchors.fill: parent
    color: root.panelSurface
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusMedium
    clip: true

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Colors.paddingLarge
      spacing: 12

      // Header
      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "Clipboard"
          color: Colors.fgMain
          font.pixelSize: 18
          font.weight: Font.DemiBold
        }
        Item { Layout.fillWidth: true }
        Rectangle {
          width: 30; height: 30; radius: 15
          color: clearAllHover.containsMouse ? Colors.withAlpha(Colors.error, 0.2) : "transparent"
          Text {
            anchors.centerIn: parent
            text: "󰃢"
            color: clearAllHover.containsMouse ? Colors.error : Colors.textSecondary
            font.family: Colors.fontMono
            font.pixelSize: 16
          }
          MouseArea {
            id: clearAllHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              Quickshell.execDetached(["sh", "-c", "cliphist wipe"]);
              root.clipboardItems = [];
            }
          }
        }
        Rectangle {
          width: 30; height: 30; radius: 15
          color: closeHover.containsMouse ? Colors.highlightLight : "transparent"
          Text {
            anchors.centerIn: parent
            text: "󰅖"
            color: Colors.textSecondary
            font.family: Colors.fontMono
            font.pixelSize: 16
          }
          MouseArea {
            id: closeHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "toggleClipboardMenu"])
          }
        }
      }

      // Search bar
      Rectangle {
        Layout.fillWidth: true
        height: 36
        radius: height / 2
        color: Colors.bgWidget
        border.color: searchInput.activeFocus ? Colors.primary : Colors.border
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 12
          spacing: 8

          Text {
            text: "󰍉"
            color: Colors.textDisabled
            font.family: Colors.fontMono
            font.pixelSize: 14
          }

          TextInput {
            id: searchInput
            Layout.fillWidth: true
            color: Colors.fgMain
            font.pixelSize: 13
            clip: true
            onTextChanged: root.searchQuery = text

            Text {
              anchors.fill: parent
              text: "Search clipboard..."
              color: Colors.textDisabled
              font.pixelSize: 13
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
      Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: itemsColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
          id: itemsColumn
          width: parent.width
          spacing: 6

          Repeater {
            model: root.filteredItemsResult
            delegate: Rectangle {
              id: clipCard
              Layout.fillWidth: true
              implicitHeight: clipContent.implicitHeight + 20
              radius: Colors.radiusSmall
              color: clipMouse.containsMouse ? Colors.highlightLight : root.cardSurface
              border.color: Colors.border
              border.width: 1
              Behavior on color { ColorAnimation { duration: 150 } }

              RowLayout {
                id: clipContent
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Text {
                  text: modelData.content || ""
                  color: Colors.fgMain
                  font.pixelSize: 12
                  Layout.fillWidth: true
                  maximumLineCount: 2
                  elide: Text.ElideRight
                  wrapMode: Text.WrapAnywhere
                }

                Rectangle {
                  width: 24; height: 24; radius: 12
                  color: deleteHover.containsMouse ? Colors.withAlpha(Colors.error, 0.2) : "transparent"
                  Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: deleteHover.containsMouse ? Colors.error : Colors.textDisabled
                    font.family: Colors.fontMono
                    font.pixelSize: 12
                  }
                  MouseArea {
                    id: deleteHover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
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
                onClicked: {
                  var safeId = parseInt(modelData.id, 10);
                  if (!isNaN(safeId)) Quickshell.execDetached(["sh", "-c", "cliphist decode " + safeId + " | wl-copy"]);
                  Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "toggleClipboardMenu"]);
                }
              }
            }
          }

          // Empty state
          Rectangle {
            Layout.fillWidth: true
            visible: root.filteredItemsResult.length === 0
            implicitHeight: 60
            radius: Colors.radiusMedium
            color: root.cardSurface
            border.color: Colors.border
            border.width: 1
            Text {
              anchors.centerIn: parent
              text: root.searchQuery ? "No matching items" : "Clipboard is empty"
              color: Colors.textDisabled
              font.pixelSize: 12
            }
          }
        }
      }
    }
  }
}
