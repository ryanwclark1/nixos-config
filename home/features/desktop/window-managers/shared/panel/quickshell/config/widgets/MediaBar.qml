import QtQuick
import "../modules"
import "../services"

Rectangle {
  id: root
  height: 24
  implicitWidth: visible ? (mediaRow.width + 16) : 0
  width: implicitWidth
  radius: height / 2
  color: Colors.bgWidget
  clip: true

  property var anchorWindow: null
  property bool vertical: false
  visible: MediaService.currentPlayer !== null

  // Rewind detection: flash prev icon when position jumps backward > 3s
  property real _lastPosition: 0
  property real _rewindFlashOpacity: 0

  Connections {
    target: MediaService
    function onCurrentPositionChanged() {
      if (root._lastPosition > 0 && MediaService.currentPosition < root._lastPosition - 3000) {
        rewindFlash.restart();
      }
      root._lastPosition = MediaService.currentPosition;
    }
  }

  SequentialAnimation {
    id: rewindFlash
    NumberAnimation { target: root; property: "_rewindFlashOpacity"; to: 1.0; duration: 100 }
    NumberAnimation { target: root; property: "_rewindFlashOpacity"; to: 0.0; duration: 400; easing.type: Easing.OutCubic }
  }

  Behavior on width { NumberAnimation { duration: Colors.durationSlow; easing.type: Easing.OutCubic } }
  Behavior on opacity { NumberAnimation { duration: Colors.durationSlow } }
  Behavior on scale { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }
  opacity: visible ? 1.0 : 0.0
  scale: mediaMouse.containsMouse ? 1.04 : 1.0

  // Rewind flash indicator
  Text {
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Colors.spacingXS
    text: "󰒮"
    color: Colors.primary
    font.family: Colors.fontMono
    font.pixelSize: Colors.fontSizeXS
    opacity: root._rewindFlashOpacity
    z: 2
  }

  Row {
    id: mediaRow
    anchors.centerIn: parent
    anchors.leftMargin: Colors.spacingS
    anchors.rightMargin: Colors.spacingS
    spacing: Colors.spacingS

    CircularGauge {
      width: 18; height: 18
      anchors.verticalCenter: parent.verticalCenter
      value: MediaService.trackLength > 0 ? (MediaService.currentPosition / MediaService.trackLength) : 0
      thickness: 2
      color: MediaService.artAccentColor
      Behavior on color { ColorAnimation { duration: 400 } }
      icon: MediaService.isPlaying ? "󰏤" : "󰐊"
    }

    Item {
      id: marqueeContainer
      visible: !root.vertical
      width: visible ? Math.min(marqueeText.contentWidth, 150) : 0
      height: 20
      clip: true
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: marqueeText
        text: MediaService.trackTitle + (MediaService.trackArtist ? " - " + MediaService.trackArtist : "")
        color: Colors.text
        font.pixelSize: Colors.fontSizeSmall
        font.weight: Font.DemiBold
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

  StateLayer {
    id: stateLayer
    hovered: mediaMouse.containsMouse
    pressed: mediaMouse.pressed
    stateColor: Colors.primary
  }

  MouseArea {
    id: mediaMouse
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: (mouse) => {
      stateLayer.burst(mouse.x, mouse.y);
      if (mouse.button === Qt.LeftButton) {
        MediaService.playPause();
      } else if (mouse.button === Qt.MiddleButton) {
        MediaService.next();
      }
    }
    onDoubleClicked: MediaService.next()

    onWheel: (wheel) => {
      var player = MediaService.currentPlayer;
      if (player) {
        var vol = player.volume || 0;
        if (wheel.angleDelta.y > 0) player.volume = Colors.clamp01(vol + 0.05);
        else player.volume = Colors.clamp01(vol - 0.05);
      }
    }
  }

  BarTooltip {
    anchorItem: root
    anchorWindow: root.anchorWindow
    hovered: mediaMouse.containsMouse
    text: MediaService.trackTitle || (MediaService.currentPlayer ? MediaService.currentPlayer.identity : "Media controls") || "Media controls"
  }
}
