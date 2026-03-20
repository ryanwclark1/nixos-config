import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "../../../services"
import "../../../shared"
import "../../../widgets" as SharedWidgets

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: contentCol.implicitHeight + Appearance.paddingLarge
  visible: Config.controlCenterShowMediaWidget && activePlayers.length > 0
  color: Colors.cardSurface
  radius: Appearance.radiusMedium
  border.color: cardHover.hovered ? Colors.primary : Colors.border
  clip: true
  scale: cardHover.hovered ? 1.01 : 1.0
  Behavior on scale { NumberAnimation { id: mediaScaleAnim; duration: Appearance.durationSlow; easing.type: Easing.OutQuint } }
  Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }
  layer.enabled: mediaScaleAnim.running

  gradient: SharedWidgets.SurfaceGradient {}

  // Inner highlight
  SharedWidgets.InnerHighlight { }

  HoverHandler { id: cardHover }

  SharedWidgets.Ref {
    service: SpectrumService
    active: root.visible && root.activePlayers.some(p => p.playbackState === Mpris.Playing)
  }

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
    anchors.margins: Appearance.spacingM
    spacing: Appearance.paddingMedium

    Repeater {
      id: mprisRepeater
      model: root.activePlayers

      delegate: GridLayout {
        Layout.fillWidth: true
        columns: root.width >= 380 ? 2 : 1
        columnSpacing: Appearance.paddingMedium
        rowSpacing: Appearance.spacingS

        // Album Art
        ClippingWrapperRectangle {
          Layout.preferredWidth: root.width >= 380 ? 70 : 56
          Layout.preferredHeight: root.width >= 380 ? 70 : 56
          Layout.alignment: root.width >= 380 ? Qt.AlignTop : Qt.AlignHCenter
          radius: Appearance.radiusXS
          color: Colors.surface

          Item {
            Image {
              id: albumArt
              anchors.fill: parent
              source: modelData.trackArtUrl || ""
              sourceSize: Qt.size(140, 140)
              asynchronous: true
              fillMode: Image.PreserveAspectCrop
              visible: status === Image.Ready
            }

            // Mini Visualizer Overlay
            Row {
              anchors.bottom: parent.bottom
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottomMargin: 4
              spacing: Appearance.spacingXXS
              height: 12
              visible: modelData.playbackState === Mpris.Playing && SpectrumService.subscriberCount > 0

              Repeater {
                model: 4
                delegate: Rectangle {
                  required property int index
                  width: 3
                  height: Math.max(2, (SpectrumService.values[index * 4] || 0) * parent.height)
                  radius: 1
                  color: Colors.primary
                  anchors.bottom: parent.bottom
                  opacity: 0.8

                  Behavior on height {
                    NumberAnimation { duration: Appearance.durationFlash; easing.type: Easing.OutCubic }
                  }
                }
              }
            }

            SharedWidgets.SvgIcon {
              anchors.centerIn: parent
              source: "music-note-2.svg"
              color: Colors.textDisabled
              size: Appearance.fontSizeIcon
              visible: albumArt.status !== Image.Ready
            }
          }
        }

        // Track Info & Controls
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Appearance.spacingXXS

          Text {
            text: modelData.trackTitle || "Unknown Track"
            color: Colors.text
            font.pixelSize: Appearance.fontSizeMedium
            font.weight: Font.Bold
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            maximumLineCount: 2
          }

          Text {
            text: modelData.trackArtist || "Unknown Artist"
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeSmall
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            maximumLineCount: 2
          }

          // Progress Bar
          Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacingXS
            height: mediaProgressHover.containsMouse ? 6 : 4
            Behavior on height { NumberAnimation { duration: Appearance.durationSnap } }
            radius: height / 2
            color: Colors.highlightLight
            visible: modelData.length > 0

            Rectangle {
              height: parent.height
              width: modelData.length > 0 ? parent.width * (modelData.position / modelData.length) : 0
              radius: parent.radius
              color: Colors.primary
              Behavior on width { NumberAnimation { duration: Appearance.durationNormal } }
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
            spacing: root.width >= 380 ? Appearance.spacingLG : Appearance.spacingM
            Layout.alignment: Qt.AlignHCenter
            
            // Previous
            MouseArea {
              id: prevBtn
              width: 32; height: 32
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              SharedWidgets.SvgIcon {
                source: "previous.svg"
                color: prevBtn.containsMouse ? Colors.primary : Colors.text
                size: Appearance.fontSizeXL
                anchors.centerIn: parent
                Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
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
                color: playBtn.containsMouse ? Colors.primary : Colors.cardSurface
                border.color: playBtn.containsMouse ? Colors.primary : Colors.border
                border.width: 1
                Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
                SharedWidgets.SvgIcon {
                  source: modelData.playbackState === Mpris.Playing ? "pause.svg" : "play.svg"
                  color: playBtn.containsMouse ? Colors.background : Colors.text
                  size: Appearance.fontSizeLarge
                  anchors.centerIn: parent
                  Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
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
              SharedWidgets.SvgIcon {
                source: "next.svg"
                color: nextBtn.containsMouse ? Colors.primary : Colors.text
                size: Appearance.fontSizeXL
                anchors.centerIn: parent
                Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
              }
              onClicked: modelData.next()
            }
          }
        }
      }
    }
  }
}
