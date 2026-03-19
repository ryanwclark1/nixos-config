import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import "../../services"

Item {
  id: root

  property bool dndEnabled: false
  readonly property bool notificationServerEnabled: (Quickshell.env("QS_DISABLE_NOTIFICATION_SERVER") || "") !== "1"
  readonly property var server: notificationServerLoader.item
  readonly property var notifications: server ? server.trackedNotifications : null

  // Persistence State
  property var archivedNotifications: []
  property string statePath: Quickshell.statePath("notifications.json")

  // Rate limiting — prevent notification floods from misbehaving apps
  property int _ingressCount: 0
  readonly property int _maxIngressPerSecond: 20

  Timer {
    interval: 1000; running: true; repeat: true
    onTriggered: root._ingressCount = 0
  }

  Timer {
    id: saveDebounce
    interval: 500; repeat: false
    onTriggered: root._doSaveNotifications()
  }

  FileView {
    id: archiveFile
    path: root.statePath
    blockLoading: true
    printErrors: false
    atomicWrites: true
  }

  Loader {
    id: notificationServerLoader
    active: root.notificationServerEnabled
    sourceComponent: notificationServerComponent
  }

  Component {
    id: notificationServerComponent

    NotificationServer {
      actionsSupported: true
      bodySupported: true
      imageSupported: true

      onNotification: function(notif) {
        if (++root._ingressCount > root._maxIngressPerSecond) {
          Logger.w("NotificationManager", "rate limit exceeded, dropping from:", notif.appName);
          return;
        }
        notif.tracked = true;
        root.saveNotifications();
      }
    }
  }

  Component.onCompleted: loadNotifications()

  function saveNotifications() {
    saveDebounce.restart();
  }

  function _doSaveNotifications() {
    var data = [];
    if (!server) {
      return;
    }
    // Combine current tracked + archive (avoiding duplicates)
    for (var i = 0; i < server.trackedNotifications.count; i++) {
      var n = server.trackedNotifications.get(i);
      data.push({
        appName: n.appName,
        summary: n.summary,
        body: n.body,
        appIcon: n.appIcon,
        image: n.image,
        timestamp: Date.now()
      });
    }

    // Add existing archived ones (limit to 50 total for performance)
    for (var j = 0; j < Math.min(archivedNotifications.length, 50 - data.length); j++) {
       data.push(archivedNotifications[j]);
    }

    archiveFile.setText(JSON.stringify(data));
  }

  function loadNotifications() {
    var raw = (archiveFile.text() || "").trim();
    if (!raw) return;
    try {
      archivedNotifications = JSON.parse(raw);
    } catch (e) {
      Logger.e("NotificationManager", "Failed to load notifications:", e);
    }
  }

  function dismissAll(appName) {
    if (!server || !server.trackedNotifications) return;
    for (var i = server.trackedNotifications.count - 1; i >= 0; i--) {
      var n = server.trackedNotifications.get(i);
      if (n && (!appName || n.appName === appName)) {
        n.dismiss();
      }
    }
  }

  function clearArchive() {
     archivedNotifications = [];
     archiveFile.setText("[]");
  }
}
