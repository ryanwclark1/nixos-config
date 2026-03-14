import QtQuick
import "../services"

Rectangle {
  id: root

  property real value: 0
  property bool muted: false
  property string icon: ""
  property string mutedIcon: ""
  property color activeColor: Colors.primary
  property color mutedColor: Colors.error
  property real minThumbWidth: 28
  property real minVisibleValue: 0.1

  signal sliderMoved(real newValue)

  // Debounce: coalesce rapid slider moves into throttled emissions
  property real _pendingValue: -1
  Timer {
    id: debounceTimer
    interval: 70
    onTriggered: {
      if (root._pendingValue >= 0) {
        root.sliderMoved(root._pendingValue);
        root._pendingValue = -1;
      }
    }
  }
  function _queueSliderValue(val) {
    _pendingValue = Math.max(0, Math.min(1.0, val));
    debounceTimer.restart();
  }
  function _flushSliderValue(val) {
    debounceTimer.stop();
    var v = Math.max(0, Math.min(1.0, val));
    root.sliderMoved(v);
    _pendingValue = -1;
  }

  height: sliderMouse.pressed ? 32 : 28
  Behavior on height { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }

  transform: Scale {
    origin.x: root.width / 2
    origin.y: root.height / 2
    xScale: sliderMouse.pressed ? 1.02 : 1.0
    yScale: sliderMouse.pressed ? 0.96 : 1.0
    Behavior on xScale { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
    Behavior on yScale { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
  }
  color: sliderMouse.containsMouse ? Colors.surface : Colors.bgWidget
  radius: height / 2
  border.color: sliderMouse.containsMouse ? (root.muted ? root.mutedColor : root.activeColor) : Colors.border
  border.width: 1

  Behavior on color { ColorAnimation { duration: Colors.durationFast } }
  Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

  // Tick marks at 25%, 50%, 75%
  Repeater {
    model: [0.25, 0.50, 0.75]
    Rectangle {
      x: root.width * modelData - 1
      y: 0; width: 2; height: root.height
      radius: 1
      color: Colors.withAlpha(Colors.textDisabled, 0.3)
      visible: !root.muted && root.value < modelData
    }
  }

  Rectangle {
    height: parent.height
    width: Math.max(root.minThumbWidth, parent.width * (root.muted ? 0 : root.value))
    radius: parent.radius
    color: root.muted ? root.mutedColor : (sliderMouse.containsMouse ? Qt.darker(root.activeColor, 1.08) : root.activeColor)
    opacity: root.muted ? 1.0 : (0.3 + root.value * 0.7)
    Behavior on color { ColorAnimation { duration: Colors.durationFast } }
    Behavior on opacity { NumberAnimation { duration: Colors.durationFast } }

    Text {
      anchors.centerIn: parent
      text: root.muted ? root.mutedIcon : root.icon
      color: root.value > 0.15 ? Colors.background : Colors.text
      Behavior on color { ColorAnimation { duration: Colors.durationFast } }
      font.family: Colors.fontMono
      font.pixelSize: Colors.fontSizeSmall
      opacity: 1.0 / Math.max(0.3, parent.opacity)
      visible: root.muted || root.value > root.minVisibleValue
    }
  }

  MouseArea {
    id: sliderMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onPressed: (mouse) => { if (width > 0) root._flushSliderValue(mouse.x / width); }
    onPositionChanged: (mouse) => { if (pressed && width > 0) root._queueSliderValue(mouse.x / width); }
    onReleased: (mouse) => { if (width > 0) root._flushSliderValue(mouse.x / width); }
  }
}
