import QtQuick
import "../../system/sections"
import "../../../services"
import "../../../services/IconHelpers.js" as IconHelpers
import "../../../shared"
import "../../../widgets"

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
  property bool iconOnly: false
  property int maxTextWidth: 150
  property bool showVisualizer: true
  property int visualizerBars: 8
  visible: MediaService.currentPlayer !== null
  readonly property bool visualizerVisible: !root.vertical && showVisualizer && MediaService.currentPlayer !== null && MediaService.isPlaying
  readonly property var visualizerValues: {
    var source = (SpectrumService && SpectrumService.values) ? SpectrumService.values : [];
    var count = Math.max(4, visualizerBars);
    var aggregated = [];
    for (var i = 0; i < count; ++i) {
      var start = Math.floor((i * source.length) / count);
      var end = Math.floor(((i + 1) * source.length) / count);
      var peak = 0;
      for (var j = start; j < end; ++j)
        peak = Math.max(peak, Number(source[j]) || 0);
      aggregated.push(peak);
    }
    return aggregated;
  }

  // Rewind detection: flash prev icon when position jumps backward > 3s
  property real _lastPosition: 0
  property real _rewindFlashOpacity: 0

  Item {
    width: 0
    height: 0
    visible: false
    Ref {
      service: MediaService
    }
    Ref {
      service: SpectrumService
      active: root.visualizerVisible
    }
  }

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
    NumberAnimation { target: root; property: "_rewindFlashOpacity"; to: 1.0; duration: Appearance.durationSnap }
    NumberAnimation { target: root; property: "_rewindFlashOpacity"; to: 0.0; duration: Appearance.durationEmphasis; easing.type: Easing.OutCubic }
  }

  Behavior on width { NumberAnimation { duration: Appearance.durationSlow; easing.type: Easing.OutCubic } }
  Behavior on opacity { NumberAnimation { duration: Appearance.durationSlow } }
  Behavior on scale { Anim { duration: Appearance.durationFast } }
  opacity: visible ? 1.0 : 0.0
  scale: mediaMouse.containsMouse ? 1.04 : 1.0

  // Rewind flash indicator
  SvgIcon {
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Appearance.spacingXS
    source: "previous.svg"
    color: Colors.primary
    size: Appearance.fontSizeXS
    opacity: root._rewindFlashOpacity
    z: 2
  }

  Row {
    id: mediaRow
    anchors.centerIn: parent
    anchors.leftMargin: Appearance.spacingS
    anchors.rightMargin: Appearance.spacingS
    spacing: Appearance.spacingS

    CircularGauge {
      width: 18; height: 18
      anchors.verticalCenter: parent.verticalCenter
      value: MediaService.trackLength > 0 ? (MediaService.currentPosition / MediaService.trackLength) : 0
      thickness: 2
      color: MediaService.artAccentColor
      Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationEmphasis } }
      icon: IconHelpers.transportToggleIcon(MediaService.isPlaying)
    }

    Item {
      visible: root.visualizerVisible
      width: visible ? visualizerRow.width : 0
      height: 16
      anchors.verticalCenter: parent.verticalCenter

      Row {
        id: visualizerRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacingXXS

        Repeater {
          model: root.visualizerValues

          delegate: Rectangle {
            required property var modelData
            width: 3
            height: 4 + Math.round(Math.max(0, Math.min(1, Number(modelData) || 0)) * 12)
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            color: Colors.withAlpha(MediaService.artAccentColor, 0.9)

            Behavior on height {
              NumberAnimation { duration: Appearance.durationSnap; easing.type: Easing.OutCubic }
            }
          }
        }
      }
    }

    Item {
      id: marqueeContainer
      visible: !root.vertical && !root.iconOnly
      width: visible ? Math.min(marqueeText.contentWidth, root.maxTextWidth) : 0
      height: 20
      clip: true
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: marqueeText
        text: MediaService.trackTitle + (MediaService.trackArtist ? " - " + MediaService.trackArtist : "")
        color: Colors.text
        font.pixelSize: Appearance.fontSizeSmall
        font.weight: Font.DemiBold
        anchors.verticalCenter: parent.verticalCenter

        SequentialAnimation on x {
          running: marqueeText.contentWidth > root.maxTextWidth
          loops: Animation.Infinite
          NumberAnimation { from: 0; to: -(marqueeText.contentWidth - marqueeContainer.width + 10); duration: Appearance.durationMarquee; easing.type: Easing.Linear }
          PauseAnimation { duration: Appearance.durationAmbientShort }
          NumberAnimation { from: -(marqueeText.contentWidth - marqueeContainer.width + 10); to: 0; duration: Appearance.durationMarquee; easing.type: Easing.Linear }
          PauseAnimation { duration: Appearance.durationAmbientShort }
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
    hoverPoint: Qt.point(mediaMouse.mouseX, mediaMouse.mouseY)
    text: MediaService.trackTitle || (MediaService.currentPlayer ? MediaService.currentPlayer.identity : "Media controls") || "Media controls"
  }
}
