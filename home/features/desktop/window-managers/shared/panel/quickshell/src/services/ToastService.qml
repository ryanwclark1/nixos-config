pragma Singleton

import QtQuick
import Quickshell

QtObject {
  id: root

  // ── Named constants ────────────────────────────
  readonly property int _noticeDurationMs: 3000
  readonly property int _errorDurationMs: 5000
  readonly property int _successDurationMs: 3000
  property int _nextActionToken: 1
  property var _actionHandlers: ({})

  signal notify(string title, string description, string icon, string type, int duration, string actionLabel, string actionToken)

  function _registerAction(actionFn) {
    if (typeof actionFn !== "function")
      return "";
    var token = "toast-action-" + _nextActionToken++;
    var handlers = Object.assign({}, _actionHandlers);
    handlers[token] = actionFn;
    _actionHandlers = handlers;
    return token;
  }

  function clearAction(token) {
    if (!token || !_actionHandlers[token])
      return;
    var handlers = Object.assign({}, _actionHandlers);
    delete handlers[token];
    _actionHandlers = handlers;
  }

  function triggerAction(token) {
    if (!token || !_actionHandlers[token])
      return;
    var fn = _actionHandlers[token];
    clearAction(token);
    fn();
  }

  function showNotice(title, desc) {
    notify(title, desc || "", "󰋼", "notice", _noticeDurationMs, "", "");
  }

  function showNoticeAction(title, desc, actionLabel, actionFn) {
    var token = _registerAction(actionFn);
    notify(title, desc || "", "󰋼", "notice", _noticeDurationMs, actionLabel || "", token);
  }

  function showError(title, desc) {
    notify(title, desc || "", "󰅚", "error", _errorDurationMs, "", "");
  }

  function showSuccess(title, desc) {
    notify(title, desc || "", "󰄬", "success", _successDurationMs, "", "");
  }
}
