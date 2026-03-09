import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "."

PanelWindow {
  id: settingsRoot
  
  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }
  
  color: "transparent"
  visible: isOpen

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "quickshell"

  property bool isOpen: false

  // State properties
  property bool animState: true
  property bool idleState: true
  property bool nightLightState: false
  property bool floatState: false

  function toggle() {
    if (isOpen) {
      close();
    } else {
      open();
    }
  }

  function open() {
    isOpen = true;
    checkStates();
  }
  
  function close() {
    isOpen = false;
  }

  function checkStates() {
    // Check Animations (Cache file absence means animations are enabled)
    var animProc = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["bash", "-c", "[ ! -f ~/.cache/toggle_animation ] && echo true || echo false"] }', settingsRoot);
    animProc.finished.connect(function() { settingsRoot.animState = animProc.stdout.readAll().trim() === "true"; });
    animProc.running = true;

    // Check Night Light
    var nightProc = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["bash", "-c", "pgrep -x hyprsunset >/dev/null && echo true || echo false"] }', settingsRoot);
    nightProc.finished.connect(function() { settingsRoot.nightLightState = nightProc.stdout.readAll().trim() === "true"; });
    nightProc.running = true;

    // Check Idle
    var idleProc = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["bash", "-c", "pgrep -x hypridle >/dev/null && echo true || echo false"] }', settingsRoot);
    idleProc.finished.connect(function() { settingsRoot.idleState = idleProc.stdout.readAll().trim() === "true"; });
    idleProc.running = true;
  }

  IpcHandler {
    target: "SettingsHub"
    function toggle() { settingsRoot.toggle(); }
    function open() { settingsRoot.open(); }
    function close() { settingsRoot.close(); }
  }

  // Backdrop to catch clicks and close
  MouseArea {
    anchors.fill: parent
    onClicked: settingsRoot.close()
    
    Rectangle {
      anchors.fill: parent
      color: "#000000"
      opacity: 0.5
    }
  }

  // Main Container
  Rectangle {
    width: 500
    height: 380
    anchors.centerIn: parent
    color: Colors.background
    opacity: 0.95
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusLarge

    // Prevent clicks from reaching the backdrop
    MouseArea { anchors.fill: parent }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 20
      spacing: 20

      // Header
      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "Settings Hub"
          color: Colors.text
          font.pixelSize: 22
          font.weight: Font.Bold
        }
        Item { Layout.fillWidth: true }
        
        Rectangle {
          width: 30
          height: 30
          radius: 15
          color: closeHover.containsMouse ? Colors.surface : "transparent"
          Text {
            anchors.centerIn: parent
            text: "󰅖"
            color: Colors.textSecondary
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
          }
          MouseArea {
            id: closeHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: settingsRoot.close()
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.border
      }

      // Settings Grid
      GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 2
        columnSpacing: 15
        rowSpacing: 15

        // Animations Toggle
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 70
          color: Colors.highlightLight
          radius: Colors.radiusMedium
          border.color: animHover.containsMouse ? Colors.primary : "transparent"
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            Text {
              text: "󰢹"
              color: settingsRoot.animState ? Colors.primary : Colors.textDisabled
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 24
            }

            ColumnLayout {
              spacing: 2
              Text { text: "Animations"; color: Colors.text; font.pixelSize: 14; font.weight: Font.DemiBold }
              Text { text: settingsRoot.animState ? "Enabled" : "Disabled"; color: Colors.textSecondary; font.pixelSize: 11 }
            }
            Item { Layout.fillWidth: true }
            
            Rectangle {
              width: 40
              height: 20
              radius: 10
              color: settingsRoot.animState ? Colors.primary : Colors.surface
              Rectangle {
                width: 16
                height: 16
                radius: 8
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
                x: settingsRoot.animState ? parent.width - width - 2 : 2
                Behavior on x { NumberAnimation { duration: 150 } }
              }
            }
          }

          MouseArea {
            id: animHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              settingsRoot.animState = !settingsRoot.animState;
              Quickshell.execDetached(["toggle-animations.sh"]);
            }
          }
        }

        // Night Light Toggle
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 70
          color: Colors.highlightLight
          radius: Colors.radiusMedium
          border.color: nightHover.containsMouse ? Colors.accent : "transparent"
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            Text {
              text: "󰖔"
              color: settingsRoot.nightLightState ? Colors.accent : Colors.textDisabled
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 24
            }

            ColumnLayout {
              spacing: 2
              Text { text: "Night Light"; color: Colors.text; font.pixelSize: 14; font.weight: Font.DemiBold }
              Text { text: settingsRoot.nightLightState ? "Active" : "Inactive"; color: Colors.textSecondary; font.pixelSize: 11 }
            }
            Item { Layout.fillWidth: true }
            
            Rectangle {
              width: 40
              height: 20
              radius: 10
              color: settingsRoot.nightLightState ? Colors.accent : Colors.surface
              Rectangle {
                width: 16
                height: 16
                radius: 8
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
                x: settingsRoot.nightLightState ? parent.width - width - 2 : 2
                Behavior on x { NumberAnimation { duration: 150 } }
              }
            }
          }

          MouseArea {
            id: nightHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              settingsRoot.nightLightState = !settingsRoot.nightLightState;
              Quickshell.execDetached(["bash", "-c", "pgrep -x hyprsunset >/dev/null && pkill hyprsunset || hyprsunset &"]);
            }
          }
        }

        // Idle Toggle
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 70
          color: Colors.highlightLight
          radius: Colors.radiusMedium
          border.color: idleHover.containsMouse ? Colors.secondary : "transparent"
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            Text {
              text: "󰒲"
              color: settingsRoot.idleState ? Colors.secondary : Colors.textDisabled
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 24
            }

            ColumnLayout {
              spacing: 2
              Text { text: "Auto Idle / Lock"; color: Colors.text; font.pixelSize: 14; font.weight: Font.DemiBold }
              Text { text: settingsRoot.idleState ? "Enabled" : "Disabled"; color: Colors.textSecondary; font.pixelSize: 11 }
            }
            Item { Layout.fillWidth: true }
            
            Rectangle {
              width: 40
              height: 20
              radius: 10
              color: settingsRoot.idleState ? Colors.secondary : Colors.surface
              Rectangle {
                width: 16
                height: 16
                radius: 8
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
                x: settingsRoot.idleState ? parent.width - width - 2 : 2
                Behavior on x { NumberAnimation { duration: 150 } }
              }
            }
          }

          MouseArea {
            id: idleHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              settingsRoot.idleState = !settingsRoot.idleState;
              Quickshell.execDetached(["toggle-idle.sh"]);
            }
          }
        }

        // All Float Toggle
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 70
          color: Colors.highlightLight
          radius: Colors.radiusMedium
          border.color: floatHover.containsMouse ? Colors.error : "transparent"
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            Text {
              text: "󱂬"
              color: Colors.error
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 24
            }

            ColumnLayout {
              spacing: 2
              Text { text: "Toggle Float"; color: Colors.text; font.pixelSize: 14; font.weight: Font.DemiBold }
              Text { text: "All Windows"; color: Colors.textSecondary; font.pixelSize: 11 }
            }
            Item { Layout.fillWidth: true }
          }

          MouseArea {
            id: floatHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              Quickshell.execDetached(["toggle-all-float.sh"]);
              settingsRoot.close();
            }
          }
        }
      }

      // One-Shot Action Buttons (Reload, Transparency)
      RowLayout {
        Layout.fillWidth: true
        spacing: 15

        Rectangle {
          Layout.fillWidth: true
          height: 45
          color: transHover.containsMouse ? Colors.surface : Colors.highlightLight
          radius: Colors.radiusSmall

          RowLayout {
            anchors.centerIn: parent
            spacing: 8
            Text { text: "󰂵"; color: Colors.text; font.family: "JetBrainsMono Nerd Font" }
            Text { text: "Toggle Active Window Transparency"; color: Colors.text; font.pixelSize: 12; font.weight: Font.Medium }
          }

          MouseArea {
            id: transHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              Quickshell.execDetached(["toggle-transparency.sh"]);
              settingsRoot.close();
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 15

        Rectangle {
          Layout.fillWidth: true
          height: 45
          color: reloadHover.containsMouse ? Colors.error : Colors.surface
          radius: Colors.radiusSmall

          RowLayout {
            anchors.centerIn: parent
            spacing: 8
            Text { text: "󰑐"; color: Colors.text; font.family: "JetBrainsMono Nerd Font" }
            Text { text: "Reload Hyprland Config"; color: Colors.text; font.pixelSize: 12; font.weight: Font.Bold }
          }

          MouseArea {
            id: reloadHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              Quickshell.execDetached(["hyprctl", "reload"]);
              settingsRoot.close();
            }
          }
        }
      }
    }
  }

  // Close on Escape
  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: settingsRoot.close()
  }
}
