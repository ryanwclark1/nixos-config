pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property var items: []
  property string statePath: Quickshell.statePath("todo.json")

  readonly property int totalCount: items.length
  readonly property int doneCount: items.filter(function(i) { return i.done; }).length
  readonly property int pendingCount: totalCount - doneCount

  function addTask(description) {
    var text = (description || "").trim();
    if (!text) return;
    var newItems = items.slice();
    newItems.push({ content: text, done: false, created: Date.now() });
    items = newItems;
    _save();
  }

  function toggleDone(index) {
    if (index < 0 || index >= items.length) return;
    var newItems = items.slice();
    newItems[index] = Object.assign({}, newItems[index], { done: !newItems[index].done });
    items = newItems;
    _save();
  }

  function deleteItem(index) {
    if (index < 0 || index >= items.length) return;
    var newItems = items.slice();
    newItems.splice(index, 1);
    items = newItems;
    _save();
  }

  function clearDone() {
    items = items.filter(function(i) { return !i.done; });
    _save();
  }

  function _save() {
    var json = JSON.stringify(items);
    Quickshell.execDetached([
      "sh", "-c", "printf %s \"$1\" > \"$2\"",
      "sh", json, root.statePath
    ]);
  }

  function _load() {
    _readProc.running = true;
  }

  Component.onCompleted: _load()

  property Process _readProc: Process {
    command: ["sh", "-c", "cat \"$1\" 2>/dev/null || echo '[]'", "sh", root.statePath]
    stdout: StdioCollector {
      onStreamFinished: {
        var raw = (this.text || "").trim();
        if (!raw) return;
        try {
          root.items = JSON.parse(raw);
        } catch (e) {
          Logger.e("TodoService", "failed to load:", e);
          root.items = [];
        }
      }
    }
  }
}
