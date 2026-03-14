import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../services"

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: contentCol.implicitHeight + 24
  visible: Config.controlCenterShowMediaWidget && activePlayers.length > 0
  color: Colors.bgWidget
  radius: Colors.radiusMedium
  border.color: cardHover.hovered ? Colors.primary : Colors.border
  clip: true
  scale: cardHover.hovered ? 1.01 : 1.0
  Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
  Behavior on border.color { ColorAnimation { duration: 160 } }

  HoverHandler { id: cardHover }

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
    anchors.margins: Colors.spacingM
    spacing: Colors.paddingMedium

    Repeater {
      id: mprisRepeater
      model: root.activePlayers

      delegate: RowLayout {
        Layout.fillWidth: true
        spacing: Colors.paddingMedium

        // Album Art
        Rectangle {
          Layout.preferredWidth: 70
          Layout.preferredHeight: 70
          radius: Colors.radiusXS
          color: Colors.surface
          clip: true

          Image {
            id: albumArt
            anchors.fill: parent
            source: modelData.trackArtUrl || ""
            sourceSize: Qt.size(140, 140)
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
          }

          Text {
            anchors.centerIn: parent
            text: "󰝚"
            color: Colors.fgDim
            font.family: Colors.fontMono
            font.pixelSize: 32
            visible: albumArt.status !== Image.Ready
          }
        }

        // Track Info & Controls
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2

          Text {
            text: modelData.trackTitle || "Unknown Track"
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            font.weight: Font.Bold
            Layout.fillWidth: true
            elide: Text.ElideRight
          }

          Text {
            text: modelData.trackArtist || "Unknown Artist"
            color: Colors.fgSecondary
            font.pixelSize: Colors.fontSizeSmall
            Layout.fillWidth: true
            elide: Text.ElideRight
          }

          // Progress Bar
          Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: Colors.spacingXS
            height: mediaProgressHover.containsMouse ? 6 : 4
            Behavior on height { NumberAnimation { duration: 100 } }
            radius: height / 2
            color: Colors.highlightLight
            visible: modelData.length > 0

            Rectangle {
              height: parent.height
              width: modelData.length > 0 ? parent.width * (modelData.position / modelData.length) : 0
              radius: parent.radius
              color: Colors.primary
              Behavior on width { NumberAnimation { duration: 200 } }
            }

            MouseArea {
              id: mediaProgressHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
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
              cursorShape: Qt.PointingHandCursor
              Text { text: "󰒮"; color: Colors.text; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL; anchors.centerIn: parent }
              onClicked: modelData.previous()
            }

            // Play/Pause
            MouseArea {
              width: 32; height: 32
              cursorShape: Qt.PointingHandCursor
              Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Colors.surface
                Text { 
                  text: modelData.playbackState === Mpris.Playing ? "󰏤" : "󰐊"
                  color: Colors.text
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeMedium
                  anchors.centerIn: parent
                }
              }
              onClicked: modelData.playPause()
            }

            // Next
            MouseArea {
              width: 24; height: 24
              cursorShape: Qt.PointingHandCursor
              Text { text: "󰒭"; color: Colors.text; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL; anchors.centerIn: parent }
              onClicked: modelData.next()
            }
          }
        }
      }
    }
  }
}
