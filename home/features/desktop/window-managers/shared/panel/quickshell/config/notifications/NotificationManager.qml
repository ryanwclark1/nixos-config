import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io

Item {
  id: root
  
  property bool dndEnabled: false
  readonly property alias server: server
  readonly property alias notifications: server.trackedNotifications
  
  // Persistence State
  property var archivedNotifications: []
  property string statePath: Quickshell.statePath("notifications.json")

  NotificationServer {
    id: server
    actionsSupported: true
    bodySupported: true
    imageSupported: true
    
    onNotification: function(notif) {
      notif.tracked = true;
      saveNotifications(); 
    }
  }

  Component.onCompleted: loadNotifications()

  function saveNotifications() {
    var data = [];
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
    
    var json = JSON.stringify(data);
    Quickshell.execDetached([
      "sh",
      "-c",
      "printf %s \"$1\" > \"$2\"",
      "sh",
      json,
      root.statePath
    ]);
  }

  function loadNotifications() {
    if (!readArchive.running) readArchive.running = true;
  }
  
  function clearArchive() {
     archivedNotifications = [];
     Quickshell.execDetached([
       "sh",
       "-c",
       "printf %s \"$1\" > \"$2\"",
       "sh",
       "[]",
       root.statePath
     ]);
  }

  Process {
    id: readArchive
    command: ["sh", "-c", "cat \"$1\" 2>/dev/null || true", "sh", root.statePath]
    stdout: StdioCollector {
      onStreamFinished: {
        var raw = (this.text || "").trim();
        if (!raw) return;
        try {
          archivedNotifications = JSON.parse(raw);
        } catch (e) {
          console.error("Failed to load notifications: " + e);
        }
      }
    }
  }
}
