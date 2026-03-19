import QtQuick
import "../../../services"
import "../../../shared"
import "../../../widgets"

MouseArea {
  id: root

  // Promote to GPU texture only during hover/press animations
  layer.enabled: containsMouse || pressed

  property string tooltipText: ""
  property string tooltipShortcut: ""
  property var anchorWindow: null
  property bool isActive: false
  property var contextActions: []
  signal contextMenuRequested(var actions, var triggerRect)
  property color activeColor: Colors.withAlpha(Colors.primary, 0.28)
  property color normalColor: Colors.bgWidget
  property color hoverColor: Colors.highlightLight
  property color activeBorderColor: Colors.primary
  property color normalBorderColor: Colors.border
  property real hoverScale: 1.04
  property real horizontalPadding: 8

  default property alias content: contentContainer.data
  signal secondaryClicked()

  function isOverlayChild(child) {
    if (!child)
      return true;
    try {
      return child.anchors && child.anchors.fill === contentContainer;
    } catch (e) {
      return false;
    }
  }

  function measuredContentWidth() {
    var maxWidth = 0;
    for (var i = 0; i < contentContainer.children.length; ++i) {
      var child = contentContainer.children[i];
      if (isOverlayChild(child))
        continue;
      maxWidth = Math.max(maxWidth, child.implicitWidth || 0, child.width || 0);
    }
    return maxWidth;
  }

  function measuredContentHeight() {
    var maxHeight = 0;
    for (var i = 0; i < contentContainer.children.length; ++i) {
      var child = contentContainer.children[i];
      if (isOverlayChild(child))
        continue;
      maxHeight = Math.max(maxHeight, child.implicitHeight || 0, child.height || 0);
    }
    return maxHeight;
  }

  height: 28
  width: measuredContentWidth() + horizontalPadding * 2
  implicitWidth: width
  implicitHeight: height
  acceptedButtons: Qt.LeftButton | Qt.RightButton
  hoverEnabled: enabled
  cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
  opacity: enabled ? 1.0 : 0.4

  // Multiplicative scale: hover lifts, press pushes back toward normal
  scale: (containsMouse ? hoverScale : 1.0) * (pressed ? 0.94 : 1.0)
  Behavior on scale { NumberAnimation { duration: Colors.durationMedium; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

  // Y-offset physics: hover lifts, press pushes down
  property real _yOffset: pressed ? 1.5 : (containsMouse ? -0.5 : 0)
  Behavior on _yOffset { Anim {} }
  transform: Translate { y: root._yOffset }

  property bool shimmerEnabled: true

  // --- Active Glow ---
  Rectangle {
    anchors.fill: parent
    anchors.margins: -3
    radius: bg.radius + 3
    color: "transparent"
    border.color: root.isActive ? Colors.withAlpha(root.activeBorderColor, 0.35) : "transparent"
    border.width: 2
    opacity: root.isActive ? 1.0 : 0.0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Colors.durationNormal } }
  }

  Rectangle {
    id: bg
    anchors.fill: parent
    color: root.isActive ? root.activeColor : (root.containsMouse ? root.hoverColor : root.normalColor)
    radius: height / 2
    clip: true
    border.color: root.isActive ? root.activeBorderColor : root.normalBorderColor
    border.width: 1
    opacity: root.isActive ? 1.0 : (root.containsMouse ? 1.0 : 0.8)
    Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
    Behavior on opacity { NumberAnimation { duration: Colors.durationFast } }
    Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }

    gradient: SurfaceGradient {}

    InnerHighlight {
      anchors.fill: parent
      hovered: root.containsMouse
      hoveredOpacity: 0.15
      highlightOpacity: 0.08
      visible: !root.isActive
    }

    // Double border effect for depth
    Rectangle {
      anchors.fill: parent
      anchors.margins: 1
      radius: parent.radius - 1
      color: "transparent"
      border.color: root.isActive ? Colors.withAlpha("#fff", 0.15) : Colors.borderLight
      border.width: 1
      opacity: root.isActive ? 0.6 : (root.containsMouse ? 0.25 : 0.1)
      Behavior on opacity { NumberAnimation { duration: Colors.durationFast } }
    }

    // Shimmer sweep on hover
    Rectangle {
      id: shimmer
      width: 60
      height: parent.height * 1.6
      y: -parent.height * 0.3
      rotation: 20
      visible: root.shimmerEnabled
      opacity: 0

      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "transparent" }
        GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.14) }
        GradientStop { position: 1.0; color: "transparent" }
      }

      NumberAnimation {
        id: shimmerAnim
        target: shimmer
        property: "x"
        from: -60
        to: root.width + 60
        duration: Colors.durationPulse
        easing.type: Easing.InOutQuad
      }

      SequentialAnimation {
        id: shimmerFade
        NumberAnimation { target: shimmer; property: "opacity"; to: 1.0; duration: Colors.durationFlash }
        PauseAnimation { duration: 440 }
        NumberAnimation { target: shimmer; property: "opacity"; to: 0.0; duration: Colors.durationFlash }
      }
    }

    ClickRipple {
      id: ripple
      color: Qt.rgba(1, 1, 1, 0.12)
    }
  }

  onContainsMouseChanged: {
    if (containsMouse && shimmerEnabled) {
      shimmerAnim.restart();
      shimmerFade.restart();
    }
  }

  onClicked: (mouse) => {
    if (mouse.button === Qt.RightButton) {
      secondaryClicked();
      if (contextActions.length > 0) {
        var globalPos = mapToItem(null, 0, 0);
        contextMenuRequested(contextActions, {
          x: globalPos.x, y: globalPos.y,
          width: root.width, height: root.height
        });
      }
      return;
    }
    ripple.burst(mouse.x, mouse.y);
  }

  Item {
    id: contentContainer
    anchors.centerIn: parent
    width: root.measuredContentWidth()
    height: root.measuredContentHeight()
  }

  BarTooltip {
    anchorItem: root
    anchorWindow: root.anchorWindow
    hovered: root.containsMouse
    text: root.tooltipText
    shortcut: root.tooltipShortcut
  }
}
