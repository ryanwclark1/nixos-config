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
  Behavior on height { Anim { duration: Appearance.durationFast } }

  transform: Scale {
    origin.x: root.width / 2
    origin.y: root.height / 2
    xScale: sliderMouse.pressed ? 1.02 : 1.0
    yScale: sliderMouse.pressed ? 0.96 : 1.0
    Behavior on xScale { NumberAnimation { duration: Appearance.durationNormal; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
    Behavior on yScale { NumberAnimation { duration: Appearance.durationNormal; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
  }
  color: sliderMouse.containsMouse ? Colors.surface : Colors.bgWidget
  radius: height / 2
  border.color: root.muted ? root.mutedColor : (sliderMouse.containsMouse ? root.activeColor : Colors.border)
  border.width: 1

  Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
  Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }

  // Background inner shadow/depth
  Rectangle {
    anchors.fill: parent
    anchors.margins: 1
    radius: parent.radius - 1
    color: "transparent"
    border.color: Colors.borderDark
    border.width: 1
    opacity: 0.1
  }

  // Tick marks at 25%, 50%, 75%
  Repeater {
    model: [0.25, 0.50, 0.75]
    Rectangle {
      x: root.width * modelData - 1
      y: 2; width: 2; height: root.height - 4
      radius: Appearance.radiusXXXS
      color: Colors.withAlpha(Colors.textDisabled, 0.2)
      visible: !root.muted && root.value < modelData
    }
  }

  Rectangle {
    id: thumb
    height: parent.height
    width: Math.max(root.minThumbWidth, parent.width * (root.muted ? 0 : root.value))
    radius: parent.radius
    color: root.muted ? root.mutedColor : root.activeColor
    Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }

    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0; color: root.muted ? root.mutedColor : root.activeColor }
      GradientStop { position: 1.0; color: root.muted ? Qt.lighter(root.mutedColor, 1.2) : Qt.lighter(root.activeColor, 1.15) }
    }

    // Inner highlight for the thumb
    Rectangle {
      anchors.fill: parent
      anchors.margins: 1
      radius: parent.radius - 1
      color: "transparent"
      border.color: Colors.withAlpha("#ffffff", 0.25)
      border.width: 1
    }

    Loader {
      anchors.centerIn: parent
      visible: root.muted || root.value > root.minVisibleValue
      property string _ic: root.muted ? root.mutedIcon : root.icon
      property color _co: root.value > 0.15 ? Colors.background : Colors.text
      sourceComponent: String(_ic).endsWith(".svg") ? _stSvg : _stNerd
    }
    Component { id: _stSvg; SvgIcon { source: parent._ic; color: parent._co; size: Appearance.fontSizeSmall } }
    Component { id: _stNerd; Text { text: parent._ic; color: parent._co; Behavior on color { enabled: !Colors.isTransitioning; CAnim {} } font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeSmall } }
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
