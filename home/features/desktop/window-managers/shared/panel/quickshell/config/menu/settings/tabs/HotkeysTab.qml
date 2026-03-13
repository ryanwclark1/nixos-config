import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../services"
import "../../../widgets" as SharedWidgets
import ".."

Item {
  id: root
  property var settingsRoot: null
  property string tabId: ""

  property var keybindsList: []
  property string keybindsFilter: ""

  Process {
    id: hyprBindsProc
    command: ["hyprctl", "binds", "-j"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var raw = JSON.parse(this.text || "[]");
          var result = [];
          for (var i = 0; i < raw.length; i++) {
            var b = raw[i];
            var mods = (b.modmask !== undefined && b.modmask !== 0) ? b.modString || "" : "";
            result.push({
              mods: mods,
              key: b["key"] || "",
              dispatcher: b.dispatcher || "",
              arg: b.arg || ""
            });
          }
          root.keybindsList = result;
        } catch (e) {
          console.error("Failed to parse hyprctl binds: " + e);
        }
      }
    }
  }

  Component.onCompleted: {
    if (!hyprBindsProc.running) hyprBindsProc.running = true;
  }

  SettingsTabPage {
    anchors.fill: parent
    tabId: root.tabId
    title: "Keybindings"
    iconName: "󱕴"

    SettingsCard {
      title: "Search"
      iconName: "󰍉"

      Rectangle {
        Layout.fillWidth: true
        height: 40
        radius: Colors.radiusSmall
        color: Colors.bgWidget
        border.color: keybindsSearch.activeFocus ? Colors.primary : Colors.border
        border.width: 1
        Behavior on border.color {
          ColorAnimation { duration: 150 }
        }

        RowLayout {
          anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 12
          }
          spacing: Colors.spacingS

          Text {
            text: "󰍉"
            color: Colors.fgDim
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeXL
          }

          TextInput {
            id: keybindsSearch
            Layout.fillWidth: true
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            onTextChanged: root.keybindsFilter = text.toLowerCase()

            Text {
              anchors.fill: parent
              text: "Search keybindings..."
              color: Colors.fgDim
              font.pixelSize: parent.font.pixelSize
              visible: parent.text.length === 0
            }
          }

          Text {
            text: "󰅖"
            color: Colors.fgDim
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeLarge
            visible: keybindsSearch.text.length > 0

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: keybindsSearch.text = ""
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 42
        radius: Colors.radiusSmall
        color: Colors.bgWidget
        border.color: Colors.border
        border.width: 1

        SharedWidgets.StateLayer {
          id: kbRefreshStateLayer
          hovered: kbRefreshHover.containsMouse
          pressed: kbRefreshHover.pressed
        }

        RowLayout {
          anchors.centerIn: parent
          spacing: Colors.spacingS
          Text {
            text: "󰑐"
            color: Colors.fgSecondary
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeLarge
          }
          Text {
            text: "Refresh"
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
          }
        }

        MouseArea {
          id: kbRefreshHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: (mouse) => {
            kbRefreshStateLayer.burst(mouse.x, mouse.y);
            root.keybindsList = [];
            hyprBindsProc.running = true;
          }
        }
      }
    }

    SettingsCard {
      title: "Bindings"
      iconName: "󰌌"

      Text {
        visible: root.keybindsList.length === 0
        text: "Loading keybindings…"
        color: Colors.fgDim
        font.pixelSize: Colors.fontSizeMedium
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 20
      }

      Repeater {
        model: {
          var filter = root.keybindsFilter;
          var list = root.keybindsList;
          if (!filter) return list;
          return list.filter(function(b) {
            var haystack = (b.mods + " " + b["key"] + " " + b.dispatcher + " " + b.arg).toLowerCase();
            return haystack.indexOf(filter) !== -1;
          });
        }

        delegate: Rectangle {
          Layout.fillWidth: true
          implicitHeight: kbRow.implicitHeight + 16
          radius: Colors.radiusXS
          color: Colors.bgWidget
          border.color: Colors.border
          border.width: 1

          RowLayout {
            id: kbRow
            anchors {
              left: parent.left
              right: parent.right
              verticalCenter: parent.verticalCenter
              leftMargin: Colors.spacingM
              rightMargin: Colors.spacingM
            }
            spacing: Colors.spacingM

            Rectangle {
              implicitWidth: chordText.implicitWidth + 16
              height: 26
              radius: 6
              color: Colors.highlight
              border.color: Colors.primary
              border.width: 1

              Text {
                id: chordText
                anchors.centerIn: parent
                text: {
                  var parts = [];
                  if (modelData.mods) parts.push(modelData.mods);
                  if (modelData["key"]) parts.push(modelData["key"]);
                  return parts.join(" + ");
                }
                color: Colors.primary
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeSmall
                font.weight: Font.DemiBold
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              Text {
                text: modelData.dispatcher
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: modelData.arg || "—"
                color: Colors.fgSecondary
                font.pixelSize: Colors.fontSizeSmall
                font.family: modelData.arg ? Colors.fontMono : ""
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: modelData.arg.length > 0 || true
              }
            }
          }
        }
      }
    }
  }
}
