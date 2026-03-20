import QtQuick
import "."
import "../services"

Item {
  id: root
  implicitWidth: 340
  implicitHeight: contentCol.implicitHeight + Appearance.paddingLarge
  width: implicitWidth
  height: implicitHeight
  visible: false

  property string title: ""
  property string description: ""
  property string icon: "info.svg"
  property string type: "notice"
  property int duration: Appearance.durationToast
  property real progress: 1.0
  property string actionLabel: ""
  property string actionToken: ""

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
  function show(t, d, i, ty, dur, actionText, actionId) {
    if (actionToken && actionToken !== (actionId || ""))
      ToastService.clearAction(actionToken);
    title = t || "";
    description = d || "";
    icon = i || "󰋼";
    type = ty || "notice";
    duration = dur || 3000;
    actionLabel = actionText || "";
    actionToken = actionId || "";
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
    NumberAnimation { target: root; property: "opacity"; to: 0; duration: Appearance.durationNormal; easing.type: Easing.InCubic }
    NumberAnimation { target: root; property: "scale"; to: 0.9; duration: Appearance.durationNormal; easing.type: Easing.InCubic }
    onFinished: {
      root.visible = false;
      if (root.actionToken) {
        ToastService.clearAction(root.actionToken);
        root.actionToken = "";
      }
      root.actionLabel = "";
      root.hidden();
    }
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
    color: Colors.cardSurface
    border.color: root.borderColor
    border.width: 1
    radius: Appearance.radiusMedium
    clip: true

    gradient: Gradient {
      orientation: Gradient.Vertical
      GradientStop { position: 0.0; color: type === "error" ? Colors.withAlpha(Colors.error, 0.1) : Colors.surfaceGradientStart }
      GradientStop { position: 1.0; color: type === "error" ? Colors.withAlpha(Colors.error, 0.02) : Colors.surfaceGradientEnd }
    }

    // Inner highlight
    InnerHighlight { highlightOpacity: 0.15 }

    // Progress bar at bottom
    Rectangle {
      width: parent.width * root.progress
      height: 3
      color: root.borderColor
      opacity: 0.6
      anchors.bottom: parent.bottom
      anchors.left: parent.left
    }

    Column {
      id: contentCol
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Appearance.spacingM
      anchors.topMargin: Appearance.paddingMedium
      spacing: Appearance.spacingXS

      Row {
        spacing: Appearance.paddingSmall
        width: parent.width

        Text {
          text: root.icon
          color: root.borderColor
          font.family: Appearance.fontMono
          font.pixelSize: Appearance.fontSizeXL
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: root.title
          color: Colors.text
          font.pixelSize: Appearance.fontSizeMedium
          font.weight: Font.Bold
          width: parent.width - 32
          elide: Text.ElideRight
        }
      }

      Text {
        text: root.description
        color: Colors.textSecondary
        font.pixelSize: Appearance.fontSizeSmall
        width: parent.width
        wrapMode: Text.Wrap
        visible: text !== ""
      }

      Rectangle {
        visible: root.actionLabel !== ""
        width: actionRow.implicitWidth + Appearance.spacingM
        height: 28
        radius: Appearance.radiusSmall
        color: actionMouse.containsMouse ? Colors.primaryGhost : Colors.primarySubtle
        border.color: Colors.withAlpha(Colors.primary, 0.25)
        border.width: 1

        Row {
          id: actionRow
          anchors.centerIn: parent
          spacing: Appearance.spacingXS

          SvgIcon {
            source: "dismiss.svg"
            color: Colors.primary
            size: Appearance.fontSizeSmall
          }

          Text {
            text: root.actionLabel
            color: Colors.primary
            font.pixelSize: Appearance.fontSizeSmall
            font.weight: Font.DemiBold
          }
        }

        MouseArea {
          id: actionMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            ToastService.triggerAction(root.actionToken);
            root.hide();
          }
        }
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
    Anim {}
  }
}
