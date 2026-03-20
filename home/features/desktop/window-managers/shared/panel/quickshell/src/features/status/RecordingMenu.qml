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
    radius: Appearance.radiusMedium
    color: RecordingService.isRecording ? Colors.errorLight : Colors.cardSurface
    Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
    border.color: RecordingService.isRecording ? Colors.error : Colors.border
    Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }
    border.width: 1

    RowLayout {
      anchors.fill: parent
      anchors.margins: Appearance.spacingM
      spacing: Appearance.paddingSmall

      Rectangle {
        width: 12; height: 12; radius: Appearance.radiusXXS
        color: RecordingService.isRecording ? Colors.error : Colors.textDisabled
        Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
        SequentialAnimation on opacity {
          running: RecordingService.isRecording
          loops: Animation.Infinite
          NumberAnimation { from: 1.0; to: 0.3; duration: Appearance.durationPulse }
          NumberAnimation { from: 0.3; to: 1.0; duration: Appearance.durationPulse }
        }
      }

      Text {
        text: RecordingService.isRecording ? "Recording" : "Idle"
        color: RecordingService.isRecording ? Colors.error : Colors.text
        Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
        font.pixelSize: Appearance.fontSizeMedium
        font.weight: Font.DemiBold
      }

      Item { Layout.fillWidth: true }

      Text {
        text: RecordingService.elapsedText
        color: RecordingService.isRecording ? Colors.error : Colors.textDisabled
        Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
        font.pixelSize: Appearance.fontSizeLarge
        font.weight: Font.Bold
        font.family: Appearance.fontMono
      }
    }
  }

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: defaultsCol.implicitHeight + Appearance.spacingM * 2
    radius: Appearance.radiusMedium
    color: Colors.cardSurface
    border.color: Colors.border
    border.width: 1

    ColumnLayout {
      id: defaultsCol
      anchors.fill: parent
      anchors.margins: Appearance.spacingM
      spacing: Appearance.spacingXS

      Text {
        text: "DEFAULTS"
        color: Colors.textDisabled
        font.pixelSize: Appearance.fontSizeXS
        font.weight: Font.Bold
      }

      Text {
        Layout.fillWidth: true
        text: (Config.recordingCaptureSource === "portal" ? "Portal chooser" : "Full screen")
          + "  •  " + Config.recordingFps + " FPS  •  "
          + RecordingService.qualityLabel(Config.recordingQuality)
        color: Colors.text
        font.pixelSize: Appearance.fontSizeSmall
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
        font.pixelSize: Appearance.fontSizeXS
        wrapMode: Text.Wrap
      }
    }
  }

  // Mode buttons (only when not recording)
  GridLayout {
    Layout.fillWidth: true
    columns: root.compactMode ? 1 : 3
    columnSpacing: Appearance.paddingSmall
    rowSpacing: Appearance.paddingSmall
    visible: !RecordingService.isRecording

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 44
      radius: Appearance.radiusMedium
      color: Colors.cardSurface
      border.color: fullscreenHover.containsMouse ? Colors.primary : Colors.border
      border.width: 1
      Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }

      ColumnLayout {
        anchors.centerIn: parent
        spacing: Appearance.spacingXXS
        SharedWidgets.SvgIcon { source: "fullscreen.svg"; color: Colors.primary; size: Appearance.fontSizeXL; Layout.alignment: Qt.AlignHCenter }
        Text { text: "Fullscreen"; color: Colors.text; font.pixelSize: Appearance.fontSizeSmall; Layout.alignment: Qt.AlignHCenter }
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
      radius: Appearance.radiusMedium
      color: Colors.cardSurface
      border.color: regionHover.containsMouse ? Colors.primary : Colors.border
      border.width: 1
      Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }

      ColumnLayout {
        anchors.centerIn: parent
        spacing: Appearance.spacingXXS
        SharedWidgets.SvgIcon { source: "desktop.svg"; color: Colors.primary; size: Appearance.fontSizeXL; Layout.alignment: Qt.AlignHCenter }
        Text { text: "Portal"; color: Colors.text; font.pixelSize: Appearance.fontSizeSmall; Layout.alignment: Qt.AlignHCenter }
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
      radius: Appearance.radiusMedium
      color: Colors.cardSurface
      border.color: legacyRegionHover.containsMouse ? Colors.primary : Colors.border
      border.width: 1
      Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }

      ColumnLayout {
        anchors.centerIn: parent
        spacing: Appearance.spacingXXS
        SharedWidgets.SvgIcon { source: "crop.svg"; color: Colors.primary; size: Appearance.fontSizeXL; Layout.alignment: Qt.AlignHCenter }
        Text { text: "Region"; color: Colors.text; font.pixelSize: Appearance.fontSizeSmall; Layout.alignment: Qt.AlignHCenter }
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
    columnSpacing: Appearance.paddingSmall
    rowSpacing: Appearance.paddingSmall
    visible: !RecordingService.isRecording

    Repeater {
      model: [
        {
          key: "recordingRecordCursor",
          label: "Cursor",
          icon: "cursor-click.svg",
          active: Config.recordingRecordCursor
        },
        {
          key: "recordingIncludeDesktopAudio",
          label: "Desktop Audio",
          icon: "speaker.svg",
          active: Config.recordingIncludeDesktopAudio
        },
        {
          key: "recordingIncludeMicrophoneAudio",
          label: "Microphone",
          icon: "mic.svg",
          active: Config.recordingIncludeMicrophoneAudio
        }
      ]

      delegate: Rectangle {
        required property var modelData
        Layout.fillWidth: true
        implicitHeight: Appearance.controlRowHeight
        radius: Appearance.radiusMedium
        color: modelData.active ? Colors.primaryMid : Colors.cardSurface
        border.color: modelData.active ? Colors.primary : Colors.border
        border.width: 1

        Row {
          anchors.centerIn: parent
          spacing: Appearance.spacingS
          SharedWidgets.SvgIcon {
            source: modelData.icon
            color: modelData.active ? Colors.primary : Colors.textSecondary
            size: Appearance.fontSizeSmall
            anchors.verticalCenter: parent.verticalCenter
          }
          Text {
            text: modelData.label
            color: modelData.active ? Colors.primary : Colors.textSecondary
            font.pixelSize: Appearance.fontSizeXS
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
          }
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
    radius: Appearance.radiusMedium
    visible: RecordingService.isRecording
    color: stopHover.containsMouse ? Qt.darker(Colors.error, 1.1) : Colors.error
    Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }

    Row {
      anchors.centerIn: parent
      spacing: Appearance.spacingS
      SharedWidgets.SvgIcon {
        source: "stop.svg"
        color: Colors.background
        size: Appearance.fontSizeMedium
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        text: "Stop Recording"
        color: Colors.background
        font.pixelSize: Appearance.fontSizeMedium
        font.weight: Font.DemiBold
        anchors.verticalCenter: parent.verticalCenter
      }
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
