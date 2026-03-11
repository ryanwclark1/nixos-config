import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services"
import "../widgets" as SharedWidgets

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: 100
  color: Colors.bgWidget
  radius: Colors.radiusMedium
  border.color: Colors.border
  clip: true

  property string nixUpdates: "0"
  property string flatpakUpdates: "0"
  property bool isChecking: false

  readonly property string cacheDir: Quickshell.env("XDG_CACHE_HOME") !== ""
    ? Quickshell.env("XDG_CACHE_HOME") + "/quickshell/updates"
    : Quickshell.env("HOME") + "/.cache/quickshell/updates"

  SharedWidgets.CommandPoll {
    id: cachePoll
    interval: 3600000
    running: true
    command: ["sh", "-c",
      "nix=$(cat '" + root.cacheDir + "/nixos' 2>/dev/null || echo 0); "
      + "fpk=$(cat '" + root.cacheDir + "/flatpak' 2>/dev/null || echo 0); "
      + "printf '%s\\n%s\\n' \"$nix\" \"$fpk\""
    ]
    parse: function(out) {
      var lines = (out || "").trim().split("\n");
      return { nix: (lines[0] || "0").trim(), flatpak: (lines.length >= 2 ? lines[1] : "0").trim() };
    }
    onUpdated: {
      root.nixUpdates = cachePoll.value.nix;
      root.flatpakUpdates = cachePoll.value.flatpak;
      root.isChecking = false;
    }
  }

  Process {
    id: refreshProc
    command: ["qs-updator"]
    stdout: StdioCollector {
      onStreamFinished: cachePoll.poll()
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if ((this.text || "").trim().length > 0)
          console.warn("UpdateWidget: qs-updator error:", this.text.trim());
        root.isChecking = false;
      }
    }
  }

  function checkUpdates() {
    isChecking = true;
    refreshProc.running = true;
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: Colors.paddingMedium
    spacing: 15

    Rectangle {
      width: 50; height: 50; radius: 25; color: Colors.secondary
      Text { anchors.centerIn: parent; text: "󰚰"; color: Colors.text; font.pixelSize: 24; font.family: Colors.fontMono }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 4
      Text {
        text: "System Updates"
        color: Colors.fgMain
        font.pixelSize: 14
        font.weight: Font.Bold
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      RowLayout {
        spacing: 12; Layout.fillWidth: true
        RowLayout {
          spacing: 4
          Text { text: ""; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 12 }
          Text {
            text: root.nixUpdates
            color: Colors.fgSecondary
            font.pixelSize: 11
            font.family: Colors.fontMono
          }
        }
        RowLayout {
          spacing: 4
          Text { text: "󰏘"; color: Colors.accent; font.family: Colors.fontMono; font.pixelSize: 12 }
          Text {
            text: root.flatpakUpdates
            color: Colors.fgSecondary
            font.pixelSize: 11
            font.family: Colors.fontMono
          }
        }
        Item { Layout.fillWidth: true }
      }
    }

    Rectangle {
      width: 80; height: 32; radius: 6; color: root.isChecking ? Colors.surface : Colors.primary
      Text {
        anchors.centerIn: parent
        text: root.isChecking ? "..." : "Refresh"
        color: Colors.text; font.pixelSize: 11; font.weight: Font.Bold
      }
      MouseArea {
        anchors.fill: parent
        enabled: !root.isChecking
        onClicked: root.checkUpdates()
      }
    }
  }
}
