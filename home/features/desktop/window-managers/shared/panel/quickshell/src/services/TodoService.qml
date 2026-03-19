pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  readonly property alias items: adapter.items
  property string statePath: Quickshell.statePath("todo.json")

  readonly property int totalCount: items.length
  readonly property int doneCount: items.filter(function(i) { return i.done; }).length
  readonly property int pendingCount: totalCount - doneCount

  function addTask(description) {
    var text = (description || "").trim();
    if (!text) return;
    var newItems = adapter.items.slice();
    newItems.push({ content: text, done: false, created: Date.now() });
    adapter.items = newItems;
  }

  function toggleDone(index) {
    if (index < 0 || index >= adapter.items.length) return;
    var newItems = adapter.items.slice();
    newItems[index] = Object.assign({}, newItems[index], { done: !newItems[index].done });
    adapter.items = newItems;
  }

  function deleteItem(index) {
    if (index < 0 || index >= adapter.items.length) return;
    var newItems = adapter.items.slice();
    newItems.splice(index, 1);
    adapter.items = newItems;
  }

  function clearDone() {
    adapter.items = adapter.items.filter(function(i) { return !i.done; });
  }

  readonly property FileView fileView: FileView {
    id: fileView
    path: root.statePath
    blockLoading: true
    printErrors: false
    atomicWrites: true
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()

    adapter: JsonAdapter {
      id: adapter
      property var items: []
    }
  }

  // Migrate from old bare-array format [...] to new {items: [...]} on first load
  Component.onCompleted: {
    var raw = (fileView.text() || "").trim();
    if (raw.startsWith("[")) {
      try {
        adapter.items = JSON.parse(raw);
      } catch (e) {
        Logger.e("TodoService", "migration failed:", e);
      }
    }
  }
}
