import QtQuick
import "../modules"
import "../services"

Row {
  visible: CompositorAdapter.supportsDispatcherActions
  spacing: 6

  ActionButton {
    label: "Float"
    command: [ "hyprctl", "dispatch", "togglefloating" ]
  }

  ActionButton {
    label: "Pseudo"
    command: [ "hyprctl", "dispatch", "pseudo" ]
  }

  ActionButton {
    label: "Full"
    command: [ "hyprctl", "dispatch", "fullscreen", "toggle" ]
  }
}
