import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services"

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

  Process {
    id: nixProc
    command: ["sh", "-c", "nix flake check --no-build 2>/dev/null && echo 'Ready' || echo '0'"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.nixUpdates = this.text.trim() || "0";
      }
    }
  }

  Process {
    id: fpProc
    command: ["sh", "-c", "flatpak update --appstream >/dev/null 2>&1 && flatpak remote-ls --updates | wc -l"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.flatpakUpdates = this.text.trim() || "0";
        root.isChecking = false;
      }
    }
  }

  function checkUpdates() {
    isChecking = true;
    nixProc.running = true;
    fpProc.running = true;
  }

  Component.onCompleted: checkUpdates()

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
          Text { text: ""; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 12 }
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
