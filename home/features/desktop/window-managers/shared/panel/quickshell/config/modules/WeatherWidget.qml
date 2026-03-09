import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "."
import "../services"

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: 80
  color: Colors.bgWidget || "#0dffffff"
  radius: Colors.radiusMedium || 12
  border.color: Colors.border || "#33ffffff"
  clip: true

  property string weatherText: "Loading weather..."
  property string temp: "--"
  property string location: "Local"

  Process {
    id: fetchWeather
    command: ["sh", "-c", "curl -s 'wttr.in?format=%l:%t:%C' || echo 'Unknown:--:Error'"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = this.text.trim().split(":");
        if (parts.length >= 3) {
          root.location = parts[0];
          root.temp = parts[1];
          root.weatherText = parts[2];
        }
      }
    }
  }

  // Refresh every 30 mins
  Timer {
    interval: 1800000
    running: true
    repeat: true
    onTriggered: fetchWeather.running = true
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: 15
    spacing: 15

    // Weather Icon Placeholder (could map condition to icons)
    Text {
      text: {
        var w = root.weatherText.toLowerCase();
        if (w.includes("sun") || w.includes("clear")) return "󰖙";
        if (w.includes("cloud")) return "󰖐";
        if (w.includes("rain")) return "󰖗";
        if (w.includes("snow")) return "󰖘";
        if (w.includes("storm")) return "󰖓";
        return "󰖐";
      }
      color: Colors.accent || "#ffffff"
      font.family: Colors.fontMono || "JetBrainsMono Nerd Font"
      font.pixelSize: 32
    }

    ColumnLayout {
      spacing: 2
      Text {
        text: root.temp
        color: Colors.fgMain || "#ffffff"
        font.pixelSize: 18
        font.weight: Font.Bold
      }
      Text {
        text: (root.weatherText || "Unknown") + " in " + (root.location || "Local")
        color: Colors.fgDim || "#cccccc"
        font.pixelSize: 11
        elide: Text.ElideRight
        Layout.fillWidth: true
      }
    }
  }
}
