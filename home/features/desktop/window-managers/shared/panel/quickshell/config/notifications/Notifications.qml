import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "../services"
import "../widgets" as SharedWidgets

PanelWindow {
  id: root

  readonly property var edgeMargins: Config.notificationMargins(screen)

  anchors {
    top: Config.notifPosition.indexOf("top") !== -1
    bottom: Config.notifPosition.indexOf("bottom") !== -1
    left: Config.notifPosition.indexOf("left") !== -1 || Config.notifPosition === "top" || Config.notifPosition === "bottom"
    right: Config.notifPosition.indexOf("right") !== -1 || Config.notifPosition === "top" || Config.notifPosition === "bottom"
  }
  margins.top: edgeMargins.top
  margins.right: edgeMargins.right
  margins.bottom: edgeMargins.bottom || edgeMargins.top
  margins.left: edgeMargins.left || edgeMargins.right

  implicitWidth: Config.notifWidth
  implicitHeight: col.implicitHeight
  color: "transparent"
  mask: Region {
    item: col
  }

  property var manager: null

  ColumnLayout {
    id: col
    width: Config.notifWidth
    spacing: Colors.paddingSmall

    Repeater {
      model: root.manager ? root.manager.notifications : null

      delegate: Rectangle {
        id: notifDelegate
        property var notification: modelData || null
        visible: notification && !notification.dismissed && (!root.manager || !root.manager.dndEnabled || isUrgent) && !_isMuted
        Layout.preferredWidth: Config.notifWidth
        Layout.preferredHeight: visible ? colMain.implicitHeight + 20 : 0

        // Entrance animation properties
        property real entranceProgress: 0
        x: (1.0 - entranceProgress) * 100 + swipeOffset
        opacity: entranceProgress

        // Staggered entry (capped at 320ms for snappy feel)
        Timer {
          id: staggerTimer
          interval: Math.min(index * 80, 320)
          running: true
          onTriggered: entranceAnim.start()
        }

        NumberAnimation { id: entranceAnim; target: notifDelegate; property: "entranceProgress"; from: 0; to: 1.0; duration: 500; easing.type: Easing.OutBack }

        // Animated dismiss: slide right + fade, then actually dismiss
        property bool isDismissing: false
        layer.enabled: entranceAnim.running || dismissAnim.running
        function animatedDismiss() {
          if (isDismissing || !notification) return;
          isDismissing = true;
          dismissAnim.start();
        }

        ParallelAnimation {
          id: dismissAnim
          NumberAnimation { target: notifDelegate; property: "opacity"; to: 0; duration: Colors.durationNormal; easing.type: Easing.InCubic }
          NumberAnimation { target: notifDelegate; property: "swipeOffset"; to: notifDelegate.width + 20; duration: Colors.durationNormal; easing.type: Easing.OutCubic }
          onFinished: {
            if (notifDelegate.notification) notifDelegate.notification.dismiss();
          }
        }

        // Use Colors singleton
        color: isUrgent ? Colors.withAlpha(Colors.error, 0.8) : Colors.bgGlass
        border.color: isUrgent ? Colors.error : Colors.border
        border.width: isUrgent ? 2 : 1
        radius: Colors.radiusLarge
        clip: true

        // ── Hover tracking ─────────────────────────
        property bool isHovered: false
        HoverHandler {
          onHoveredChanged: notifDelegate.isHovered = hovered
        }

        // ── Dismiss progress bar ───────────────────
        property real dismissProgress: 1.0

        NumberAnimation {
          id: dismissProgressAnim
          target: notifDelegate
          property: "dismissProgress"
          from: 1.0
          to: 0.0
          duration: notifDelegate._urgencyTimeout > 0 ? notifDelegate._urgencyTimeout : Config.popupTimer
          running: dismissTimer.running
          paused: running && notifDelegate.isHovered
        }

        // Progress bar at top
        Rectangle {
          width: parent.width * notifDelegate.dismissProgress
          height: 3
          color: notifDelegate.isUrgent ? Colors.error : Colors.primary
          opacity: 0.7
          anchors.top: parent.top
          anchors.left: parent.left
          z: 1
        }

        // ── Swipe to dismiss ───────────────────────
        property real swipeOffset: 0
        property bool isSwiping: false
        property real _swipeStartX: 0

        Behavior on swipeOffset {
          enabled: !notifDelegate.isSwiping
          NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutCubic }
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor
          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton && notifDelegate.notification) {
              notifDelegate.notification.dismiss();
            }
          }
          onPressed: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
              notifDelegate._swipeStartX = mouse.x;
              notifDelegate.isSwiping = true;
            }
          }
          onPositionChanged: function(mouse) {
            if (notifDelegate.isSwiping) {
              var delta = mouse.x - notifDelegate._swipeStartX;
              notifDelegate.swipeOffset = Math.max(0, delta);
            }
          }
          onReleased: function(mouse) {
            if (notifDelegate.isSwiping) {
              notifDelegate.isSwiping = false;
              var threshold = Math.max(80, notifDelegate.width * 0.35);
              if (notifDelegate.swipeOffset >= threshold) {
                notifDelegate.animatedDismiss();
              } else {
                notifDelegate.swipeOffset = 0;
              }
            }
          }
        }

        property bool isReplying: false
        property bool isUrgent: !!(modelData && modelData.urgency === NotificationUrgency.Critical)
        readonly property string previewImageSource: {
          var source = String((modelData && modelData.image) || "");
          if (source === "")
            return "";
          if (source.startsWith("/") || source.startsWith("file://")
              || source.startsWith("data:") || source.startsWith("image://")
              || source.startsWith("http://") || source.startsWith("https://")) {
            return source;
          }
          return "";
        }

        onIsReplyingChanged: {
          if (isReplying) replyInput.forceActiveFocus();
          else if (replyInput.activeFocus) replyInput.focus = false;
        }

        // Pulse animation for urgent notifications
        SequentialAnimation on border.color {
          running: notifDelegate.isUrgent
          loops: Animation.Infinite
          ColorAnimation { from: Colors.error; to: Qt.lighter(Colors.error, 1.4); duration: 800 }
          ColorAnimation { from: Qt.lighter(Colors.error, 1.4); to: Colors.error; duration: 800 }
        }

        Column {
          id: colMain
          width: parent.width
          spacing: Colors.paddingSmall
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter

          Row {
            width: parent.width - 24
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Colors.spacingM

            SharedWidgets.AppIcon {
              iconName: modelData.appIcon || ""
              appName: modelData.appName || ""
              iconSize: 44
              fallbackIcon: "󰂚"
              visible: (modelData.appIcon || "") !== ""
            }

            Column {
              width: parent.width - 52; spacing: Colors.spacingXS
              Text { text: modelData.appName || "Notification"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Bold; font.capitalization: Font.AllUppercase }
              Text { text: modelData.summary; color: Colors.text; font.pixelSize: Colors.fontSizeLarge; font.weight: Font.Bold; width: parent.width; wrapMode: Text.Wrap }
              Text { text: Config.notifPrivacyMode ? "Notification content hidden" : modelData.body; color: Colors.textSecondary; font.pixelSize: Config.notifCompact ? Colors.fontSizeSmall : Colors.fontSizeMedium; width: parent.width; wrapMode: Text.Wrap; visible: modelData.body !== ""; font.italic: Config.notifPrivacyMode }
            }

            Rectangle {
              width: 32; height: 32; radius: height / 2
              color: "transparent"

              SharedWidgets.StateLayer {
                id: dismissXStateLayer
                hovered: dismissXHover.containsMouse
                pressed: dismissXHover.pressed
              }

              Text {
                anchors.centerIn: parent
                text: "󰅖"
                color: Colors.error
                font.pixelSize: Colors.fontSizeXL
                font.family: Colors.fontMono
              }

              MouseArea {
                id: dismissXHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                  dismissXStateLayer.burst(mouse.x, mouse.y);
                  notifDelegate.animatedDismiss();
                }
              }
            }
          }

          // Large Image Preview
          Rectangle {
            width: parent.width - 24
            height: 180
            anchors.horizontalCenter: parent.horizontalCenter
            visible: notifDelegate.previewImageSource !== ""
            radius: Colors.radiusXS
            clip: true
            color: "transparent"
            border.color: Colors.border
            border.width: 1

            Image {
              anchors.fill: parent
              source: notifDelegate.previewImageSource
              sourceSize: Qt.size(600, 300)
              asynchronous: true
              fillMode: Image.PreserveAspectCrop
            }
          }

          // Reply Input
          Rectangle {
            width: parent.width - 24; height: 40; radius: Colors.radiusXS
            anchors.horizontalCenter: parent.horizontalCenter
            color: Colors.highlightLight
            visible: notifDelegate.isReplying
            border.color: replyInput.activeFocus ? Colors.primary : "transparent"
            border.width: 1
            TextInput {
              id: replyInput
              anchors.fill: parent; anchors.margins: Colors.paddingSmall
              verticalAlignment: Text.AlignVCenter
              color: Colors.text; font.pixelSize: Colors.fontSizeMedium
              onVisibleChanged: if (!visible && activeFocus) focus = false
              Keys.onReturnPressed: { notifDelegate.notification.invoke(replyInput.text); notifDelegate.notification.dismiss(); }
              Keys.onEscapePressed: notifDelegate.isReplying = false
            }
            Text {
              anchors.fill: parent; anchors.leftMargin: Colors.paddingSmall
              verticalAlignment: Text.AlignVCenter
              text: "Type a reply..."; color: Colors.fgDim; font.pixelSize: Colors.fontSizeMedium
              visible: !replyInput.text && !replyInput.activeFocus
            }
          }

          // Actions
          Row {
            width: parent.width - 24; spacing: Colors.spacingS
            anchors.horizontalCenter: parent.horizontalCenter
            visible: notifDelegate.notification && notifDelegate.notification.actions &&
                     notifDelegate.notification.actions.count > 0 && !notifDelegate.isReplying
            Repeater {
              model: notifDelegate.notification ? notifDelegate.notification.actions : null
              delegate: Rectangle {
                width: {
                  var actionCount = notifDelegate.notification && notifDelegate.notification.actions
                    ? notifDelegate.notification.actions.count
                    : 1;
                  return (parent.width - (actionCount - 1) * 8) / actionCount;
                }
                height: 34; radius: Colors.radiusXXS; border.color: Colors.border
                color: Colors.highlightLight

                SharedWidgets.StateLayer {
                  id: actionStateLayer
                  hovered: actionMouse.containsMouse
                  pressed: actionMouse.pressed
                }

                Text { anchors.centerIn: parent; text: modelData && modelData.label ? modelData.label : ""; color: Colors.text; font.pixelSize: Colors.fontSizeMedium }
                MouseArea {
                  id: actionMouse
                  anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                  onClicked: (mouse) => {
                    actionStateLayer.burst(mouse.x, mouse.y);
                    var label = modelData && modelData.label ? modelData.label.toLowerCase() : "";
                    if (label.includes("reply")) { notifDelegate.isReplying = true; replyInput.forceActiveFocus(); }
                    else if (modelData) { modelData.invoke(); notifDelegate.notification.dismiss(); }
                  }
                }
              }
            }
          }

          Rectangle {
            width: parent.width - 24
            height: 36
            anchors.horizontalCenter: parent.horizontalCenter
            radius: Colors.radiusXS
            color: Colors.highlightLight
            visible: !notifDelegate.isReplying

            SharedWidgets.StateLayer {
              id: dismissStateLayer
              hovered: dismissMouse.containsMouse
              pressed: dismissMouse.pressed
            }

            Text {
              anchors.centerIn: parent
              text: "Dismiss"
              color: Colors.error
              font.pixelSize: Colors.fontSizeMedium
              font.weight: Font.DemiBold
            }

            MouseArea {
              id: dismissMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: (mouse) => {
                dismissStateLayer.burst(mouse.x, mouse.y);
                notifDelegate.animatedDismiss();
              }
            }
          }

        }

        // Urgency-aware timeout: use per-urgency config, fallback to popupTimer
        readonly property int _urgencyTimeout: {
          if (!notification) return Config.popupTimer;
          // Check notification rules for app-specific timeout
          var rules = Config.notifRules;
          for (var i = 0; i < rules.length; i++) {
            if (rules[i].appName && (notification.appName || "").toLowerCase() === rules[i].appName.toLowerCase()) {
              if (rules[i].action === "mute") return -1;
              if (rules[i].timeout !== undefined) return rules[i].timeout;
            }
          }
          if (notification.urgency === NotificationUrgency.Critical) return Config.notifTimeoutCritical;
          if (notification.urgency === NotificationUrgency.Low) return Config.notifTimeoutLow;
          return Config.notifTimeoutNormal;
        }
        readonly property bool _isMuted: _urgencyTimeout < 0

        Timer {
          id: dismissTimer
          interval: Math.max(1000, notifDelegate._urgencyTimeout)
          running: notifDelegate.notification && !notifDelegate.isReplying
                   && !notifDelegate.notification.dismissed && notifDelegate._urgencyTimeout > 0
                   && !notifDelegate.isHovered
          onTriggered: notifDelegate.animatedDismiss()
        }
      }
    }
  }
}
