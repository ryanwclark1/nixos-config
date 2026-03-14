import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMaxWidth: 360; compactThreshold: 350
  implicitHeight: compactMode ? 430 : 400
  title: "Music"
  toggleMethod: "toggleMusicMenu"
  surfaceTint: Colors.withAlpha(root.dominantColor, 0.05)

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

  Timer {
    id: fallbackClearTimer
    interval: 3000
    onTriggered: root._fallbackArtUrl = ""
  }

  headerExtras: [
    // Player selector (only if multiple players)
    Rectangle {
      visible: root.activePlayers.length > 1
      width: Math.min(playerSelectorText.implicitWidth + 24, root.compactMode ? 160 : 220)
      height: 26
      radius: 13
      color: Colors.bgWidget

      Text {
        id: playerSelectorText
        anchors.centerIn: parent
        text: root.player ? (root.player.identity || "") : ""
        color: Colors.textSecondary
        font.pixelSize: Colors.fontSizeSmall
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
      icon: "󰝚"
      message: "No music playing"
    }
  }

  // Player content
  ColumnLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Colors.spacingL
    visible: !!root.player

    // Album art
    Rectangle {
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredWidth: root.compactMode ? 96 : 120
      Layout.preferredHeight: root.compactMode ? 96 : 120
      radius: Colors.radiusMedium
      color: Colors.surface
      clip: true

      Image {
        id: albumArt
        anchors.fill: parent
        source: root.effectiveArtUrl || ""
        sourceSize: Qt.size(240, 240)
        asynchronous: true
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
        color: Colors.text
        font.pixelSize: root.compactMode ? Colors.fontSizeLarge : Colors.fontSizeXL
        font.weight: Font.Bold
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
      }

      Text {
        text: MediaService.trackArtist || "Unknown Artist"
        color: Colors.fgSecondary
        font.pixelSize: root.compactMode ? Colors.fontSizeSmall : Colors.fontSizeMedium
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
      }
    }

    // Seek bar
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Colors.spacingXS
      visible: MediaService.trackLength > 0

      Item {
        Layout.fillWidth: true
        height: 12

        SharedWidgets.WavyProgress {
          anchors.fill: parent
          value: MediaService.trackLength > 0 ? MediaService.currentPosition / MediaService.trackLength : 0
          active: MediaService.isPlaying
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
          font.pixelSize: Colors.fontSizeXS
          font.family: Colors.fontMono
        }
        Item { Layout.fillWidth: true }
        Text {
          text: MediaService.lengthString
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS
          font.family: Colors.fontMono
        }
      }
    }

    // Transport controls
    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: root.compactMode ? Colors.spacingL : Colors.spacingXL

      SharedWidgets.PulseButton {
        icon: "󰒟"; size: root.compactMode ? 24 : 28; tint: Colors.textSecondary
        onClicked: if (root.player) root.player.shuffle = !root.player.shuffle
      }

      SharedWidgets.PulseButton {
        icon: "󰒮"; size: root.compactMode ? 32 : 36; tint: Colors.text
        onClicked: MediaService.previous()
      }

      // Play/Pause (larger, filled style — tinted by album art accent)
      SharedWidgets.PulseButton {
        icon: MediaService.isPlaying ? "󰏤" : "󰐊"
        size: root.compactMode ? 42 : 48; tint: Colors.background
        color: root.dominantColor
        Behavior on color { ColorAnimation { duration: 400 } }
        onClicked: MediaService.playPause()
      }

      SharedWidgets.PulseButton {
        icon: "󰒭"; size: root.compactMode ? 32 : 36; tint: Colors.text
        onClicked: MediaService.next()
      }

      SharedWidgets.PulseButton {
        icon: "󰑖"; size: root.compactMode ? 24 : 28; tint: Colors.textSecondary
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
        font.pixelSize: Colors.fontSizeLarge
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
          color: root.dominantColor
          Behavior on color { ColorAnimation { duration: 400 } }
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
        font.pixelSize: Colors.fontSizeXS
        font.family: Colors.fontMono
      }
    }

    Item { Layout.fillHeight: true }
  }
}
