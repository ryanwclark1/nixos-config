pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  readonly property alias items: adapter.items
  property string statePath: Quickshell.statePath("todo.json")

  property int _doneCount: 0
  readonly property int totalCount: items.length
  readonly property int doneCount: _doneCount
  readonly property int pendingCount: totalCount - doneCount

  function _syncDoneCount() {
    var arr = adapter.items;
    var n = 0;
    for (var i = 0; i < arr.length; i++) {
      if (arr[i] && arr[i].done)
        n++;
    }
    root._doneCount = n;
  }

  function addTask(description) {
    var text = (description || "").trim();
    if (!text) return;
    var newItems = adapter.items.slice();
    newItems.push({ content: text, done: false, created: Date.now() });
    adapter.items = newItems;
    root._syncDoneCount();
  }

  function toggleDone(index) {
    if (index < 0 || index >= adapter.items.length) return;
    var newItems = adapter.items.slice();
    newItems[index] = Object.assign({}, newItems[index], { done: !newItems[index].done });
    adapter.items = newItems;
    root._syncDoneCount();
  }

  function deleteItem(index) {
    if (index < 0 || index >= adapter.items.length) return;
    var newItems = adapter.items.slice();
    newItems.splice(index, 1);
    adapter.items = newItems;
    root._syncDoneCount();
  }

  function clearDone() {
    adapter.items = adapter.items.filter(function(i) { return !i.done; });
    root._syncDoneCount();
  }

  readonly property FileView fileView: FileView {
    id: fileView
    path: root.statePath
    blockLoading: true
    printErrors: false
    atomicWrites: true
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: {
      writeAdapter();
      root._syncDoneCount();
    }

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
    root._syncDoneCount();
  }
}
