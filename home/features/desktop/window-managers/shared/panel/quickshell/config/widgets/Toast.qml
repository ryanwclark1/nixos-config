import QtQuick
import "../services"

Item {
  id: root
  width: 340
  height: contentCol.height + 24
  visible: false

  property string title: ""
  property string description: ""
  property string icon: "󰋼"
  property string type: "notice"
  property int duration: 3000
  property real progress: 1.0

  signal hidden()

  // ── Type-dependent border color ────────────────
  readonly property color borderColor: type === "error" ? Colors.error
    : type === "success" ? Colors.primary
    : Colors.border

  // ── Swipe tracking ─────────────────────────────
  property real _swipeStartX: 0
  property real _swipeOffset: 0
  property bool _isSwiping: false
  readonly property real _dismissThreshold: Math.max(80, width * 0.28)

  // ── Show / Hide ────────────────────────────────
  function show(t, d, i, ty, dur) {
    title = t || "";
    description = d || "";
    icon = i || "󰋼";
    type = ty || "notice";
    duration = dur || 3000;
    progress = 1.0;
    _swipeOffset = 0;
    visible = true;
    opacity = 1.0;
    scale = 1.0;
    progressAnim.duration = duration;
    progressAnim.restart();
  }

  function hide() {
    progressAnim.stop();
    hideAnim.start();
  }

  // ── Progress animation ─────────────────────────
  NumberAnimation {
    id: progressAnim
    target: root
    property: "progress"
    from: 1.0
    to: 0.0
    duration: root.duration
    running: false
    onFinished: root.hide()
  }

  // ── Hide animation ─────────────────────────────
  ParallelAnimation {
    id: hideAnim
    NumberAnimation { target: root; property: "opacity"; to: 0; duration: Colors.durationNormal; easing.type: Easing.InCubic }
    NumberAnimation { target: root; property: "scale"; to: 0.9; duration: Colors.durationNormal; easing.type: Easing.InCubic }
    onFinished: { root.visible = false; root.hidden(); }
  }

  // ── Hover pause ────────────────────────────────
  HoverHandler {
    id: hoverHandler
    onHoveredChanged: {
      if (hovered) {
        progressAnim.pause();
      } else {
        resumeTimer.restart();
      }
    }
  }

  Timer {
    id: resumeTimer
    interval: 50
    onTriggered: if (!hoverHandler.hovered && progressAnim.paused) progressAnim.resume()
  }

  // ── Visual ─────────────────────────────────────
  transform: Translate { x: root._swipeOffset }

  Rectangle {
    id: bg
    anchors.fill: parent
    color: Colors.bgGlass
    border.color: root.borderColor
    border.width: 1
    radius: Colors.radiusMedium
    clip: true

    // Progress bar at top
    Rectangle {
      width: parent.width * root.progress
      height: 3
      color: root.borderColor
      opacity: 0.8
      anchors.top: parent.top
      anchors.left: parent.left
      radius: Colors.radiusMedium
    }

    Column {
      id: contentCol
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Colors.spacingM
      anchors.topMargin: Colors.paddingMedium
      spacing: Colors.spacingXS

      Row {
        spacing: Colors.paddingSmall
        width: parent.width

        Text {
          text: root.icon
          color: root.borderColor
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeXL
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: root.title
          color: Colors.text
          font.pixelSize: Colors.fontSizeMedium
          font.weight: Font.Bold
          width: parent.width - 32
          elide: Text.ElideRight
        }
      }

      Text {
        text: root.description
        color: Colors.textSecondary
        font.pixelSize: Colors.fontSizeSmall
        width: parent.width
        wrapMode: Text.Wrap
        visible: text !== ""
      }
    }

    // Swipe to dismiss
    MouseArea {
      anchors.fill: parent
      onPressed: (mouse) => {
        root._swipeStartX = mouse.x;
        root._isSwiping = true;
      }
      onPositionChanged: (mouse) => {
        if (root._isSwiping) {
          var delta = mouse.x - root._swipeStartX;
          root._swipeOffset = Math.max(0, delta);
        }
      }
      onReleased: {
        root._isSwiping = false;
        if (root._swipeOffset >= root._dismissThreshold) {
          root.hide();
        } else {
          root._swipeOffset = 0;
        }
      }
    }
  }

  Behavior on _swipeOffset {
    enabled: !root._isSwiping
    NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutCubic }
  }
}
