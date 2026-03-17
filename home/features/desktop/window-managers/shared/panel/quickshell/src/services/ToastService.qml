pragma Singleton

import QtQuick
import Quickshell

QtObject {
  id: root

  // ── Named constants ────────────────────────────
  readonly property int _noticeDurationMs: 3000
  readonly property int _errorDurationMs: 5000
  readonly property int _successDurationMs: 3000

  signal notify(string title, string description, string icon, string type, int duration)

  function showNotice(title, desc) {
    notify(title, desc || "", "󰋼", "notice", _noticeDurationMs);
  }

  function showError(title, desc) {
    notify(title, desc || "", "󰅚", "error", _errorDurationMs);
  }

  function showSuccess(title, desc) {
    notify(title, desc || "", "󰄬", "success", _successDurationMs);
  }
}
