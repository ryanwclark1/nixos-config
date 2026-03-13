import QtQuick
import "../modules"
import "../services"

Row {
  visible: CompositorAdapter.supportsDispatcherActions
  spacing: 6

  ActionButton {
    label: "Float"
    action: function() { CompositorAdapter.dispatchAction("togglefloating", "", "Toggle floating"); }
  }

  ActionButton {
    label: "Pseudo"
    action: function() { CompositorAdapter.dispatchAction("pseudo", "", "Toggle pseudo mode"); }
  }

  ActionButton {
    label: "Full"
    action: function() { CompositorAdapter.dispatchAction("fullscreen", "toggle", "Toggle fullscreen"); }
  }
}
