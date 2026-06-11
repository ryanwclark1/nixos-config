import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets

RowLayout {
  id: root

  required property real currentValue
  required property real maxValue
  required property color osdColor
  required property string osdIcon
  required property string osdLabel
  required property string osdType
  required property bool isLockKey

  readonly property real scaleFactor: parent.height / 56.0

  anchors.fill: parent
  anchors.leftMargin: Appearance.spacingL * scaleFactor
  anchors.rightMargin: Appearance.spacingL * scaleFactor
  spacing: Appearance.spacingM * scaleFactor

  function triggerPulse() {
    pillIconPulse.restart();
  }

  Item {
    id: pillIconContainer
    implicitWidth: pillIconLoader.item ? pillIconLoader.item.implicitWidth : Appearance.fontSizeXL * scaleFactor
    implicitHeight: pillIconLoader.item ? pillIconLoader.item.implicitHeight : Appearance.fontSizeXL * scaleFactor
    scale: 1.0

    Loader {
      id: pillIconLoader
      anchors.centerIn: parent
      sourceComponent: String(root.osdIcon).endsWith(".svg") ? _pillSvg : _pillNerd
    }
    Component { id: _pillSvg; SharedWidgets.SvgIcon { source: root.osdIcon; color: root.osdColor; size: Appearance.fontSizeXL * root.scaleFactor } }
    Component { id: _pillNerd; Text { text: root.osdIcon; color: root.osdColor; font.pixelSize: Appearance.fontSizeXL * root.scaleFactor; font.family: Appearance.fontMono } }

    SequentialAnimation {
      id: pillIconPulse
      NumberAnimation { target: pillIconContainer; property: "scale"; to: 1.22; duration: Appearance.durationFlash; easing.type: Easing.OutQuad }
      NumberAnimation { target: pillIconContainer; property: "scale"; to: 1.0; duration: Appearance.durationFast; easing.type: Easing.OutElastic }
    }
  }

  // Progress track (draggable for volume/brightness)
  Item {
    id: osdTrack
    Layout.fillWidth: true
    Layout.preferredHeight: (osdTrackMouse.pressed ? 12 : 6) * root.scaleFactor
    Behavior on Layout.preferredHeight { NumberAnimation { duration: Appearance.durationSnap; easing.type: Easing.OutCubic } }

    Rectangle {
      anchors.fill: parent
      radius: parent.height / 2
      color: Colors.withAlpha(root.osdColor, 0.2)
    }

    // Tick marks at 25%, 50%, 75%
    Repeater {
      model: root.isLockKey ? [] : [0.25, 0.50, 0.75]
      Rectangle {
        x: osdTrack.width * modelData - 1
        y: -1 * root.scaleFactor; width: 2 * root.scaleFactor; height: osdTrack.height + 2 * root.scaleFactor
        radius: Appearance.radiusXXXS
        color: Colors.withAlpha(Colors.text, 0.2)
        visible: (root.currentValue / root.maxValue) < modelData
      }
    }

    Rectangle {
      width: {
        if (root.isLockKey) return root.currentValue * parent.width;
        return parent.width * Math.min(1.0, root.currentValue / root.maxValue);
      }
      height: parent.height
      radius: parent.height / 2
      color: root.osdColor

      Behavior on width { NumberAnimation { duration: Appearance.durationSnap; easing.type: Easing.OutCubic } }
    }

    // Overdrive marker at 100% when max > 1.0
    Rectangle {
      visible: root.maxValue > 1.0 && !root.isLockKey
      x: parent.width * (1.0 / root.maxValue)
      y: -2 * root.scaleFactor
      width: 2 * root.scaleFactor
      height: parent.height + 4 * root.scaleFactor
      radius: Appearance.radiusXXXS
      color: Colors.borderMedium
    }

    // Drag interaction for volume/brightness adjustment
    MouseArea {
      id: osdTrackMouse
      anchors.fill: parent
      anchors.topMargin: -12 * root.scaleFactor
      anchors.bottomMargin: -12 * root.scaleFactor
      enabled: !root.isLockKey
      hoverEnabled: true
      cursorShape: root.isLockKey ? Qt.ArrowCursor : Qt.PointingHandCursor

      function applyValue(mouseX) {
        var ratio = Math.max(0, Math.min(1.0, mouseX / osdTrack.width));
        var value = ratio * root.maxValue;
        if (root.osdType === "volume") {
          AudioService.setVolume("@DEFAULT_AUDIO_SINK@", value);
        } else if (root.osdType === "mic") {
          AudioService.setVolume("@DEFAULT_AUDIO_SOURCE@", value);
        } else if (root.osdType === "brightness") {
          BrightnessService.setBrightness(BrightnessService.primaryMonitor.name, ratio);
        } else if (root.osdType === "kbdbrightness") {
          BrightnessService.setKbdBrightness(value);
        }
      }

      onPressed: (mouse) => applyValue(mouse.x)
      onPositionChanged: (mouse) => { if (pressed) applyValue(mouse.x); }
    }
  }

  Text {
    text: root.osdLabel
    color: Colors.text
    font.pixelSize: Appearance.fontSizeMedium * root.scaleFactor
    font.weight: Font.Bold
    font.family: Appearance.fontMono
    Layout.minimumWidth: 70 * root.scaleFactor
    horizontalAlignment: Text.AlignRight
  }
}
