import QtQuick
import Quickshell.Services.Mpris
import "../services"

Rectangle {
  id: root
  height: 24
  implicitWidth: visible ? (mediaRow.width + 16) : 0
  width: implicitWidth
  radius: height / 2
  color: Colors.bgWidget
  clip: true
  
  property var player: Mpris.players.length > 0 ? Mpris.players[0] : null
  visible: player !== null && player.playbackState !== Mpris.Stopped

  Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
  Behavior on opacity { NumberAnimation { duration: 300 } }
  opacity: visible ? 1.0 : 0.0

  Row {
    id: mediaRow
    anchors.centerIn: parent
    anchors.leftMargin: 8
    anchors.rightMargin: 8
    spacing: 8

    Text {
      text: player && player.playbackState === Mpris.Playing ? "󰐊" : "󰏤"
      color: Colors.primary
      font.family: Colors.fontMono
      font.pixelSize: 14
      anchors.verticalCenter: parent.verticalCenter
    }

    Item {
      id: marqueeContainer
      width: Math.min(marqueeText.contentWidth, 150)
      height: 20
      clip: true
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: marqueeText
        text: player ? (player.trackTitle + (player.trackArtist ? " - " + player.trackArtist : "")) : ""
        color: Colors.fgMain
        font.pixelSize: 11
        font.weight: Font.Medium
        anchors.verticalCenter: parent.verticalCenter

        SequentialAnimation on x {
          running: marqueeText.contentWidth > 150
          loops: Animation.Infinite
          NumberAnimation { from: 0; to: -marqueeText.contentWidth + 140; duration: 5000; easing.type: Easing.Linear }
          PauseAnimation { duration: 1000 }
          NumberAnimation { from: -marqueeText.contentWidth + 140; to: 0; duration: 5000; easing.type: Easing.Linear }
          PauseAnimation { duration: 1000 }
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: if (player) player.playPause()
  }
}
