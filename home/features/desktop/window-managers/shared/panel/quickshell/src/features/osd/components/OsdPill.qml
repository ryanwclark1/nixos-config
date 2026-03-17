import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"

RowLayout {
  id: root

  required property real currentValue
  required property real maxValue
  required property color osdColor
  required property string osdIcon
  required property string osdLabel
  required property string osdType
  required property bool isLockKey

  anchors.fill: parent
  anchors.leftMargin: Colors.spacingL
  anchors.rightMargin: Colors.spacingL
  spacing: Colors.spacingM

  function triggerPulse() {
    pillIconPulse.restart();
  }

  Text {
    id: pillIconText
    text: root.osdIcon
    color: root.osdColor
    font.pixelSize: Colors.fontSizeXL
    font.family: Colors.fontMono
    scale: 1.0

    SequentialAnimation {
      id: pillIconPulse
      NumberAnimation { target: pillIconText; property: "scale"; to: 1.22; duration: 80; easing.type: Easing.OutQuad }
      NumberAnimation { target: pillIconText; property: "scale"; to: 1.0; duration: Colors.durationFast; easing.type: Easing.OutElastic }
    }
  }

  // Progress track (draggable for volume/brightness)
  Item {
    id: osdTrack
    Layout.fillWidth: true
    Layout.preferredHeight: osdTrackMouse.pressed ? 12 : 6
    Behavior on Layout.preferredHeight { NumberAnimation { duration: Colors.durationSnap; easing.type: Easing.OutCubic } }

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
        y: -1; width: 2; height: osdTrack.height + 2
        radius: 1
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

      Behavior on width { NumberAnimation { duration: Colors.durationSnap; easing.type: Easing.OutCubic } }
    }

    // Overdrive marker at 100% when max > 1.0
    Rectangle {
      visible: root.maxValue > 1.0 && !root.isLockKey
      x: parent.width * (1.0 / root.maxValue)
      y: -2
      width: 2
      height: parent.height + 4
      radius: 1
      color: Colors.withAlpha(Colors.text, 0.4)
    }

    // Drag interaction for volume/brightness adjustment
    MouseArea {
      id: osdTrackMouse
      anchors.fill: parent
      anchors.topMargin: -12
      anchors.bottomMargin: -12
      enabled: !root.isLockKey
      hoverEnabled: true
      cursorShape: root.isLockKey ? Qt.ArrowCursor : Qt.PointingHandCursor

      function applyValue(mouseX) {
        var ratio = Math.max(0, Math.min(1.0, mouseX / osdTrack.width));
        var value = ratio * root.maxValue;
        if (root.osdType === "volume") {
          var pct = Math.round(value * 100);
          Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", pct + "%"]);
        } else if (root.osdType === "mic") {
          var pct = Math.round(value * 100);
          Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", pct + "%"]);
        } else if (root.osdType === "brightness") {
          var pct = Math.round(value * 100);
          Quickshell.execDetached(["brightnessctl", "set", pct + "%"]);
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
    font.pixelSize: Colors.fontSizeMedium
    font.weight: Font.Bold
    font.family: Colors.fontMono
    Layout.minimumWidth: 70
    horizontalAlignment: Text.AlignRight
  }
}
