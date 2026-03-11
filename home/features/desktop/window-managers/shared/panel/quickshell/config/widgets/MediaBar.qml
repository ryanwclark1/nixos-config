import QtQuick
import "../modules"
import "../services"
import "." as LocalWidgets

Rectangle {
  id: root
  height: 24
  implicitWidth: visible ? (mediaRow.width + 16) : 0
  width: implicitWidth
  radius: height / 2
  color: mediaMouse.containsMouse ? Colors.highlightLight : Colors.bgWidget
  clip: true

  property var anchorWindow: null
  visible: MediaService.currentPlayer !== null

  Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
  Behavior on opacity { NumberAnimation { duration: 300 } }
  Behavior on color { ColorAnimation { duration: 160 } }
  Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  opacity: visible ? 1.0 : 0.0
  scale: mediaMouse.containsMouse ? 1.04 : 1.0

  Row {
    id: mediaRow
    anchors.centerIn: parent
    anchors.leftMargin: 8
    anchors.rightMargin: 8
    spacing: 8

    CircularGauge {
      width: 18; height: 18
      anchors.verticalCenter: parent.verticalCenter
      value: MediaService.trackLength > 0 ? (MediaService.currentPosition / MediaService.trackLength) : 0
      thickness: 2
      color: Colors.primary
      icon: MediaService.isPlaying ? "󰏤" : "󰐊"
    }

    Item {
      id: marqueeContainer
      width: Math.min(marqueeText.contentWidth, 150)
      height: 20
      clip: true
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: marqueeText
        text: MediaService.trackTitle + (MediaService.trackArtist ? " - " + MediaService.trackArtist : "")
        color: Colors.fgMain
        font.pixelSize: 11
        font.weight: Font.Medium
        anchors.verticalCenter: parent.verticalCenter

        SequentialAnimation on x {
          running: marqueeText.contentWidth > 150
          loops: Animation.Infinite
          NumberAnimation { from: 0; to: -(marqueeText.contentWidth - marqueeContainer.width + 10); duration: 5000; easing.type: Easing.Linear }
          PauseAnimation { duration: 1000 }
          NumberAnimation { from: -(marqueeText.contentWidth - marqueeContainer.width + 10); to: 0; duration: 5000; easing.type: Easing.Linear }
          PauseAnimation { duration: 1000 }
        }
      }
    }
  }

  MouseArea {
    id: mediaMouse
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    hoverEnabled: true
    onClicked: (mouse) => {
      if (mouse.button === Qt.LeftButton) {
        MediaService.playPause();
      } else if (mouse.button === Qt.MiddleButton) {
        MediaService.next();
      }
    }
    onDoubleClicked: MediaService.next()

    onWheel: (wheel) => {
      if (MediaService.currentPlayer) {
        var vol = MediaService.currentPlayer.volume || 0;
        if (wheel.angleDelta.y > 0) MediaService.currentPlayer.volume = Colors.clamp01(vol + 0.05);
        else MediaService.currentPlayer.volume = Colors.clamp01(vol - 0.05);
      }
    }
  }

  LocalWidgets.BarTooltip {
    anchorItem: root
    anchorWindow: root.anchorWindow
    hovered: mediaMouse.containsMouse
    text: MediaService.trackTitle || (MediaService.currentPlayer ? MediaService.currentPlayer.identity : "Media controls") || "Media controls"
  }
}
