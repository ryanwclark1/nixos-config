import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: mprisRepeater.count > 0 ? 115 : 0
  visible: mprisRepeater.count > 0
  color: "#0dffffff"
  radius: 12
  border.color: "#33ffffff"
  clip: true

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 12
    spacing: 10

    Repeater {
      id: mprisRepeater
      model: Mpris.players
      
      delegate: RowLayout {
        visible: modelData.playbackState !== Mpris.Stopped
        Layout.fillWidth: true
        spacing: 15

        // Album Art
        Rectangle {
          width: 70
          height: 70
          radius: 8
          color: "#1e1f22"
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
            color: "#444444"
            font.family: "JetBrainsMono Nerd Font"
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
            color: "#e6e6e6"
            font.pixelSize: 14
            font.weight: Font.Bold
            Layout.fillWidth: true
            elide: Text.ElideRight
          }

          Text {
            text: modelData.trackArtist || "Unknown Artist"
            color: "#aaaaaa"
            font.pixelSize: 12
            Layout.fillWidth: true
            elide: Text.ElideRight
          }

          // Progress Bar
          Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 4
            height: 4
            radius: 2
            color: "#33ffffff"
            visible: modelData.length > 0
            
            Rectangle {
              height: parent.height
              width: modelData.length > 0 ? parent.width * (modelData.position / modelData.length) : 0
              radius: 2
              color: "#4caf50"
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

          Item { Layout.preferredHeight: 2 }

          // Playback Controls
          RowLayout {
            spacing: 15
            Layout.alignment: Qt.AlignHCenter
            
            // Previous
            MouseArea {
              width: 24; height: 24
              Text { text: "󰒮"; color: "#e6e6e6"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20; anchors.centerIn: parent }
              onClicked: modelData.previous()
            }

            // Play/Pause
            MouseArea {
              width: 32; height: 32
              Rectangle {
                anchors.fill: parent
                radius: 16
                color: "#3d3e42"
                Text { 
                  text: modelData.playbackState === Mpris.Playing ? "󰏤" : "󰐊"
                  color: "#e6e6e6"
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 16
                  anchors.centerIn: parent
                }
              }
              onClicked: modelData.playPause()
            }

            // Next
            MouseArea {
              width: 24; height: 24
              Text { text: "󰒭"; color: "#e6e6e6"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20; anchors.centerIn: parent }
              onClicked: modelData.next()
            }
          }
        }
      }
    }
  }
}
