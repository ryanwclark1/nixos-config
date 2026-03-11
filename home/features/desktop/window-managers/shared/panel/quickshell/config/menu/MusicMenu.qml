import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../services"
import "../widgets" as SharedWidgets

PopupWindow {
  id: root
  implicitWidth: 360
  implicitHeight: 400

  readonly property var activePlayers: MediaService.getAvailablePlayers()
  readonly property var player: MediaService.currentPlayer

  Rectangle {
    anchors.fill: parent
    color: Colors.popupSurface
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusMedium
    clip: true

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Colors.paddingLarge
      spacing: 14

      // Header
      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "Music"
          color: Colors.fgMain
          font.pixelSize: 18
          font.weight: Font.DemiBold
        }
        Item { Layout.fillWidth: true }

        // Player selector (only if multiple players)
        Rectangle {
          visible: root.activePlayers.length > 1
          width: playerSelectorText.implicitWidth + 24
          height: 26
          radius: 13
          color: playerSelectorHover.containsMouse ? Colors.highlightLight : Colors.bgWidget
          Behavior on color { ColorAnimation { duration: 150 } }

          Text {
            id: playerSelectorText
            anchors.centerIn: parent
            text: root.player ? (root.player.identity || "") : ""
            color: Colors.textSecondary
            font.pixelSize: 11
          }

          MouseArea {
            id: playerSelectorHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              var idx = (MediaService.selectedPlayerIndex + 1) % root.activePlayers.length;
              MediaService.switchToPlayer(idx);
            }
          }
        }

        SharedWidgets.MenuCloseButton { toggleMethod: "toggleMusicMenu" }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.border
      }

      // No player state
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !root.player

        Text {
          anchors.centerIn: parent
          text: "No music playing"
          color: Colors.textDisabled
          font.pixelSize: 14
        }
      }

      // Player content
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 16
        visible: !!root.player

        // Album art
        Rectangle {
          Layout.alignment: Qt.AlignHCenter
          Layout.preferredWidth: 120
          Layout.preferredHeight: 120
          radius: Colors.radiusMedium
          color: Colors.surface
          clip: true

          Image {
            id: albumArt
            anchors.fill: parent
            source: MediaService.trackArtUrl || ""
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
          }

          Text {
            anchors.centerIn: parent
            text: "󰝚"
            color: Colors.fgDim
            font.family: Colors.fontMono
            font.pixelSize: 48
            visible: albumArt.status !== Image.Ready
          }
        }

        // Track info
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2

          Text {
            text: MediaService.trackTitle || "Unknown Track"
            color: Colors.fgMain
            font.pixelSize: 16
            font.weight: Font.Bold
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
          }

          Text {
            text: MediaService.trackArtist || "Unknown Artist"
            color: Colors.fgSecondary
            font.pixelSize: 13
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
          }
        }

        // Seek bar
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4
          visible: MediaService.trackLength > 0

          Rectangle {
            id: seekTrack
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: Colors.bgWidget
            border.color: seekMouse.containsMouse ? Colors.primary : Colors.border
            border.width: 1

            Rectangle {
              height: parent.height
              width: MediaService.trackLength > 0 ? parent.width * (MediaService.currentPosition / MediaService.trackLength) : 0
              radius: 3
              color: Colors.primary
              Behavior on width { NumberAnimation { duration: 200 } }
            }

            MouseArea {
              id: seekMouse
              anchors.fill: parent
              hoverEnabled: true
              onClicked: (mouse) => {
                if (MediaService.trackLength > 0) {
                  MediaService.seekByRatio(mouse.x / width);
                }
              }
              onPositionChanged: (mouse) => {
                if (pressed && MediaService.trackLength > 0) {
                  MediaService.seekByRatio(mouse.x / width);
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            Text {
              text: MediaService.positionString
              color: Colors.textDisabled
              font.pixelSize: 10
              font.family: Colors.fontMono
            }
            Item { Layout.fillWidth: true }
            Text {
              text: MediaService.lengthString
              color: Colors.textDisabled
              font.pixelSize: 10
              font.family: Colors.fontMono
            }
          }
        }

        // Transport controls
        RowLayout {
          Layout.alignment: Qt.AlignHCenter
          spacing: 24

          // Shuffle
          MouseArea {
            width: 28; height: 28
            hoverEnabled: true
            Rectangle {
              anchors.fill: parent; radius: 14
              color: parent.containsMouse ? Colors.highlightLight : "transparent"
            }
            Text { text: "󰒟"; color: Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: 18; anchors.centerIn: parent }
            onClicked: if (root.player) root.player.shuffle = !root.player.shuffle
          }

          // Previous
          MouseArea {
            width: 36; height: 36
            hoverEnabled: true
            Rectangle {
              anchors.fill: parent; radius: 18
              color: parent.containsMouse ? Colors.highlightLight : "transparent"
            }
            Text { text: "󰒮"; color: Colors.fgMain; font.family: Colors.fontMono; font.pixelSize: 22; anchors.centerIn: parent }
            onClicked: MediaService.previous()
          }

          // Play/Pause
          MouseArea {
            width: 48; height: 48
            hoverEnabled: true
            Rectangle {
              anchors.fill: parent; radius: 24
              color: parent.containsMouse ? Qt.darker(Colors.primary, 1.1) : Colors.primary
              Behavior on color { ColorAnimation { duration: 150 } }
            }
            Text {
              text: MediaService.isPlaying ? "󰏤" : "󰐊"
              color: Colors.background
              font.family: Colors.fontMono
              font.pixelSize: 22
              anchors.centerIn: parent
            }
            onClicked: MediaService.playPause()
          }

          // Next
          MouseArea {
            width: 36; height: 36
            hoverEnabled: true
            Rectangle {
              anchors.fill: parent; radius: 18
              color: parent.containsMouse ? Colors.highlightLight : "transparent"
            }
            Text { text: "󰒭"; color: Colors.fgMain; font.family: Colors.fontMono; font.pixelSize: 22; anchors.centerIn: parent }
            onClicked: MediaService.next()
          }

          // Repeat
          MouseArea {
            width: 28; height: 28
            hoverEnabled: true
            Rectangle {
              anchors.fill: parent; radius: 14
              color: parent.containsMouse ? Colors.highlightLight : "transparent"
            }
            Text { text: "󰑖"; color: Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: 18; anchors.centerIn: parent }
            onClicked: {
              if (!root.player) return;
              if (root.player.loopStatus === Mpris.None) root.player.loopStatus = Mpris.Track;
              else if (root.player.loopStatus === Mpris.Track) root.player.loopStatus = Mpris.Playlist;
              else root.player.loopStatus = Mpris.None;
            }
          }
        }

        // Volume
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Text {
            text: "󰕾"
            color: Colors.textSecondary
            font.family: Colors.fontMono
            font.pixelSize: 14
          }

          Rectangle {
            id: volTrack
            Layout.fillWidth: true
            height: 4
            radius: 2
            color: Colors.bgWidget

            Rectangle {
              height: parent.height
              width: root.player ? parent.width * Colors.clamp01(root.player.volume) : 0
              radius: 2
              color: Colors.primary
            }

            MouseArea {
              anchors.fill: parent
              onPressed: (mouse) => { if (root.player) root.player.volume = Colors.clamp01(mouse.x / width); }
              onPositionChanged: (mouse) => { if (pressed && root.player) root.player.volume = Colors.clamp01(mouse.x / width); }
            }
          }

          Text {
            text: root.player ? Math.round(Colors.clamp01(root.player.volume) * 100) + "%" : "0%"
            color: Colors.textDisabled
            font.pixelSize: 10
            font.family: Colors.fontMono
          }
        }

        Item { Layout.fillHeight: true }
      }
    }
  }
}
