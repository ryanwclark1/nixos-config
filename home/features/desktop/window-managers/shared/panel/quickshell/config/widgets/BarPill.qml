import QtQuick
import "../services"

MouseArea {
  id: root

  // Promote to GPU texture only during hover/press animations
  layer.enabled: containsMouse || pressed

  property string tooltipText: ""
  property var anchorWindow: null
  property bool isActive: false
  property color activeColor: Colors.withAlpha(Colors.primary, 0.28)
  property color normalColor: Colors.bgWidget
  property color hoverColor: Colors.highlightLight
  property real hoverScale: 1.04
  property real horizontalPadding: 8

  default property alias content: contentContainer.data

  height: 28
  width: contentContainer.childrenRect.width + horizontalPadding * 2
  hoverEnabled: enabled
  cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
  opacity: enabled ? 1.0 : 0.4

  // Multiplicative scale: hover lifts, press pushes back toward normal
  scale: (containsMouse ? hoverScale : 1.0) * (pressed ? 0.94 : 1.0)
  Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

  // Y-offset physics: hover lifts, press pushes down
  property real _yOffset: pressed ? 1.5 : (containsMouse ? -0.5 : 0)
  Behavior on _yOffset { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutCubic } }
  transform: Translate { y: root._yOffset }

  property bool shimmerEnabled: true

  Rectangle {
    id: bg
    anchors.fill: parent
    color: root.isActive ? root.activeColor : (root.containsMouse ? root.hoverColor : root.normalColor)
    radius: height / 2
    clip: true
    border.color: root.isActive ? Colors.primary : "transparent"
    border.width: root.isActive ? 1 : 0
    Behavior on color { ColorAnimation { duration: Colors.durationFast } }

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
        duration: 600
        easing.type: Easing.InOutQuad
      }

      SequentialAnimation {
        id: shimmerFade
        NumberAnimation { target: shimmer; property: "opacity"; to: 1.0; duration: 80 }
        PauseAnimation { duration: 440 }
        NumberAnimation { target: shimmer; property: "opacity"; to: 0.0; duration: 80 }
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

  onClicked: (mouse) => ripple.burst(mouse.x, mouse.y)

  Item {
    id: contentContainer
    anchors.centerIn: parent
    anchors.verticalCenterOffset: -1
    width: childrenRect.width
    height: childrenRect.height
  }

  BarTooltip {
    anchorItem: root
    anchorWindow: root.anchorWindow
    hovered: root.containsMouse
    text: root.tooltipText
  }
}
