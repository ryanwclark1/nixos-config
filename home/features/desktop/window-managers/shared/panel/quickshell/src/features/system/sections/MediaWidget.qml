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
  Layout.preferredHeight: contentCol.implicitHeight + Colors.paddingLarge
  visible: Config.controlCenterShowMediaWidget && activePlayers.length > 0
  color: Colors.cardSurface
  radius: Colors.radiusMedium
  border.color: cardHover.hovered ? Colors.primary : Colors.border
  clip: true
  scale: cardHover.hovered ? 1.01 : 1.0
  Behavior on scale { NumberAnimation { id: mediaScaleAnim; duration: Colors.durationSlow; easing.type: Easing.OutQuint } }
  Behavior on border.color { CAnim {} }
  layer.enabled: mediaScaleAnim.running

  gradient: SharedWidgets.SurfaceGradient {}

  // Inner highlight
  SharedWidgets.InnerHighlight { }

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

      delegate: GridLayout {
        Layout.fillWidth: true
        columns: root.width >= 380 ? 2 : 1
        columnSpacing: Colors.paddingMedium
        rowSpacing: Colors.spacingS

        // Album Art
        ClippingWrapperRectangle {
          Layout.preferredWidth: root.width >= 380 ? 70 : 56
          Layout.preferredHeight: root.width >= 380 ? 70 : 56
          Layout.alignment: root.width >= 380 ? Qt.AlignTop : Qt.AlignHCenter
          radius: Colors.radiusXS
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

            Text {
              anchors.centerIn: parent
              text: "󰝚"
              color: Colors.textDisabled
              font.family: Colors.fontMono
              font.pixelSize: Colors.fontSizeIcon
              visible: albumArt.status !== Image.Ready
            }
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
            wrapMode: Text.Wrap
            maximumLineCount: 2
          }

          Text {
            text: modelData.trackArtist || "Unknown Artist"
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeSmall
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            maximumLineCount: 2
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
            spacing: root.width >= 380 ? Colors.spacingLG : Colors.spacingM
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
                Behavior on color { CAnim {} }
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
                Behavior on color { CAnim {} }
                Text { 
                  text: modelData.playbackState === Mpris.Playing ? "󰏤" : "󰐊"
                  color: playBtn.containsMouse ? Colors.background : Colors.text
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeLarge
                  anchors.centerIn: parent
                  Behavior on color { CAnim {} }
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
                Behavior on color { CAnim {} }
              }
              onClicked: modelData.next()
            }
          }
        }
      }
    }
  }
}
