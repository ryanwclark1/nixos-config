import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../services"

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: contentCol.implicitHeight + 24
  visible: activePlayers.length > 0
  color: Colors.bgWidget
  radius: Colors.radiusMedium
  border.color: Colors.border
  clip: true

  readonly property var activePlayers: {
    var players = [];
    for (var i = 0; i < Mpris.players.length; i++) {
      var p = Mpris.players[i];
      if (p.playbackState !== Mpris.Stopped) {
        players.push(p);
      }
    }
    return players;
  }

  ColumnLayout {
    id: contentCol
    anchors.fill: parent
    anchors.margins: 12
    spacing: 15

    Repeater {
      id: mprisRepeater
      model: root.activePlayers

      delegate: RowLayout {
        Layout.fillWidth: true
        spacing: 15
...

        // Album Art
        Rectangle {
          Layout.preferredWidth: 70
          Layout.preferredHeight: 70
          radius: 8
          color: Colors.surface
          clip: true

          Image {
            anchors.fill: parent
            source: modelData.trackArtUrl || ""
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
          }

          Text {
            anchors.centerIn: parent
            text: "󰝚"
            color: Colors.fgDim
            font.family: Colors.fontMono
            font.pixelSize: 32
            visible: parent.children[0].status !== Image.Ready
          }
        }

        // Track Info & Controls
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2

          Text {
            text: modelData.trackTitle || "Unknown Track"
            color: Colors.fgMain
            font.pixelSize: 13
            font.weight: Font.Bold
            Layout.fillWidth: true
            elide: Text.ElideRight
          }

          Text {
            text: modelData.trackArtist || "Unknown Artist"
            color: Colors.fgSecondary
            font.pixelSize: 11
            Layout.fillWidth: true
            elide: Text.ElideRight
          }

          // Progress Bar
          Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 4
            height: 4
            radius: 2
            color: Colors.highlightLight
            visible: modelData.length > 0
            
            Rectangle {
              height: parent.height
              width: modelData.length > 0 ? parent.width * (modelData.position / modelData.length) : 0
              radius: 2
              color: Colors.primary
            }
            
            MouseArea {
              anchors.fill: parent
              onClicked: (mouse) => {
                if (modelData.length > 0) {
                  modelData.position = modelData.length * (mouse.x / width);
                }
              }
            }
          }

          Item { Layout.preferredHeight: 5 }

          // Playback Controls
          RowLayout {
            spacing: 20
            Layout.alignment: Qt.AlignHCenter
            
            // Previous
            MouseArea {
              width: 24; height: 24
              Text { text: "󰒮"; color: Colors.fgMain; font.family: Colors.fontMono; font.pixelSize: 18; anchors.centerIn: parent }
              onClicked: modelData.previous()
            }

            // Play/Pause
            MouseArea {
              width: 32; height: 32
              Rectangle {
                anchors.fill: parent
                radius: 16
                color: Colors.surface
                Text { 
                  text: modelData.playbackState === Mpris.Playing ? "󰏤" : "󰐊"
                  color: Colors.fgMain
                  font.family: Colors.fontMono
                  font.pixelSize: 14
                  anchors.centerIn: parent
                }
              }
              onClicked: modelData.playPause()
            }

            // Next
            MouseArea {
              width: 24; height: 24
              Text { text: "󰒭"; color: Colors.fgMain; font.family: Colors.fontMono; font.pixelSize: 18; anchors.centerIn: parent }
              onClicked: modelData.next()
            }
          }
        }
      }
    }
  }
}
