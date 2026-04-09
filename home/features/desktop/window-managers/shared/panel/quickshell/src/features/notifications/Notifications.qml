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
  margins.right: Math.max(edgeMargins.right, Appearance.spacingS)
  margins.bottom: edgeMargins.bottom || edgeMargins.top
  margins.left: Math.max(edgeMargins.left || edgeMargins.right, Appearance.spacingS)

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
    spacing: Appearance.paddingSmall

    Repeater {
      model: root.manager ? root.manager.notifications : null

      delegate: Item {
        id: notifWrapper
        property var notification: modelData || null
        // Local flag: true after popup timeout expires (hides popup, keeps in center)
        property bool _expired: false
        visible: !!notification && !notification.dismissed && !_expired && (!root.manager || !root.manager.dndEnabled || isUrgent) && !_isMuted
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
          // Screenshot notifications get extra time for click-to-edit
          if (notification.screenshotPath)
            return Math.max(Config.notifTimeoutNormal, 8000);
          if (notification.urgency === NotificationUrgency.Critical) return Config.notifTimeoutCritical;
          if (notification.urgency === NotificationUrgency.Low) return Config.notifTimeoutLow;
          return Config.notifTimeoutNormal;
        }
        readonly property bool _isMuted: _urgencyTimeout < 0

        // Entrance/Exit Animation Logic
        property real entranceProgress: 0
        property real exitProgress: 1.0
        property bool isDismissing: false
        // true when the popup expires by timeout (should NOT dismiss from center)
        // false when user explicitly dismisses (click X, swipe, right-click)
        property bool _isAutoExpiry: false

        opacity: entranceProgress * exitProgress
        scale: 0.95 + (0.05 * entranceProgress)
        x: (1.0 - entranceProgress) * 40 + delegate.swipeOffset

        layer.enabled: (entranceAnim.running || dismissAnim.running) && root.allowLayer(width, height)

        Component.onCompleted: {
          entranceTimer.interval = Math.min(index * 60, 240);
          entranceTimer.start();
        }

        Timer { id: entranceTimer; onTriggered: entranceAnim.start() }
        NumberAnimation { id: entranceAnim; target: notifWrapper; property: "entranceProgress"; to: 1.0; duration: Appearance.durationEmphasis; easing.type: Easing.OutQuint }

        // User-initiated dismiss: removes from both popup and notification center
        function animatedDismiss() {
          if (isDismissing) return;
          _isAutoExpiry = false;
          isDismissing = true;
          dismissTimer.stop();
          dismissTimer.dismissProgress = 0;
          dismissAnim.start();
        }

        // Auto-expiry: hides popup but keeps notification in center
        function autoExpirePopup() {
          if (isDismissing) return;
          _isAutoExpiry = true;
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
          NumberAnimation { target: notifWrapper; property: "exitProgress"; to: 0; duration: Appearance.durationPanelOpen; easing.type: Easing.InCubic }
          NumberAnimation { target: notifWrapper; property: "x"; to: notifWrapper.width + 40; duration: Appearance.durationPanelOpen; easing.type: Easing.InCubic }
          onFinished: {
            if (!notification) return;
            if (notifWrapper._isAutoExpiry) {
              notification.expire();
            } else {
              if (root.manager)
                root.manager.dismissNotification(notification);
              else
                notification.dismiss();
            }
          }
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
              notifWrapper.notification.sendInlineReply(text);
            notifWrapper.animatedDismiss();
          }

          // Progress bar for auto-dismiss
          Rectangle {
            id: progress
            anchors.top: parent.top
            anchors.left: parent.left
            height: 3
            radius: Appearance.radiusXS
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
              notifWrapper.autoExpirePopup();
            }
          }
        }
      }
    }
  }
}
