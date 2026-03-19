import QtQuick
import QtQuick.Layouts
import "../services"

// ScrollableContent — reusable scrollable wrapper for popup menus.
//
// Replaces the boilerplate Item + Flickable + ColumnLayout + Scrollbar
// + OverscrollGlow pattern used across popup menus.
//
// Usage:
//   ScrollableContent {
//     Layout.fillWidth: true
//     Layout.fillHeight: true
//     // children go directly into the inner ColumnLayout
//     Text { text: "Hello" }
//   }

Item {
  id: root

  property int columnSpacing: Colors.spacingM
  default property alias content: contentColumn.data
  readonly property alias flickable: flick

  Flickable {
    id: flick
    anchors.fill: parent
    contentHeight: contentColumn.implicitHeight
    clip: true
    boundsBehavior: Flickable.DragOverBounds

    ColumnLayout {
      id: contentColumn
      width: parent.width
      spacing: root.columnSpacing
    }
  }

  Item {
    id: scrollbar
    readonly property bool overflow: flick.contentHeight > flick.height
    readonly property real thumbRatio: flick.contentHeight > 0 ? Math.min(1.0, flick.height / flick.contentHeight) : 1.0
    readonly property real thumbHeight: Math.max(24, thumbRatio * height)
    readonly property real thumbY: (flick.contentHeight - flick.height) > 0
      ? (flick.contentY / (flick.contentHeight - flick.height)) * (height - thumbHeight)
      : 0
    property bool visibleState: false

    anchors.right: flick.right
    anchors.top: flick.top
    anchors.bottom: flick.bottom
    anchors.rightMargin: 2
    width: 6
    visible: overflow
    opacity: visibleState ? 1.0 : 0.0

    Behavior on opacity { Anim { duration: Colors.durationFast } }

    readonly property int _scrollbarHideMs: 1200

    Timer {
      id: hideTimer
      interval: scrollbar._scrollbarHideMs
      repeat: false
      onTriggered: if (!thumbDrag.drag.active && !thumbDrag.containsMouse) scrollbar.visibleState = false
    }

    Connections {
      target: flick

      function onContentYChanged() {
        scrollbar.visibleState = true;
        hideTimer.restart();
      }

      function onMovingChanged() {
        if (flick.moving) {
          scrollbar.visibleState = true;
          hideTimer.restart();
        }
      }
    }

    Rectangle {
      anchors.fill: parent
      radius: width / 2
      color: Colors.withAlpha(Colors.border, 0.25)
    }

    Rectangle {
      id: thumb
      width: parent.width
      height: scrollbar.thumbHeight
      y: thumbDrag.drag.active ? y : scrollbar.thumbY
      radius: width / 2
      color: thumbDrag.drag.active ? Colors.primary : (thumbDrag.containsMouse ? Colors.textSecondary : Colors.border)

      Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }

      Behavior on y {
        enabled: !thumbDrag.drag.active
        NumberAnimation { duration: Colors.durationFlash; easing.type: Easing.OutCubic }
      }

      MouseArea {
        id: thumbDrag
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.SizeVerCursor
        drag.target: thumb
        drag.axis: Drag.YAxis
        drag.minimumY: 0
        drag.maximumY: scrollbar.height - thumb.height

        onEntered: {
          scrollbar.visibleState = true;
          hideTimer.stop();
        }
        onExited: if (!drag.active) hideTimer.restart()

        onPositionChanged: {
          if (!drag.active)
            return;
          var trackRange = scrollbar.height - thumb.height;
          if (trackRange > 0) {
            var ratio = thumb.y / trackRange;
            var maxContentY = flick.contentHeight - flick.height;
            flick.contentY = Math.max(0, Math.min(maxContentY, ratio * maxContentY));
          }
          scrollbar.visibleState = true;
          hideTimer.restart();
        }

        drag.onActiveChanged: {
          if (!drag.active) {
            if (!containsMouse)
              hideTimer.restart();
          } else {
            scrollbar.visibleState = true;
            hideTimer.stop();
          }
        }
      }
    }
  }

  Item {
    anchors.fill: flick

    readonly property real verticalOvershootSafe: flick ? flick.verticalOvershoot : 0

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: Math.min(60, Math.abs(parent.verticalOvershootSafe) * 0.6)
      visible: parent.verticalOvershootSafe < 0
      gradient: Gradient {
        GradientStop { position: 0.0; color: Colors.highlightLight }
        GradientStop { position: 1.0; color: "transparent" }
      }
    }

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: Math.min(60, Math.abs(parent.verticalOvershootSafe) * 0.6)
      visible: parent.verticalOvershootSafe > 0
      gradient: Gradient {
        GradientStop { position: 0.0; color: "transparent" }
        GradientStop { position: 1.0; color: Colors.highlightLight }
      }
    }
  }
}
