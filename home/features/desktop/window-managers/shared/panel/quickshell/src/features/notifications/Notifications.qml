import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../../services"

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
  margins.right: Math.max(edgeMargins.right, Colors.spacingS)
  margins.bottom: edgeMargins.bottom || edgeMargins.top
  margins.left: Math.max(edgeMargins.left || edgeMargins.right, Colors.spacingS)

  implicitWidth: Config.notifWidth
  implicitHeight: Math.max(1, col.implicitHeight)
  color: "transparent"
  mask: Region {
    item: col
  }

  property var manager: null
  readonly property int maxLayerTextureSize: 4096

  function allowLayer(width, height) {
    return width > 0 && height > 0
      && width <= maxLayerTextureSize
      && height <= maxLayerTextureSize;
  }

  ColumnLayout {
    id: col
    width: Config.notifWidth
    spacing: Colors.paddingSmall

    Repeater {
      model: root.manager ? root.manager.notifications : null

      delegate: Item {
        id: notifWrapper
        property var notification: modelData || null
        visible: notification && !notification.dismissed && (!root.manager || !root.manager.dndEnabled || isUrgent) && !_isMuted
        Layout.preferredWidth: Config.notifWidth
        Layout.preferredHeight: visible ? delegate.height : 0

        readonly property bool isUrgent: !!(notification && notification.urgency === NotificationUrgency.Critical)
        readonly property int _urgencyTimeout: {
          if (!notification) return Config.popupTimer;
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

        // Entrance/Exit Animation Logic
        property real entranceProgress: 0
        property real exitProgress: 1.0
        property bool isDismissing: false

        opacity: entranceProgress * exitProgress
        scale: 0.95 + (0.05 * entranceProgress)
        x: (1.0 - entranceProgress) * 40 + delegate.swipeOffset

        layer.enabled: (entranceAnim.running || dismissAnim.running) && root.allowLayer(width, height)

        Component.onCompleted: {
          entranceTimer.interval = Math.min(index * 60, 240);
          entranceTimer.start();
        }

        Timer { id: entranceTimer; onTriggered: entranceAnim.start() }
        NumberAnimation { id: entranceAnim; target: notifWrapper; property: "entranceProgress"; to: 1.0; duration: Colors.durationEmphasis; easing.type: Easing.OutQuint }

        function animatedDismiss() {
          if (isDismissing) return;
          isDismissing = true;
          dismissTimer.stop();
          dismissTimer.dismissProgress = 0;
          dismissAnim.start();
        }

        function canAutoDismiss() {
          return !!notifWrapper.notification
            && !delegate.isReplying
            && !notifWrapper.isDismissing
            && notifWrapper._urgencyTimeout > 0
            && !delegate.isHovered;
        }

        ParallelAnimation {
          id: dismissAnim
          NumberAnimation { target: notifWrapper; property: "exitProgress"; to: 0; duration: Colors.durationPanelOpen; easing.type: Easing.InCubic }
          NumberAnimation { target: notifWrapper; property: "x"; to: notifWrapper.width + 40; duration: Colors.durationPanelOpen; easing.type: Easing.InCubic }
          onFinished: if (notification) notification.dismiss()
        }

        NotificationDelegate {
          id: delegate
          notification: notifWrapper.notification
          isPopup: true
          showContent: !notifWrapper.isDismissing
          onDismissRequested: notifWrapper.animatedDismiss()
          onActionInvoked: function(action) {
            action.invoke();
            notifWrapper.animatedDismiss();
          }
          onReplySent: function(text) {
            if (notifWrapper.notification)
              notifWrapper.notification.invoke(text);
            notifWrapper.animatedDismiss();
          }

          // Progress bar for auto-dismiss
          Rectangle {
            id: progress
            anchors.top: parent.top
            anchors.left: parent.left
            height: 3
            radius: Colors.radiusXS
            color: notifWrapper.isUrgent ? Colors.error : Colors.primary
            opacity: 0.6
            width: parent.width * (1.0 - dismissTimer.dismissProgress)
            visible: !notifWrapper.isDismissing && notifWrapper._urgencyTimeout > 0
          }
        }

        Timer {
          id: dismissTimer
          property real dismissProgress: 0
          interval: 50
          repeat: true
          running: notifWrapper.canAutoDismiss()
          onRunningChanged: {
            if (!running && !notifWrapper.isDismissing)
              dismissProgress = 0;
          }
          onTriggered: {
            dismissProgress += 50 / notifWrapper._urgencyTimeout;
            if (dismissProgress >= 1.0) {
              stop();
              notifWrapper.animatedDismiss();
            }
          }
        }
      }
    }
  }
}
