import QtQuick
import "../services"

// Scrollbar — a 6px capsule scrollbar that auto-hides after 1200ms.
// Bind `flickable` to the Flickable/ListView you want to control.
//
// Usage:
//   Item {
//     Layout.fillWidth: true
//     Layout.fillHeight: true
//
//     Flickable { id: myFlick; anchors.fill: parent; ... }
//
//     Scrollbar { flickable: myFlick }
//   }

Item {
  id: root

  // The Flickable (or ListView) to bind to.
  property Flickable flickable: null

  // ── Derived geometry ──────────────────────────────────────────────────────
  readonly property bool _overflow: flickable ? flickable.contentHeight > flickable.height : false
  readonly property real _thumbRatio: (flickable && flickable.contentHeight > 0)
    ? Math.min(1.0, flickable.height / flickable.contentHeight)
    : 1.0
  readonly property real _thumbH: Math.max(24, _thumbRatio * height)
  readonly property real _thumbY: (flickable && (flickable.contentHeight - flickable.height) > 0)
    ? (flickable.contentY / (flickable.contentHeight - flickable.height)) * (height - _thumbH)
    : 0

  // ── Default positioning: overlay on the right edge of the flickable ───────
  anchors.right: flickable ? flickable.right : undefined
  anchors.top: flickable ? flickable.top : undefined
  anchors.bottom: flickable ? flickable.bottom : undefined
  anchors.rightMargin: 2
  width: 6

  // Only meaningful when there is overflow.
  visible: _overflow
  opacity: _visible ? 1.0 : 0.0
  Behavior on opacity { Anim { duration: Appearance.durationFast } }

  // ── Show/hide state ───────────────────────────────────────────────────────
  property bool _visible: false

  readonly property int _scrollbarHideMs: 1200

  Timer {
    id: hideTimer
    interval: root._scrollbarHideMs
    repeat: false
    onTriggered: if (!thumbDrag.drag.active && !thumbDrag.containsMouse) root._visible = false
  }

  // Wake the scrollbar on any scroll activity.
  Connections {
    target: root.flickable
    enabled: root.flickable !== null

    function onContentYChanged() {
      root._visible = true;
      hideTimer.restart();
    }

    function onMovingChanged() {
      if (root.flickable && root.flickable.moving) {
        root._visible = true;
        hideTimer.restart();
      }
    }
  }

  // ── Track rail ────────────────────────────────────────────────────────────
  Rectangle {
    anchors.fill: parent
    radius: width / 2
    color: Colors.withAlpha(Colors.border, 0.25)
  }

  // ── Thumb ─────────────────────────────────────────────────────────────────
  Rectangle {
    id: thumb
    width: parent.width
    height: root._thumbH
    // During drag the MouseArea drives y; otherwise track the flickable.
    y: thumbDrag.drag.active ? y : root._thumbY
    radius: width / 2

    // 3-state colour.
    color: {
      if (thumbDrag.drag.active)   return Colors.primary;
      if (thumbDrag.containsMouse) return Colors.textSecondary;
      return Colors.border;
    }
    Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
    // Smooth position updates while not dragging.
    Behavior on y {
      enabled: !thumbDrag.drag.active
      NumberAnimation { duration: Appearance.durationFlash; easing.type: Easing.OutCubic }
    }

    // ── Drag + hover MouseArea ─────────────────────────────────────────────
    MouseArea {
      id: thumbDrag
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.SizeVerCursor

      drag.target: thumb
      drag.axis: Drag.YAxis
      drag.minimumY: 0
      drag.maximumY: root.height - thumb.height

      // Show on hover; keep alive while dragging.
      onEntered: {
        root._visible = true;
        hideTimer.stop();
      }
      onExited: {
        if (!drag.active) hideTimer.restart();
      }

      // Propagate thumb position → flickable contentY during drag.
      onPositionChanged: {
        if (!drag.active || !root.flickable) return;
        var trackRange = root.height - thumb.height;
        if (trackRange > 0) {
          var ratio = thumb.y / trackRange;
          var maxContentY = root.flickable.contentHeight - root.flickable.height;
          root.flickable.contentY = Math.max(0, Math.min(maxContentY, ratio * maxContentY));
        }
        root._visible = true;
        hideTimer.restart();
      }

      drag.onActiveChanged: {
        if (!drag.active) {
          if (!containsMouse) hideTimer.restart();
        } else {
          root._visible = true;
          hideTimer.stop();
        }
      }
    }
  }
}
