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
  color: Colors.withAlpha(Colors.surface, 0.4)
  radius: Colors.radiusMedium
  border.color: cardHover.hovered ? Colors.primary : Colors.border
  clip: true
  scale: cardHover.hovered ? 1.01 : 1.0
  Behavior on scale { NumberAnimation { duration: Colors.durationSlow; easing.type: Easing.OutQuint } }
  Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

  gradient: Gradient {
    orientation: Gradient.Vertical
    GradientStop { position: 0.0; color: Colors.surfaceGradientStart }
    GradientStop { position: 1.0; color: Colors.surfaceGradientEnd }
  }

  // Inner highlight
  Rectangle {
    anchors.fill: parent
    anchors.margins: 1
    radius: parent.radius - 1
    color: "transparent"
    border.color: Colors.borderLight
    border.width: 1
    opacity: 0.1
  }

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
            color: Colors.textDisabled
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeIcon
            visible: albumArt.status !== Image.Ready
          }
        }

        // Track Info & Controls
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingXXS

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
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeSmall
            Layout.fillWidth: true
            elide: Text.ElideRight
          }

          // Progress Bar
          Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: Colors.spacingXS
            height: mediaProgressHover.containsMouse ? 6 : 4
            Behavior on height { NumberAnimation { duration: Colors.durationSnap } }
            radius: height / 2
            color: Colors.highlightLight
            visible: modelData.length > 0

            Rectangle {
              height: parent.height
              width: modelData.length > 0 ? parent.width * (modelData.position / modelData.length) : 0
              radius: parent.radius
              color: Colors.primary
              Behavior on width { NumberAnimation { duration: Colors.durationNormal } }
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
            spacing: Colors.spacingLG
            Layout.alignment: Qt.AlignHCenter
            
            // Previous
            MouseArea {
              id: prevBtn
              width: 32; height: 32
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              Text { 
                text: "󰒮"
                color: prevBtn.containsMouse ? Colors.primary : Colors.text
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeXL
                anchors.centerIn: parent
                Behavior on color { ColorAnimation { duration: Colors.durationFast } }
              }
              onClicked: modelData.previous()
            }

            // Play/Pause
            MouseArea {
              id: playBtn
              width: 40; height: 40
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: playBtn.containsMouse ? Colors.primary : Colors.withAlpha(Colors.surface, 0.6)
                border.color: playBtn.containsMouse ? Colors.primary : Colors.border
                border.width: 1
                Behavior on color { ColorAnimation { duration: Colors.durationFast } }
                Text { 
                  text: modelData.playbackState === Mpris.Playing ? "󰏤" : "󰐊"
                  color: playBtn.containsMouse ? Colors.background : Colors.text
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeLarge
                  anchors.centerIn: parent
                  Behavior on color { ColorAnimation { duration: Colors.durationFast } }
                }
              }
              onClicked: modelData.playPause()
            }

            // Next
            MouseArea {
              id: nextBtn
              width: 32; height: 32
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              Text { 
                text: "󰒭"
                color: nextBtn.containsMouse ? Colors.primary : Colors.text
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeXL
                anchors.centerIn: parent
                Behavior on color { ColorAnimation { duration: Colors.durationFast } }
              }
              onClicked: modelData.next()
            }
          }
        }
      }
    }
  }
}
