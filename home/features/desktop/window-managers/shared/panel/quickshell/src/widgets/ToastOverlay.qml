import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
  id: root
  required property ShellScreen screenModel
  screen: screenModel
  readonly property var edgeMargins: Config.reservedEdgesForScreen(screenModel, "")

  anchors {
    top: true
    left: true
    right: true
  }

  margins.top: edgeMargins.top
  margins.left: edgeMargins.left
  margins.right: edgeMargins.right
  implicitHeight: toastLoader.item ? toastLoader.item.implicitHeight + 16 : 80
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  WlrLayershell.namespace: "quickshell-toast"
  exclusiveZone: 0

  mask: Region { item: toastContainer }

  // ── Queue ──────────────────────────────────────
  property var _messageQueue: []
  property bool _showing: false

  Connections {
    target: ToastService
    function onNotify(title, description, icon, type, duration) {
      root._enqueue(title, description, icon, type, duration);
    }
  }

  function _enqueue(title, description, icon, type, duration) {
    // Replace current toast if showing
    if (_showing && toastLoader.item) {
      toastLoader.item.show(title, description, icon, type, duration);
      return;
    }

    if (_showing) {
      _messageQueue.push({ title: title, description: description, icon: icon, type: type, duration: duration });
      return;
    }

    _showToast(title, description, icon, type, duration);
  }

  function _showToast(title, description, icon, type, duration) {
    _showing = true;
    toastLoader.active = true;
    if (toastLoader.item) {
      toastLoader.item.show(title, description, icon, type, duration);
    }
  }

  function _onToastHidden() {
    toastLoader.active = false;
    _showing = false;

    if (_messageQueue.length > 0) {
      var next = _messageQueue.shift();
      _showToast(next.title, next.description, next.icon, next.type, next.duration);
    }
  }

  // ── Visual ─────────────────────────────────────
  Item {
    id: toastContainer
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    width: toastLoader.item ? toastLoader.item.width : 0
    height: toastLoader.item ? toastLoader.item.height : 0

    Loader {
      id: toastLoader
      active: false
      sourceComponent: Toast {
        onHidden: root._onToastHidden()
      }
    }
  }
}
