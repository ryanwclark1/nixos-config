import QtQuick
import Quickshell.Services.Pipewire

Row {
  spacing: 6
  anchors.verticalCenter: parent.verticalCenter

  property var sink: Pipewire.defaultAudioSink

  Text {
    // Basic fallback icons if properties are complex
    text: "󰕾" 
    color: "#e6e6e6"
    font.pixelSize: 16
    font.family: "JetBrainsMono Nerd Font"
    anchors.verticalCenter: parent.verticalCenter
  }

  Text {
    // Currently Pipewire object doesn't expose easy simple volume without extra bindings,
    // so we show a static or placeholder text until bound to script
    text: "Vol"
    color: "#e6e6e6"
    font.pixelSize: 12
    anchors.verticalCenter: parent.verticalCenter
  }
}
