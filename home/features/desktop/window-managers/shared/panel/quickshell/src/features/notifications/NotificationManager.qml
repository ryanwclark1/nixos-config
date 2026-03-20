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

  // Screenshot notification tracking — keyed by body text, value = { path, ts }
  property var _pendingScreenshotPaths: ({})

  // Rate limiting — prevent notification floods from misbehaving apps
  property int _ingressCount: 0
  readonly property int _maxIngressPerSecond: 20

  Timer {
    interval: 1000; running: true; repeat: true
    onTriggered: root._ingressCount = 0
  }

  // Prune stale pending screenshot entries that were never matched
  Timer {
    interval: 30000; running: true; repeat: true
    onTriggered: root._pruneStaleScreenshotPaths()
  }

  Timer {
    id: saveDebounce
    interval: 500; repeat: false
    onTriggered: root._doSave()
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
        notif._receivedAt = new Date();

        // Detect screenshot notifications — match by full body text key
        var bodyKey = (notif.body || "").trim();
        var pending = root._pendingScreenshotPaths[bodyKey];
        if (pending) {
          notif.screenshotPath = pending.path;
          var next = Object.assign({}, root._pendingScreenshotPaths);
          delete next[bodyKey];
          root._pendingScreenshotPaths = next;
        }

        // TTS: skip screenshot notifications (reading file paths is not useful)
        if (!notif.screenshotPath)
          root._maybeSpeakNotification(notif);

        root._scheduleSave();
      }
    }
  }

  Connections {
    target: ScreenshotService
    function onScreenshotNotificationRequested(filePath) {
      root._sendScreenshotNotification(filePath);
    }
  }

  Component.onCompleted: _loadArchive()

  // ── Public API ───────────────────────────────

  // Archive a notification's data then dismiss it from tracked list
  function dismissNotification(notification) {
    if (!notification) return;
    _archiveNotification(notification);
    notification.dismiss();
    _scheduleSave();
  }

  // Dismiss all tracked notifications (optionally filtered by app name)
  function dismissAll(appName) {
    if (!server || !server.trackedNotifications) return;
    // Archive all before dismissing
    for (var i = server.trackedNotifications.count - 1; i >= 0; i--) {
      var n = server.trackedNotifications.get(i);
      if (n && (!appName || n.appName === appName)) {
        _archiveNotification(n);
        n.dismiss();
      }
    }
    _scheduleSave();
  }

  function clearArchive() {
    archivedNotifications = [];
    archiveFile.setText("[]");
  }

  // ── Internal ─────────────────────────────────

  function _archiveNotification(n) {
    if (!n) return;
    var entry = {
      appName: n.appName || "",
      summary: n.summary || "",
      body: n.body || "",
      appIcon: n.appIcon || "",
      image: n.image || "",
      timestamp: Date.now()
    };
    // Prepend to archive (newest first), limit to 100 entries
    var next = [entry];
    for (var i = 0; i < Math.min(archivedNotifications.length, 99); i++)
      next.push(archivedNotifications[i]);
    archivedNotifications = next;
  }

  function _scheduleSave() {
    saveDebounce.restart();
  }

  function _doSave() {
    // Save just the archive — tracked notifications are live D-Bus objects
    // that don't survive restarts; the archive is our persistent history
    archiveFile.setText(JSON.stringify(archivedNotifications));
  }

  function _loadArchive() {
    var raw = (archiveFile.text() || "").trim();
    if (!raw) return;
    try {
      var parsed = JSON.parse(raw);
      // Prune entries older than 7 days
      var now = Date.now();
      var cutoff = now - (7 * 86400000);
      var pruned = [];
      for (var i = 0; i < parsed.length; i++) {
        if ((parsed[i].timestamp || 0) > cutoff)
          pruned.push(parsed[i]);
      }
      archivedNotifications = pruned;
    } catch (e) {
      Logger.e("NotificationManager", "Failed to load notification archive:", e);
    }
  }

  // ── TTS Read-Aloud ─────────────────────────

  readonly property bool ttsSpeaking: _ttsProc.running

  property Process _ttsProc: Process {
    running: false
    onExited: {} // no-op, running becomes false automatically
  }

  function stopSpeaking() {
    _ttsProc.running = false;
  }

  function _maybeSpeakNotification(notif) {
    if (!Config.notifTtsEnabled || root.dndEnabled) return;
    var appName = (notif.appName || "").toLowerCase();
    var excluded = Config.notifTtsExcludedApps || [];
    for (var i = 0; i < excluded.length; i++) {
      if (appName === String(excluded[i]).toLowerCase()) return;
    }
    var text = (notif.summary || "");
    if (notif.body) text += ". " + notif.body;
    text = text.replace(/<[^>]*>/g, "").trim();
    if (!text) return;
    if (text.length > 300) text = text.substring(0, 300);
    // Kill previous speech, then start new
    _ttsProc.running = false;
    _ttsProc.command = [
      "qs-tts-speak",
      "--rate=" + Config.notifTtsRate,
      "--volume=" + Config.notifTtsVolume,
      "--engine=" + Config.notifTtsEngine,
      text
    ];
    _ttsProc.running = true;
  }

  // ── Screenshot Notification ────────────────

  function _sendScreenshotNotification(filePath) {
    var body = "Saved to " + filePath + " and copied to clipboard";
    Quickshell.execDetached([
      "notify-send", "-i", "camera-photo",
      "-a", "Screenshot",
      "-h", "string:image-path:" + filePath,
      "Screenshot captured",
      body
    ]);
    // Key by the exact body text so onNotification can match without parsing
    var next = Object.assign({}, _pendingScreenshotPaths);
    next[body] = { path: filePath, ts: Date.now() };
    _pendingScreenshotPaths = next;
  }

  function _pruneStaleScreenshotPaths() {
    var cutoff = Date.now() - 30000;
    var changed = false;
    var next = {};
    var keys = Object.keys(root._pendingScreenshotPaths);
    for (var i = 0; i < keys.length; i++) {
      var entry = root._pendingScreenshotPaths[keys[i]];
      if (entry.ts > cutoff) {
        next[keys[i]] = entry;
      } else {
        changed = true;
      }
    }
    if (changed)
      root._pendingScreenshotPaths = next;
  }
}
