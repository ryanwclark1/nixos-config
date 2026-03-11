import Quickshell
import QtQuick
import Quickshell.Services.Mpris

pragma Singleton

QtObject {
  id: root

  // ── Exposed state ──────────────────────────────
  property var currentPlayer: null
  property bool isPlaying: false
  property string trackTitle: ""
  property string trackArtist: ""
  property string trackArtUrl: ""
  property real trackLength: 0
  property real currentPosition: 0
  property string positionString: "0:00"
  property string lengthString: "0:00"
  property bool isSeeking: false
  property int selectedPlayerIndex: 0

  // ── Browser dedup + player list ────────────────
  readonly property var _browserIdentities: ["firefox", "chromium", "chrome", "brave"]

  function _isBrowserPlayer(player) {
    if (!player || !player.identity) return false;
    var id = player.identity.toLowerCase();
    for (var i = 0; i < _browserIdentities.length; i++) {
      if (id.indexOf(_browserIdentities[i]) !== -1) return true;
    }
    return false;
  }

  function getAvailablePlayers() {
    var raw = [];
    for (var i = 0; i < Mpris.players.length; i++) {
      var p = Mpris.players[i];
      if (p && p.canPlay) raw.push(p);
    }

    // Separate specific (non-browser) and generic (browser) players
    var specific = [];
    var generic = [];
    for (var j = 0; j < raw.length; j++) {
      if (_isBrowserPlayer(raw[j])) generic.push(raw[j]);
      else specific.push(raw[j]);
    }

    // For each specific player, check if a browser player has the same track
    var mergedGenericIndices = {};
    var result = [];

    for (var s = 0; s < specific.length; s++) {
      var sp = specific[s];
      var title = (sp.trackTitle || "").toLowerCase();
      var merged = false;

      if (title) {
        for (var g = 0; g < generic.length; g++) {
          if (mergedGenericIndices[g]) continue;
          var gt = (generic[g].trackTitle || "").toLowerCase();
          if (gt && (gt.indexOf(title) !== -1 || title.indexOf(gt) !== -1)) {
            // Create virtual merged player — use richer metadata source, route controls to specific
            var richer = (generic[g].trackArtUrl && !sp.trackArtUrl) ? generic[g] : sp;
            result.push({
              identity: sp.identity,
              trackTitle: richer.trackTitle || sp.trackTitle,
              trackArtist: richer.trackArtist || sp.trackArtist,
              trackArtUrl: richer.trackArtUrl || sp.trackArtUrl || "",
              trackAlbum: richer.trackAlbum || sp.trackAlbum || "",
              length: sp.length || generic[g].length || 0,
              position: sp.position || 0,
              playbackState: sp.playbackState,
              volume: sp.volume,
              canPlay: true,
              canPause: sp.canPause,
              canGoNext: sp.canGoNext,
              canGoPrevious: sp.canGoPrevious,
              shuffle: sp.shuffle,
              loopStatus: sp.loopStatus,
              _controlTarget: sp,
              _isVirtual: true
            });
            mergedGenericIndices[g] = true;
            merged = true;
            break;
          }
        }
      }

      if (!merged) result.push(sp);
    }

    // Add unmerged browser players
    for (var ug = 0; ug < generic.length; ug++) {
      if (!mergedGenericIndices[ug]) result.push(generic[ug]);
    }

    return result;
  }

  // ── Player selection ───────────────────────────
  function _findActivePlayer() {
    var players = getAvailablePlayers();
    if (players.length === 0) return null;

    // Prefer currently playing
    for (var i = 0; i < players.length; i++) {
      if (players[i].playbackState === Mpris.Playing) return players[i];
    }

    // Fallback to selected index
    var idx = Math.min(selectedPlayerIndex, players.length - 1);
    return players[Math.max(0, idx)];
  }

  function updateCurrentPlayer() {
    var p = _findActivePlayer();
    currentPlayer = p;
    if (p) {
      isPlaying = p.playbackState === Mpris.Playing;
      trackTitle = p.trackTitle || "";
      trackArtist = p.trackArtist || "";
      trackArtUrl = p.trackArtUrl || "";
      trackLength = p.length || 0;
      lengthString = formatTime(trackLength);
    } else {
      isPlaying = false;
      trackTitle = "";
      trackArtist = "";
      trackArtUrl = "";
      trackLength = 0;
      currentPosition = 0;
      positionString = "0:00";
      lengthString = "0:00";
    }
  }

  // ── Position tracking ──────────────────────────
  property Timer positionTimer: Timer {
    interval: 1000
    running: root.isPlaying && !root.isSeeking && root.trackLength > 0
    repeat: true
    onTriggered: {
      if (root.currentPlayer) {
        var pos = root.currentPlayer._isVirtual
          ? (root.currentPlayer._controlTarget ? root.currentPlayer._controlTarget.position : 0)
          : root.currentPlayer.position;
        root.currentPosition = pos || 0;
        root.positionString = root.formatTime(root.currentPosition);
      }
    }
  }

  // ── Auto-switch monitor ────────────────────────
  property Timer switchMonitor: Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: root.updateCurrentPlayer()
  }

  // ── Formatting ─────────────────────────────────
  function formatTime(seconds) {
    if (!seconds || seconds < 0) return "0:00";
    var s = Math.floor(seconds);
    var h = Math.floor(s / 3600);
    var m = Math.floor((s % 3600) / 60);
    var sec = s % 60;
    if (h > 0) return h + ":" + (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec;
    return m + ":" + (sec < 10 ? "0" : "") + sec;
  }

  // ── Transport controls ─────────────────────────
  function _controlTarget() {
    if (!currentPlayer) return null;
    return currentPlayer._isVirtual ? currentPlayer._controlTarget : currentPlayer;
  }

  function playPause() {
    var t = _controlTarget();
    if (t) t.playPause();
  }

  function next() {
    var t = _controlTarget();
    if (t) t.next();
  }

  function previous() {
    var t = _controlTarget();
    if (t) t.previous();
  }

  function seekByRatio(ratio) {
    var t = _controlTarget();
    if (t && trackLength > 0) {
      isSeeking = true;
      t.position = trackLength * Math.max(0, Math.min(1, ratio));
      currentPosition = t.position;
      positionString = formatTime(currentPosition);
      seekResetTimer.restart();
    }
  }

  property Timer seekResetTimer: Timer {
    interval: 300
    onTriggered: root.isSeeking = false
  }

  function switchToPlayer(index) {
    selectedPlayerIndex = index;
    updateCurrentPlayer();
  }

  // ── Init ───────────────────────────────────────
  Component.onCompleted: updateCurrentPlayer()
}
