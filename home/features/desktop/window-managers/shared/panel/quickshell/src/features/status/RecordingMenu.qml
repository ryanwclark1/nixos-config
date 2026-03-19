import QtQuick
import QtQuick.Layouts
import "../../shared"
import "../../services"
import "../../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMinWidth: 320; popupMaxWidth: 360; compactThreshold: 340
  implicitHeight: compactMode ? 430 : 390
  title: "Screen Recording"
  subtitle: RecordingService.isRecording
    ? ("Active · " + RecordingService.elapsedText)
    : ((Config.recordingCaptureSource === "portal" ? "Portal" : "Full Screen")
        + " · " + Config.recordingFps + " FPS · " + RecordingService.qualityLabel(Config.recordingQuality))

  SharedWidgets.Ref { service: RecordingService }

  function toggleConfigFlag(key) {
    Config[key] = !Config[key];
  }

  // Status display
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 50
    radius: Colors.radiusMedium
    color: RecordingService.isRecording ? Colors.errorLight : Colors.cardSurface
    Behavior on color { CAnim {} }
    border.color: RecordingService.isRecording ? Colors.error : Colors.border
    Behavior on border.color { CAnim {} }
    border.width: 1

    RowLayout {
      anchors.fill: parent
      anchors.margins: Colors.spacingM
      spacing: Colors.paddingSmall

      Rectangle {
        width: 12; height: 12; radius: Colors.radiusXXS
        color: RecordingService.isRecording ? Colors.error : Colors.textDisabled
        Behavior on color { CAnim {} }
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
        Behavior on color { CAnim {} }
        font.pixelSize: Colors.fontSizeMedium
        font.weight: Font.DemiBold
      }

      Item { Layout.fillWidth: true }

      Text {
        text: RecordingService.elapsedText
        color: RecordingService.isRecording ? Colors.error : Colors.textDisabled
        Behavior on color { CAnim {} }
        font.pixelSize: Colors.fontSizeLarge
        font.weight: Font.Bold
        font.family: Colors.fontMono
      }
    }
  }

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: defaultsCol.implicitHeight + Colors.spacingM * 2
    radius: Colors.radiusMedium
    color: Colors.cardSurface
    border.color: Colors.border
    border.width: 1

    ColumnLayout {
      id: defaultsCol
      anchors.fill: parent
      anchors.margins: Colors.spacingM
      spacing: Colors.spacingXS

      Text {
        text: "DEFAULTS"
        color: Colors.textDisabled
        font.pixelSize: Colors.fontSizeXS
        font.weight: Font.Bold
      }

      Text {
        Layout.fillWidth: true
        text: (Config.recordingCaptureSource === "portal" ? "Portal chooser" : "Full screen")
          + "  •  " + Config.recordingFps + " FPS  •  "
          + RecordingService.qualityLabel(Config.recordingQuality)
        color: Colors.text
        font.pixelSize: Colors.fontSizeSmall
        font.weight: Font.Medium
        wrapMode: Text.Wrap
      }

      Text {
        Layout.fillWidth: true
        text: (Config.recordingRecordCursor ? "Cursor" : "No cursor")
          + "  •  "
          + (Config.recordingIncludeDesktopAudio ? "Desktop audio" : "No desktop audio")
          + "  •  "
          + (Config.recordingIncludeMicrophoneAudio ? "Microphone" : "No microphone")
        color: Colors.textSecondary
        font.pixelSize: Colors.fontSizeXS
        wrapMode: Text.Wrap
      }
    }
  }

  // Mode buttons (only when not recording)
  GridLayout {
    Layout.fillWidth: true
    columns: root.compactMode ? 1 : 3
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
      Behavior on border.color { CAnim {} }

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
        onClicked: (mouse) => { fullscreenStateLayer.burst(mouse.x, mouse.y); RecordingService.startRecording("screen"); }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 44
      radius: Colors.radiusMedium
      color: Colors.cardSurface
      border.color: regionHover.containsMouse ? Colors.primary : Colors.border
      border.width: 1
      Behavior on border.color { CAnim {} }

      ColumnLayout {
        anchors.centerIn: parent
        spacing: Colors.spacingXXS
        Text { text: "󰹑"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL; Layout.alignment: Qt.AlignHCenter }
        Text { text: "Portal"; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; Layout.alignment: Qt.AlignHCenter }
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
        onClicked: (mouse) => { regionStateLayer.burst(mouse.x, mouse.y); RecordingService.startRecording("portal"); }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 44
      radius: Colors.radiusMedium
      color: Colors.cardSurface
      border.color: legacyRegionHover.containsMouse ? Colors.primary : Colors.border
      border.width: 1
      Behavior on border.color { CAnim {} }

      ColumnLayout {
        anchors.centerIn: parent
        spacing: Colors.spacingXXS
        Text { text: "󰩬"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL; Layout.alignment: Qt.AlignHCenter }
        Text { text: "Region"; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; Layout.alignment: Qt.AlignHCenter }
      }

      SharedWidgets.StateLayer {
        id: legacyRegionStateLayer
        hovered: legacyRegionHover.containsMouse
        pressed: legacyRegionHover.pressed
      }

      MouseArea {
        id: legacyRegionHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
          legacyRegionStateLayer.burst(mouse.x, mouse.y);
          RecordingService.startLegacyRegionRecording();
        }
      }
    }
  }

  GridLayout {
    Layout.fillWidth: true
    columns: root.compactMode ? 1 : 3
    columnSpacing: Colors.paddingSmall
    rowSpacing: Colors.paddingSmall
    visible: !RecordingService.isRecording

    Repeater {
      model: [
        {
          key: "recordingRecordCursor",
          label: "Cursor",
          icon: "󰆺",
          active: Config.recordingRecordCursor
        },
        {
          key: "recordingIncludeDesktopAudio",
          label: "Desktop Audio",
          icon: "󰕾",
          active: Config.recordingIncludeDesktopAudio
        },
        {
          key: "recordingIncludeMicrophoneAudio",
          label: "Microphone",
          icon: "󰍬",
          active: Config.recordingIncludeMicrophoneAudio
        }
      ]

      delegate: Rectangle {
        required property var modelData
        Layout.fillWidth: true
        implicitHeight: 38
        radius: Colors.radiusMedium
        color: modelData.active ? Colors.primaryMid : Colors.cardSurface
        border.color: modelData.active ? Colors.primary : Colors.border
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: modelData.icon + "  " + modelData.label
          color: modelData.active ? Colors.primary : Colors.textSecondary
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeXS
          font.weight: Font.DemiBold
        }

        SharedWidgets.StateLayer {
          id: toggleStateLayer
          hovered: toggleMouse.containsMouse
          pressed: toggleMouse.pressed
        }

        MouseArea {
          id: toggleMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: (mouse) => {
            toggleStateLayer.burst(mouse.x, mouse.y);
            root.toggleConfigFlag(modelData.key);
          }
        }
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
    Behavior on color { CAnim {} }

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
