import QtQuick
import "../modules"

Row {
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
