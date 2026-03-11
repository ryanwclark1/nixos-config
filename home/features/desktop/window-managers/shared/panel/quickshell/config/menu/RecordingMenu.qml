import Quickshell
import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

PopupWindow {
  id: root
  implicitWidth: 300
  implicitHeight: 220

  Component.onCompleted: RecordingService.subscribe()
  Component.onDestruction: RecordingService.unsubscribe()

  Rectangle {
    anchors.fill: parent
    color: Colors.popupSurface
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusMedium
    clip: true

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Colors.paddingLarge
      spacing: 14

      // Header
      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "Screen Recording"
          color: Colors.fgMain
          font.pixelSize: 18
          font.weight: Font.DemiBold
        }
        Item { Layout.fillWidth: true }
        SharedWidgets.MenuCloseButton { toggleMethod: "toggleRecordingMenu" }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.border
      }

      // Status display
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 50
        radius: Colors.radiusMedium
        color: RecordingService.isRecording ? Colors.withAlpha(Colors.error, 0.15) : Colors.cardSurface
        border.color: RecordingService.isRecording ? Colors.error : Colors.border
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.margins: 12
          spacing: 10

          Rectangle {
            width: 12; height: 12; radius: 6
            color: RecordingService.isRecording ? Colors.error : Colors.textDisabled
            SequentialAnimation on opacity {
              running: RecordingService.isRecording
              loops: Animation.Infinite
              NumberAnimation { from: 1.0; to: 0.3; duration: 600 }
              NumberAnimation { from: 0.3; to: 1.0; duration: 600 }
            }
          }

          Text {
            text: RecordingService.isRecording ? "Recording" : "Idle"
            color: RecordingService.isRecording ? Colors.error : Colors.fgMain
            font.pixelSize: 14
            font.weight: Font.DemiBold
          }

          Item { Layout.fillWidth: true }

          Text {
            text: RecordingService.elapsedText
            color: RecordingService.isRecording ? Colors.error : Colors.textDisabled
            font.pixelSize: 16
            font.weight: Font.Bold
            font.family: Colors.fontMono
          }
        }
      }

      // Mode buttons (only when not recording)
      RowLayout {
        Layout.fillWidth: true
        spacing: 10
        visible: !RecordingService.isRecording

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 44
          radius: Colors.radiusMedium
          color: fullscreenHover.containsMouse ? Colors.highlightLight : Colors.cardSurface
          border.color: fullscreenHover.containsMouse ? Colors.primary : Colors.border
          border.width: 1
          Behavior on color { ColorAnimation { duration: 150 } }

          ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            Text { text: "󰍹"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 20; Layout.alignment: Qt.AlignHCenter }
            Text { text: "Fullscreen"; color: Colors.fgMain; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
          }

          MouseArea {
            id: fullscreenHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: RecordingService.startRecording("fullscreen")
          }
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 44
          radius: Colors.radiusMedium
          color: regionHover.containsMouse ? Colors.highlightLight : Colors.cardSurface
          border.color: regionHover.containsMouse ? Colors.primary : Colors.border
          border.width: 1
          Behavior on color { ColorAnimation { duration: 150 } }

          ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            Text { text: "󰩬"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 20; Layout.alignment: Qt.AlignHCenter }
            Text { text: "Region"; color: Colors.fgMain; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
          }

          MouseArea {
            id: regionHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: RecordingService.startRecording("region")
          }
        }
      }

      // Stop button (only when recording)
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 44
        radius: Colors.radiusMedium
        visible: RecordingService.isRecording
        color: stopHover.containsMouse ? Qt.darker(Colors.error, 1.1) : Colors.error

        Text {
          anchors.centerIn: parent
          text: "󰓛  Stop Recording"
          color: Colors.background
          font.pixelSize: 14
          font.weight: Font.DemiBold
          font.family: Colors.fontMono
        }

        MouseArea {
          id: stopHover
          anchors.fill: parent
          hoverEnabled: true
          onClicked: RecordingService.stopRecording()
        }
      }

      Item { Layout.fillHeight: true }
    }
  }
}
