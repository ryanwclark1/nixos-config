import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../widgets" as SharedWidgets
import "../services"

ColumnLayout {
  id: root

  required property var mediaPlayers
  required property bool compactMode
  required property bool tightMode

  spacing: root.compactMode ? Colors.paddingSmall : Colors.paddingMedium

  Repeater {
    model: root.mediaPlayers
    delegate: Rectangle {
      Layout.fillWidth: true
      height: root.tightMode ? 96 : (root.compactMode ? 108 : 120)
      color: Colors.bgWidget
      radius: Colors.radiusMedium
      border.color: Colors.border
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.margins: root.compactMode ? Colors.spacingM : Colors.paddingMedium
        spacing: root.compactMode ? Colors.paddingSmall : Colors.paddingMedium
        Rectangle {
          width: root.compactMode ? 72 : 90
          height: root.compactMode ? 72 : 90
          radius: Colors.radiusXS
          color: Colors.surface
          clip: true
          Image { anchors.fill: parent; source: modelData.trackArtUrl || ""; sourceSize: Qt.size(128, 128); asynchronous: true; fillMode: Image.PreserveAspectCrop }
        }
        ColumnLayout {
          Layout.fillWidth: true
          Text { text: modelData.trackTitle || "Unknown"; color: Colors.text; font.pixelSize: root.compactMode ? Colors.fontSizeMedium : Colors.fontSizeLarge; font.weight: Font.Bold; elide: Text.ElideRight }
          Text { text: modelData.trackArtist || "Unknown"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeSmall }
          Item { Layout.fillHeight: true }
          RowLayout {
            spacing: root.compactMode ? Colors.paddingSmall : Colors.paddingMedium
            Rectangle {
              width: root.compactMode ? 26 : 30; height: root.compactMode ? 26 : 30; radius: height / 2
              color: "transparent"
              Text { anchors.centerIn: parent; text: "󰒮"; color: Colors.text; font.family: Colors.fontMono; font.pixelSize: root.compactMode ? Colors.fontSizeLarge : Colors.fontSizeXL }
              SharedWidgets.StateLayer { id: prevStateLayer; hovered: prevHover.containsMouse; pressed: prevHover.pressed }
              MouseArea {
                id: prevHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                  prevStateLayer.burst(mouse.x, mouse.y);
                  (modelData._playerRef || modelData).previous();
                }
              }
            }
            Rectangle {
              width: root.compactMode ? 30 : 36; height: root.compactMode ? 30 : 36; radius: height / 2
              color: "transparent"
              Text { anchors.centerIn: parent; text: (modelData._playerRef || modelData).playbackState === Mpris.Playing ? "󰏤" : "󰐊"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: root.compactMode ? Colors.fontSizeXL : Colors.fontSizeHuge }
              SharedWidgets.StateLayer { id: playStateLayer; hovered: playHover.containsMouse; pressed: playHover.pressed }
              MouseArea {
                id: playHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                  playStateLayer.burst(mouse.x, mouse.y);
                  (modelData._playerRef || modelData).playPause();
                }
              }
            }
            Rectangle {
              width: root.compactMode ? 26 : 30; height: root.compactMode ? 26 : 30; radius: height / 2
              color: "transparent"
              Text { anchors.centerIn: parent; text: "󰒭"; color: Colors.text; font.family: Colors.fontMono; font.pixelSize: root.compactMode ? Colors.fontSizeLarge : Colors.fontSizeXL }
              SharedWidgets.StateLayer { id: nextStateLayer; hovered: nextHover.containsMouse; pressed: nextHover.pressed }
              MouseArea {
                id: nextHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                  nextStateLayer.burst(mouse.x, mouse.y);
                  (modelData._playerRef || modelData).next();
                }
              }
            }
          }
        }
      }
    }
  }
}
