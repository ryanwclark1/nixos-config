import QtQuick
import QtQuick.Layouts
import "../../menu"
import "../../services"
import "../../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMinWidth: 280; popupMaxWidth: 300; compactThreshold: 295
  implicitHeight: compactMode ? 270 : 220
  title: "Screen Recording"

  SharedWidgets.Ref { service: RecordingService }

  // Status display
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 50
    radius: Colors.radiusMedium
    color: RecordingService.isRecording ? Colors.errorLight : Colors.cardSurface
    Behavior on color { ColorAnimation { duration: Colors.durationFast } }
    border.color: RecordingService.isRecording ? Colors.error : Colors.border
    Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }
    border.width: 1

    RowLayout {
      anchors.fill: parent
      anchors.margins: Colors.spacingM
      spacing: Colors.paddingSmall

      Rectangle {
        width: 12; height: 12; radius: Colors.radiusXXS
        color: RecordingService.isRecording ? Colors.error : Colors.textDisabled
        Behavior on color { ColorAnimation { duration: Colors.durationFast } }
        SequentialAnimation on opacity {
          running: RecordingService.isRecording
          loops: Animation.Infinite
          NumberAnimation { from: 1.0; to: 0.3; duration: Colors.durationPulse }
          NumberAnimation { from: 0.3; to: 1.0; duration: Colors.durationPulse }
        }
      }

      Text {
        text: RecordingService.isRecording ? "Recording" : "Idle"
        color: RecordingService.isRecording ? Colors.error : Colors.text
        Behavior on color { ColorAnimation { duration: Colors.durationFast } }
        font.pixelSize: Colors.fontSizeMedium
        font.weight: Font.DemiBold
      }

      Item { Layout.fillWidth: true }

      Text {
        text: RecordingService.elapsedText
        color: RecordingService.isRecording ? Colors.error : Colors.textDisabled
        Behavior on color { ColorAnimation { duration: Colors.durationFast } }
        font.pixelSize: Colors.fontSizeLarge
        font.weight: Font.Bold
        font.family: Colors.fontMono
      }
    }
  }

  // Mode buttons (only when not recording)
  GridLayout {
    Layout.fillWidth: true
    columns: root.compactMode ? 1 : 2
    columnSpacing: Colors.paddingSmall
    rowSpacing: Colors.paddingSmall
    visible: !RecordingService.isRecording

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 44
      radius: Colors.radiusMedium
      color: Colors.cardSurface
      border.color: fullscreenHover.containsMouse ? Colors.primary : Colors.border
      border.width: 1
      Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

      ColumnLayout {
        anchors.centerIn: parent
        spacing: Colors.spacingXXS
        Text { text: "󰍹"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL; Layout.alignment: Qt.AlignHCenter }
        Text { text: "Fullscreen"; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; Layout.alignment: Qt.AlignHCenter }
      }

      SharedWidgets.StateLayer {
        id: fullscreenStateLayer
        hovered: fullscreenHover.containsMouse
        pressed: fullscreenHover.pressed
      }

      MouseArea {
        id: fullscreenHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => { fullscreenStateLayer.burst(mouse.x, mouse.y); RecordingService.startRecording("fullscreen"); }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 44
      radius: Colors.radiusMedium
      color: Colors.cardSurface
      border.color: regionHover.containsMouse ? Colors.primary : Colors.border
      border.width: 1
      Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

      ColumnLayout {
        anchors.centerIn: parent
        spacing: Colors.spacingXXS
        Text { text: "󰩬"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL; Layout.alignment: Qt.AlignHCenter }
        Text { text: "Region"; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; Layout.alignment: Qt.AlignHCenter }
      }

      SharedWidgets.StateLayer {
        id: regionStateLayer
        hovered: regionHover.containsMouse
        pressed: regionHover.pressed
      }

      MouseArea {
        id: regionHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => { regionStateLayer.burst(mouse.x, mouse.y); RecordingService.startRecording("region"); }
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
    Behavior on color { ColorAnimation { duration: Colors.durationFast } }

    Text {
      anchors.centerIn: parent
      text: "󰓛  Stop Recording"
      color: Colors.background
      font.pixelSize: Colors.fontSizeMedium
      font.weight: Font.DemiBold
      font.family: Colors.fontMono
    }

    MouseArea {
      id: stopHover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: RecordingService.stopRecording()
    }
  }

  Item { Layout.fillHeight: true }
}
