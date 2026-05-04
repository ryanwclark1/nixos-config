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
  readonly property real clampedValue: Math.max(0, Math.min(1.0, value))
  readonly property real fillWidth: Math.max(minThumbWidth, width * (muted ? 0 : clampedValue))

  signal sliderMoved(real newValue)

  activeFocusOnTab: true
  Accessible.role: Accessible.Slider
  Accessible.name: root.icon || "Slider"
  Accessible.value: Math.round(root.value * 100) + "%"
  Accessible.onIncreaseAction: root._flushSliderValue(root.value + 0.05)
  Accessible.onDecreaseAction: root._flushSliderValue(root.value - 0.05)

  Keys.onPressed: event => {
    var step = 0.05;
    if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) {
      root._flushSliderValue(root.value - step);
      event.accepted = true;
    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) {
      root._flushSliderValue(root.value + step);
      event.accepted = true;
    } else if (event.key === Qt.Key_Home) {
      root._flushSliderValue(0);
      event.accepted = true;
    } else if (event.key === Qt.Key_End) {
      root._flushSliderValue(1);
      event.accepted = true;
    } else if (event.key === Qt.Key_PageUp) {
      root._flushSliderValue(root.value + 0.2);
      event.accepted = true;
    } else if (event.key === Qt.Key_PageDown) {
      root._flushSliderValue(root.value - 0.2);
      event.accepted = true;
    }
  }

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

  height: 28
  color: sliderMouse.containsMouse ? Colors.surface : Colors.bgWidget
  radius: height / 2
  border.color: root.activeFocus ? Colors.primary : (root.muted ? root.mutedColor : (sliderMouse.containsMouse ? root.activeColor : Colors.border))
  border.width: root.activeFocus ? 2 : 1

  Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
  Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }

  // Background inner shadow/depth
  Rectangle {
    anchors.fill: parent
    anchors.margins: root.activeFocus ? 2 : 1
    radius: parent.radius - (root.activeFocus ? 2 : 1)
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
      y: root.activeFocus ? 3 : 2; width: 2; height: root.height - (root.activeFocus ? 6 : 4)
      radius: Appearance.radiusXXXS
      color: Colors.withAlpha(Colors.textDisabled, 0.2)
      visible: !root.muted && root.value < modelData
    }
  }

  Rectangle {
    id: thumb
    height: parent.height
    width: root.fillWidth
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
      anchors.margins: root.activeFocus ? 2 : 1
      radius: parent.radius - (root.activeFocus ? 2 : 1)
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

  Rectangle {
    id: knob
    readonly property real knobSize: Math.max(16, root.height - 6)
    width: knobSize
    height: knobSize
    radius: knobSize / 2
    y: (root.height - height) / 2
    x: Math.max(3, Math.min(root.width - width - 3, root.fillWidth - width - 3))
    color: root.muted ? Colors.surfaceContainerHighest : Colors.background
    border.width: root.activeFocus ? 3 : 2
    border.color: root.muted ? root.mutedColor : root.activeColor
    z: 2
    scale: sliderMouse.pressed ? 1.06 : (sliderMouse.containsMouse ? 1.02 : 1.0)

    Behavior on x { enabled: !Colors.isTransitioning; NumberAnimation { duration: Appearance.durationFast; easing.type: Easing.OutCubic } }
    Behavior on scale { enabled: !Colors.isTransitioning; NumberAnimation { duration: Appearance.durationFast; easing.type: Easing.OutCubic } }
    Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
    Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }

    Rectangle {
      anchors.fill: parent
      anchors.margins: 2
      radius: parent.radius - 2
      color: "transparent"
      border.width: 1
      border.color: Colors.withAlpha("#ffffff", sliderMouse.pressed ? 0.4 : 0.24)
    }
  }

  MouseArea {
    id: sliderMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onPressed: (mouse) => {
        root.forceActiveFocus();
        if (width > 0) root._flushSliderValue(mouse.x / width);
    }
    onPositionChanged: (mouse) => { if (pressed && width > 0) root._queueSliderValue(mouse.x / width); }
    onReleased: (mouse) => { if (width > 0) root._flushSliderValue(mouse.x / width); }
  }
}
