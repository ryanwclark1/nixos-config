import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "../../shared"
import "../../services"
import "../../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMaxWidth: 360; compactThreshold: 350
  implicitHeight: compactMode ? 430 : 400
  title: "Music"
  surfaceTint: Colors.withAlpha(root.dominantColor, 0.12)

  SharedWidgets.Ref { service: MediaService }

  backgroundContent: [
    Rectangle {
      anchors.fill: parent
      radius: Appearance.radiusLarge
      color: "transparent"
      clip: true
      layer.enabled: MediaService.isPlaying && root.wantVisible

      Rectangle {
        anchors.centerIn: parent
        width: parent.width * 1.5
        height: width
        radius: width / 2
        color: root.dominantColor
        opacity: 0.12
        scale: MediaService.isPlaying ? 1.0 : 0.8
        Behavior on scale { NumberAnimation { duration: Appearance.durationAmbient; easing.type: Easing.InOutSine } }

        SequentialAnimation on opacity {
          running: MediaService.isPlaying && root.wantVisible
          loops: Animation.Infinite
          NumberAnimation { from: 0.08; to: 0.18; duration: Appearance.durationToast; easing.type: Easing.InOutSine }
          NumberAnimation { from: 0.18; to: 0.08; duration: Appearance.durationToast; easing.type: Easing.InOutSine }
        }
      }
    }
  ]

  readonly property var activePlayers: {
    MediaService.currentPlayer; // force re-eval on player change
    return MediaService.getAvailablePlayers();
  }
  readonly property var player: MediaService.currentPlayer
  // Bind dominant color directly to MediaService's extracted accent color
  property color dominantColor: MediaService.artAccentColor

  // Sticky fallback art: keep previous art visible for 3s after track change
  property string _fallbackArtUrl: ""
  readonly property string effectiveArtUrl: MediaService.trackArtUrl || _fallbackArtUrl

  onEffectiveArtUrlChanged: {
    if (MediaService.trackArtUrl) {
      _fallbackArtUrl = MediaService.trackArtUrl;
      fallbackClearTimer.stop();
    } else if (_fallbackArtUrl) {
      fallbackClearTimer.restart();
    }
  }

  readonly property int _fallbackArtClearMs: 3000

  Timer {
    id: fallbackClearTimer
    interval: root._fallbackArtClearMs
    onTriggered: root._fallbackArtUrl = ""
  }

  headerExtras: [
    // Player selector (only if multiple players)
    Rectangle {
      visible: root.activePlayers.length > 1
      width: Math.min(playerSelectorText.implicitWidth + 24, root.compactMode ? 160 : 220)
      height: 26
      radius: height / 2
      color: Colors.bgWidget

      Text {
        id: playerSelectorText
        anchors.centerIn: parent
        text: root.player ? (root.player.identity || "") : ""
        color: Colors.textSecondary
        font.pixelSize: Appearance.fontSizeSmall
      }

      SharedWidgets.StateLayer {
        id: stateLayer
        hovered: playerSelectorHover.containsMouse
        pressed: playerSelectorHover.pressed
      }

      MouseArea {
        id: playerSelectorHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
          stateLayer.burst(mouse.x, mouse.y);
          var idx = (MediaService.selectedPlayerIndex + 1) % root.activePlayers.length;
          MediaService.switchToPlayer(idx);
        }
      }
    }
  ]

  // No player state
  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: !root.player

    SharedWidgets.EmptyState {
      anchors.centerIn: parent
      icon: "music-note-2.svg"
      message: "No music playing"
    }
  }

  // Player content
  ColumnLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Appearance.spacingL
    visible: !!root.player

    // Album art (ClippingWrapperRectangle for proper radius clipping)
    Item {
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredWidth: root.compactMode ? 96 : 120
      Layout.preferredHeight: root.compactMode ? 96 : 120

      // Glow Shadow
      Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: Appearance.radiusMedium + 4
        color: root.dominantColor
        opacity: MediaService.isPlaying ? 0.25 : 0.1
        visible: albumArt.status === Image.Ready
        Behavior on opacity { NumberAnimation { duration: Appearance.durationAmbientShort } }
      }

      ClippingWrapperRectangle {
        anchors.fill: parent
        radius: Appearance.radiusMedium
        color: Colors.surface
        border.color: Colors.withAlpha(root.dominantColor, 0.3)
        border.width: 1

        Item {
          anchors.fill: parent
          Image {
            id: albumArt
            anchors.fill: parent
            source: root.effectiveArtUrl || ""
            sourceSize: Qt.size(240, 240)
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
          }

          SharedWidgets.SvgIcon {
            anchors.centerIn: parent
            source: "music-note-2.svg"
            color: Colors.textDisabled
            size: Appearance.fontSizeHuge * 2
            visible: albumArt.status !== Image.Ready
          }
        }
      }
    }

    // Track info
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Appearance.spacingXXS

      Text {
        text: MediaService.trackTitle || "Unknown Track"
        color: Colors.text
        font.pixelSize: root.compactMode ? Appearance.fontSizeLarge : Appearance.fontSizeXL
        font.weight: Font.Bold
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
      }

      Text {
        text: MediaService.trackArtist || "Unknown Artist"
        color: Colors.textSecondary
        font.pixelSize: root.compactMode ? Appearance.fontSizeSmall : Appearance.fontSizeMedium
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
      }
    }

    // Seek bar
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Appearance.spacingXS
      visible: MediaService.trackLength > 0

      Item {
        Layout.fillWidth: true
        height: 12

        SharedWidgets.WavyProgress {
          anchors.fill: parent
          value: MediaService.trackLength > 0 ? MediaService.currentPosition / MediaService.trackLength : 0
          active: MediaService.isPlaying && root.wantVisible
          color: root.dominantColor
          trackColor: Colors.withAlpha(root.dominantColor, 0.18)
          amplitude: 2.5
          frequency: 0.15
          lineWidth: 2.5
        }

        MouseArea {
          id: seekMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: (mouse) => {
            if (MediaService.trackLength > 0 && width > 0) {
              MediaService.seekByRatio(Colors.clamp01(mouse.x / width));
            }
          }
          onPositionChanged: (mouse) => {
            if (pressed && MediaService.trackLength > 0 && width > 0) {
              MediaService.seekByRatio(Colors.clamp01(mouse.x / width));
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        Text {
          text: MediaService.positionString
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.family: Appearance.fontMono
        }
        Item { Layout.fillWidth: true }
        Text {
          text: MediaService.lengthString
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.family: Appearance.fontMono
        }
      }
    }

    // Transport controls
    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: root.compactMode ? Appearance.spacingL : Appearance.spacingXL

      SharedWidgets.PulseButton {
        icon: "shuffle.svg"; size: root.compactMode ? 24 : 28; tint: Colors.textSecondary
        onClicked: if (root.player) root.player.shuffle = !root.player.shuffle
      }

      SharedWidgets.PulseButton {
        icon: "previous.svg"; size: root.compactMode ? 32 : 36; tint: Colors.text
        onClicked: MediaService.previous()
      }

      // Play/Pause (larger, filled style — tinted by album art accent)
      SharedWidgets.PulseButton {
        icon: MediaService.isPlaying ? "pause.svg" : "play.svg"
        size: root.compactMode ? 42 : 48; tint: Colors.background
        color: root.dominantColor
        Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationEmphasis } }
        onClicked: MediaService.playPause()
      }

      SharedWidgets.PulseButton {
        icon: "next.svg"; size: root.compactMode ? 32 : 36; tint: Colors.text
        onClicked: MediaService.next()
      }

      SharedWidgets.PulseButton {
        icon: "repeat.svg"; size: root.compactMode ? 24 : 28; tint: Colors.textSecondary
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
      spacing: Appearance.paddingSmall

      SharedWidgets.SvgIcon {
        source: "speaker.svg"
        color: Colors.textSecondary
        size: Appearance.fontSizeLarge
      }

      Rectangle {
        id: volTrack
        Layout.fillWidth: true
        height: 4
        radius: Appearance.radiusMicro
        color: Colors.bgWidget

        Rectangle {
          height: parent.height
          width: root.player ? parent.width * Colors.clamp01(root.player.volume) : 0
          radius: Appearance.radiusMicro
          color: root.dominantColor
          Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationEmphasis } }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onPressed: (mouse) => { if (root.player) root.player.volume = Colors.clamp01(mouse.x / width); }
          onPositionChanged: (mouse) => { if (pressed && root.player) root.player.volume = Colors.clamp01(mouse.x / width); }
        }
      }

      Text {
        text: root.player ? Math.round(Colors.clamp01(root.player.volume) * 100) + "%" : "0%"
        color: Colors.textDisabled
        font.pixelSize: Appearance.fontSizeXS
        font.family: Appearance.fontMono
      }
    }

    Item { Layout.fillHeight: true }
  }
}
