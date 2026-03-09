import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"

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
  property string activeTab: "system" // system, appearance, layout

  function open() { isOpen = true; }
  function close() { isOpen = false; }
  function toggle() { isOpen ? close() : open(); }

  IpcHandler {
    target: "SettingsHub"
    function toggle() { settingsRoot.toggle(); }
    function open() { settingsRoot.open(); }
    function close() { settingsRoot.close(); }
  }

  // Backdrop
  MouseArea {
    anchors.fill: parent; onClicked: settingsRoot.close()
    Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.5 }
  }

  // Main Container
  Rectangle {
    id: mainContainer
    width: 750; height: 550
    anchors.centerIn: parent
    color: Colors.bgGlass
    border.color: Colors.border; border.width: 1; radius: Colors.radiusLarge
    clip: true

    opacity: settingsRoot.isOpen ? 1.0 : 0.0
    scale: settingsRoot.isOpen ? 1.0 : 0.95
    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

    MouseArea { anchors.fill: parent }

    RowLayout {
      anchors.fill: parent; spacing: 0

      // Sidebar Tabs
      Rectangle {
        Layout.preferredWidth: 200; Layout.fillHeight: true; color: Qt.rgba(0, 0, 0, 0.1)
        
        ColumnLayout {
          anchors.fill: parent; anchors.margins: 24; spacing: 8
          
          Text { 
            text: "SETTINGS"
            color: Colors.textDisabled
            font.pixelSize: 9
            font.weight: Font.Black
            font.letterSpacing: 1.5
            Layout.bottomMargin: 12
          }
          
          TabBtn { label: "System"; icon: "󰒓"; tabId: "system" }
          TabBtn { label: "Appearance"; icon: "󰸉"; tabId: "appearance" }
          TabBtn { label: "Hyprland"; icon: "󱗼"; tabId: "layout" }
          
          Item { Layout.fillHeight: true }
          
          Rectangle {
            Layout.fillWidth: true; height: 42; radius: 10
            color: saveHover.containsMouse ? Qt.darker(Colors.primary, 1.1) : Colors.primary
            
            RowLayout {
              anchors.centerIn: parent; spacing: 8
              Text { text: "󰆓"; color: "white"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
              Text { text: "Save & Close"; color: "white"; font.weight: Font.Bold; font.pixelSize: 12 }
            }
            
            MouseArea { 
              id: saveHover
              anchors.fill: parent; hoverEnabled: true
              onClicked: { Config.save(); settingsRoot.close(); } 
            }
          }
        }
      }

      // Content Area
      ColumnLayout {
        Layout.fillWidth: true; Layout.fillHeight: true; Layout.margins: 32; spacing: 24

        Text {
          text: activeTab === "system" ? "System Controls" : (activeTab === "appearance" ? "UI Appearance" : "Hyprland Layout")
          color: Colors.fgMain; font.pixelSize: 26; font.weight: Font.Bold; font.letterSpacing: -0.5
        }

        // --- SYSTEM TAB ---
        GridLayout {
          visible: activeTab === "system"
          columns: 2; columnSpacing: 16; rowSpacing: 16; Layout.fillWidth: true
          
          ToggleCard { label: "Animations"; icon: "󰢹"; property: "animState" }
          ToggleCard { label: "Auto Idle"; icon: "󰒲"; property: "idleState" }
          ToggleCard { label: "Night Light"; icon: "󰖔"; property: "nightLightState" }
          ToggleCard { label: "Blur Effects"; icon: "󰃠"; property: "blurEnabled"; isConfig: true }
        }

        // --- APPEARANCE TAB ---
        ColumnLayout {
          visible: activeTab === "appearance"
          spacing: 24; Layout.fillWidth: true

          ConfigSlider { label: "Bar Height"; min: 20; max: 60; value: Config.barHeight; onMoved: (v) => Config.barHeight = v }
          ConfigSlider { label: "Bar Margin"; min: 0; max: 40; value: Config.barMargin; onMoved: (v) => Config.barMargin = v }
          ConfigSlider { label: "Glass Opacity"; min: 0.1; max: 1.0; value: Config.glassOpacity; step: 0.05; onMoved: (v) => Config.glassOpacity = v }
          
          RowLayout {
            spacing: 20
            Text { text: "Floating Bar"; color: Colors.fgMain; font.pixelSize: 14; Layout.fillWidth: true }
            Switch { checked: Config.barFloating; onToggled: Config.barFloating = !Config.barFloating }
          }
        }

        // --- HYPRLAND TAB ---
        ColumnLayout {
          visible: activeTab === "layout"
          spacing: 24; Layout.fillWidth: true

          RowLayout {
            spacing: 20
            Text { text: "Master Layout"; color: Colors.fgMain; font.pixelSize: 14; Layout.fillWidth: true }
            Switch { 
              checked: false
              onToggled: Quickshell.execDetached(["hyprctl", "dispatch", "layoutmsg", "toggle"])
            }
          }

          ConfigSlider { 
            label: "Outer Gaps"
            min: 0; max: 50; value: 10
            onMoved: (v) => Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_out", v.toString()])
          }

          ConfigSlider { 
            label: "Inner Gaps"
            min: 0; max: 30; value: 5
            onMoved: (v) => Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_in", v.toString()])
          }

          ConfigSlider { 
            label: "Active Opacity"
            min: 0.5; max: 1.0; value: 1.0; step: 0.05
            onMoved: (v) => Quickshell.execDetached(["hyprctl", "keyword", "decoration:active_opacity", v.toString()])
          }
        }

        Item { Layout.fillHeight: true }
      }
    }

    // --- COMPONENT HELPERS ---
    component TabBtn: Rectangle {
      property string label; property string icon; property string tabId
      Layout.fillWidth: true; height: 44; radius: 10
      color: activeTab === tabId ? Colors.highlight : "transparent"
      
      RowLayout {
        anchors.fill: parent; anchors.leftMargin: 16; spacing: 14
        Text { 
          text: icon
          color: activeTab === tabId ? Colors.primary : Colors.fgDim
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 18
        }
        Text { 
          text: label
          color: activeTab === tabId ? Colors.fgMain : Colors.fgSecondary
          font.pixelSize: 13
          font.weight: activeTab === tabId ? Font.DemiBold : Font.Normal
        }
      }
      
      MouseArea { 
        anchors.fill: parent; hoverEnabled: true
        onEntered: if (activeTab !== tabId) parent.color = Colors.highlightLight
        onExited: if (activeTab !== tabId) parent.color = "transparent"
        onClicked: activeTab = tabId 
      }
    }

    component ConfigSlider: ColumnLayout {
      property string label; property real min; property real max; property real value; property real step: 1; signal moved(real v)
      spacing: 12; Layout.fillWidth: true
      
      RowLayout {
        Text { text: label; color: Colors.fgMain; font.pixelSize: 13; font.weight: Font.Medium }
        Item { Layout.fillWidth: true }
        Text { 
          text: (step < 1 ? Math.round(value * 100) : Math.round(value)) + (step < 1 ? "%" : "px")
          color: Colors.fgSecondary; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" 
        }
      }
      
      Rectangle {
        Layout.fillWidth: true; height: 6; color: Colors.surface; radius: 3
        Rectangle {
          width: parent.width * ((value - min) / (max - min)); height: parent.height; color: Colors.primary; radius: 3
        }
        MouseArea {
          anchors.fill: parent
          onPressed: (mouse) => {
            var raw = min + (mouse.x / width) * (max - min);
            var val = step < 1 ? Math.round(raw/step)*step : Math.round(raw);
            moved(Math.max(min, Math.min(max, val)));
          }
        }
      }
    }

    component Switch: Rectangle {
      property bool checked; signal toggled()
      width: 40; height: 20; radius: 10; color: checked ? Colors.primary : Colors.surface
      
      Rectangle {
        width: 14; height: 14; radius: 7; color: "white"; anchors.verticalCenter: parent.verticalCenter
        x: checked ? parent.width - width - 3 : 3
        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
      }
      
      MouseArea { anchors.fill: parent; onClicked: toggled() }
    }

    component ToggleCard: Rectangle {
      property string label; property string icon; property string property; property bool isConfig: false
      Layout.fillWidth: true; height: 64; color: Colors.bgWidget; radius: 12; border.color: Colors.border; border.width: 1
      
      property bool active: isConfig ? Config[property] : false
      
      RowLayout {
        anchors.fill: parent; anchors.margins: 16; spacing: 16
        
        Rectangle {
          width: 32; height: 32; radius: 8; color: active ? Colors.highlight : Colors.surface
          Text { 
            anchors.centerIn: parent
            text: icon
            color: active ? Colors.primary : Colors.fgDim
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
          }
        }
        
        Text { 
          text: label
          color: Colors.fgMain
          font.pixelSize: 13
          font.weight: Font.Medium
          Layout.fillWidth: true 
        }
        
        Switch { checked: active; onToggled: { if(isConfig) Config[property] = !Config[property]; } }
      }
    }
  }
}
