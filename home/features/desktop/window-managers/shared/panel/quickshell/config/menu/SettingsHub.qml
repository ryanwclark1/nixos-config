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
  property string activeTab: "system" // system, appearance

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
    width: 700; height: 500
    anchors.centerIn: parent
    color: Colors.bgGlass
    border.color: Colors.border; border.width: 1; radius: Colors.radiusLarge
    clip: true

    MouseArea { anchors.fill: parent }

    RowLayout {
      anchors.fill: parent; spacing: 0

      // Sidebar Tabs
      Rectangle {
        width: 180; Layout.fillHeight: true; color: "#1affffff"
        ColumnLayout {
          anchors.fill: parent; anchors.margins: 20; spacing: 10
          Text { text: "SETTINGS"; color: Colors.textDisabled; font.pixelSize: 10; font.bold: true; Layout.bottomMargin: 10 }
          
          TabBtn { label: "System"; icon: "󰒓"; tabId: "system" }
          TabBtn { label: "Appearance"; icon: "󰸉"; tabId: "appearance" }
          TabBtn { label: "Hyprland"; icon: "󱗼"; tabId: "layout" }
          
          Item { Layout.fillHeight: true }
          
          Rectangle {
            Layout.fillWidth: true; height: 40; radius: 8; color: Colors.error
            Text { anchors.centerIn: parent; text: "Save & Close"; color: "white"; font.weight: Font.Bold; font.pixelSize: 12 }
            MouseArea { anchors.fill: parent; onClicked: { Config.save(); settingsRoot.close(); } }
          }
        }
      }

      // Content Area
      ColumnLayout {
        Layout.fillWidth: true; Layout.fillHeight: true; Layout.margins: 24; spacing: 20

        Text {
          text: activeTab === "system" ? "System Controls" : (activeTab === "appearance" ? "UI Appearance" : "Hyprland Layout")
          color: Colors.fgMain; font.pixelSize: 24; font.weight: Font.Bold
        }

        // --- SYSTEM TAB ---
        GridLayout {
          visible: activeTab === "system"
          columns: 2; columnSpacing: 15; rowSpacing: 15; Layout.fillWidth: true
          
          ToggleCard { label: "Animations"; icon: "󰢹"; property: "animState" }
          ToggleCard { label: "Auto Idle"; icon: "󰒲"; property: "idleState" }
          ToggleCard { label: "Night Light"; icon: "󰖔"; property: "nightLightState" }
          ToggleCard { label: "Blur Effects"; icon: "󰃠"; property: "blurEnabled"; isConfig: true }
        }

        // --- APPEARANCE TAB ---
        ColumnLayout {
          visible: activeTab === "appearance"
          spacing: 20; Layout.fillWidth: true

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
          spacing: 20; Layout.fillWidth: true

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
  }

  // --- COMPONENT HELPERS ---
  component TabBtn: Rectangle {
    property string label; property string icon; property string tabId
    Layout.fillWidth: true; height: 40; radius: 8
    color: activeTab === tabId ? Colors.highlight : "transparent"
    RowLayout {
      anchors.fill: parent; anchors.leftMargin: 12; spacing: 12
      Text { text: icon; color: activeTab === tabId ? Colors.primary : Colors.fgSecondary; font.family: Colors.fontMono; font.pixelSize: 16 }
      Text { text: label; color: activeTab === tabId ? Colors.fgMain : Colors.fgSecondary; font.pixelSize: 13 }
    }
    MouseArea { anchors.fill: parent; onClicked: activeTab = tabId }
  }

  component ConfigSlider: ColumnLayout {
    property string label; property real min; property real max; property real value; property real step: 1; signal moved(real v)
    spacing: 8; Layout.fillWidth: true
    RowLayout {
      Text { text: label; color: Colors.fgMain; font.pixelSize: 13 }
      Item { Layout.fillWidth: true }
      Text { text: Math.round(value * (step < 1 ? 100 : 1)) + (step < 1 ? "%" : "px"); color: Colors.fgSecondary; font.pixelSize: 11 }
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
          moved(step < 1 ? Math.round(raw/step)*step : Math.round(raw));
        }
      }
    }
  }

  component Switch: Rectangle {
    property bool checked; signal toggled()
    width: 40; height: 20; radius: 10; color: checked ? Colors.primary : Colors.surface
    Rectangle {
      width: 16; height: 16; radius: 8; color: "white"; anchors.verticalCenter: parent.verticalCenter
      x: checked ? parent.width - width - 2 : 2
      Behavior on x { NumberAnimation { duration: 150 } }
    }
    MouseArea { anchors.fill: parent; onClicked: toggled() }
  }

  component ToggleCard: Rectangle {
    property string label; property string icon; property string property; property bool isConfig: false
    Layout.fillWidth: true; height: 60; color: "#1affffff"; radius: 10
    property bool active: isConfig ? Config[property] : false // Simplified for demo
    
    RowLayout {
      anchors.fill: parent; anchors.margins: 15
      Text { text: icon; color: active ? Colors.primary : Colors.fgDim; font.family: Colors.fontMono; font.pixelSize: 20 }
      Text { text: label; color: Colors.fgMain; font.pixelSize: 13; Layout.fillWidth: true }
      Switch { checked: active; onToggled: { if(isConfig) Config[property] = !Config[property]; } }
    }
  }
}
