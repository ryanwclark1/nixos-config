import QtQuick
import QtQuick.Layouts
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

  function checkUpdates() {
    isChecking = true;
    
    // Check NixOS (flake) updates - simplified for the widget
    var nixProc = Quickshell.exec(["sh", "-c", "nix flake check --no-build 2>/dev/null && echo 'Ready' || echo '0'"]);
    nixProc.exited.connect(function() {
       // Real implementation would be nix-channel --updated or similar
       root.nixUpdates = "Check required";
    });

    // Check Flatpak
    var fpProc = Quickshell.exec(["sh", "-c", "flatpak update --appstream >/dev/null 2>&1 && flatpak remote-ls --updates | wc -l"]);
    fpProc.exited.connect(function() {
       root.flatpakUpdates = fpProc.stdout.trim() || "0";
       isChecking = false;
    });
  }

  Component.onCompleted: checkUpdates()

  RowLayout {
    anchors.fill: parent
    anchors.margins: 15
    spacing: 15

    Rectangle {
      width: 50; height: 50; radius: 25; color: Colors.secondary
      Text { anchors.centerIn: parent; text: "󰚰"; color: "#ffffff"; font.pixelSize: 24; font.family: Colors.fontMono }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 2
      Text { text: "System Updates"; color: Colors.fgMain; font.pixelSize: 16; font.weight: Font.Bold }
      
      RowLayout {
        spacing: 10
        Text { text: " NixOS: " + root.nixUpdates; color: Colors.fgSecondary; font.pixelSize: 11; font.family: Colors.fontMono }
        Text { text: "󰏘 Flatpak: " + root.flatpakUpdates; color: Colors.fgSecondary; font.pixelSize: 11; font.family: Colors.fontMono }
      }
    }

    Rectangle {
      width: 80; height: 32; radius: 6; color: root.isChecking ? Colors.highlightLight : Colors.primary
      Text { 
        anchors.centerIn: parent
        text: root.isChecking ? "..." : "Refresh"
        color: "#ffffff"; font.pixelSize: 11; font.weight: Font.Bold 
      }
      MouseArea {
        anchors.fill: parent
        enabled: !root.isChecking
        onClicked: root.checkUpdates()
      }
    }
  }
}
