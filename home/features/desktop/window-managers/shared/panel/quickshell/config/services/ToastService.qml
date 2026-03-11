import Quickshell
import QtQuick

pragma Singleton

QtObject {
  id: root

  signal notify(string title, string description, string icon, string type, int duration)

  function showNotice(title, desc) {
    notify(title, desc || "", "󰋼", "notice", 3000);
  }

  function showError(title, desc) {
    notify(title, desc || "", "󰅚", "error", 5000);
  }

  function showSuccess(title, desc) {
    notify(title, desc || "", "󰄬", "success", 3000);
  }
}
