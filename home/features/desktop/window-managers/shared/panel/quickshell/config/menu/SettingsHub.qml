import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
  property string activeTab: "system"
  property real layoutGapsOut: 10
  property real layoutGapsIn: 5
  property real layoutActiveOpacity: 1.0

  readonly property var launcherModeOptions: [
    { value: "drun", label: "Apps" },
    { value: "window", label: "Windows" },
    { value: "files", label: "Files" },
    { value: "ai", label: "AI" },
    { value: "clip", label: "Clipboard" },
    { value: "system", label: "System" },
    { value: "media", label: "Media" }
  ]

  function refreshHyprlandSettings() {
    hyprStateProc.running = true;
  }

  function open() {
    isOpen = true;
    refreshHyprlandSettings();
  }

  function close() {
    isOpen = false;
  }

  function toggle() {
    isOpen ? close() : open();
  }

  IpcHandler {
    target: "SettingsHub"
    function toggle() { settingsRoot.toggle(); }
    function open() { settingsRoot.open(); }
    function close() { settingsRoot.close(); }
  }

  Process {
    id: hyprStateProc
    command: [
      "sh",
      "-c",
      "hyprctl getoption general:gaps_out -j 2>/dev/null; "
      + "printf '\\n'; "
      + "hyprctl getoption general:gaps_in -j 2>/dev/null; "
      + "printf '\\n'; "
      + "hyprctl getoption decoration:active_opacity -j 2>/dev/null"
    ]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").trim().split("\n");
        try {
          if (lines[0]) {
            var gapsOut = JSON.parse(lines[0]);
            settingsRoot.layoutGapsOut = gapsOut.int !== undefined ? gapsOut.int : settingsRoot.layoutGapsOut;
          }
          if (lines[1]) {
            var gapsIn = JSON.parse(lines[1]);
            settingsRoot.layoutGapsIn = gapsIn.int !== undefined ? gapsIn.int : settingsRoot.layoutGapsIn;
          }
          if (lines[2]) {
            var activeOpacity = JSON.parse(lines[2]);
            settingsRoot.layoutActiveOpacity = activeOpacity.float !== undefined ? activeOpacity.float : settingsRoot.layoutActiveOpacity;
          }
        } catch (e) {
          console.error("Failed to parse Hyprland settings: " + e);
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: settingsRoot.close()

    Rectangle {
      anchors.fill: parent
      color: Colors.background
      opacity: 0.5
    }
  }

  Rectangle {
    id: mainBox
    width: 780
    height: 620
    anchors.centerIn: parent
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusLarge
    clip: true

    focus: settingsRoot.isOpen
    onVisibleChanged: if (visible) forceActiveFocus()
    Keys.onEscapePressed: settingsRoot.isOpen = false

    opacity: settingsRoot.isOpen ? 1.0 : 0.0
    scale: settingsRoot.isOpen ? 1.0 : 0.95
    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

    MouseArea { anchors.fill: parent }

    RowLayout {
      anchors.fill: parent
      spacing: 0

      Rectangle {
        Layout.preferredWidth: 200
        Layout.fillHeight: true
        color: Qt.rgba(0, 0, 0, 0.1)

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Colors.paddingLarge
          spacing: 8

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
            Layout.fillWidth: true
            height: 42
            radius: 10
            color: saveHover.containsMouse ? Qt.darker(Colors.primary, 1.1) : Colors.primary

            RowLayout {
              anchors.centerIn: parent
              spacing: 8
              Text { text: "󰆓"; color: Colors.text; font.family: Colors.fontMono; font.pixelSize: 14 }
              Text { text: "Save & Close"; color: Colors.text; font.weight: Font.Bold; font.pixelSize: 12 }
            }

            MouseArea {
              id: saveHover
              anchors.fill: parent
              hoverEnabled: true
              onClicked: {
                Config.save();
                settingsRoot.close();
              }
            }
          }
        }
      }

      Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentHeight: contentColumn.implicitHeight + 64
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
          id: contentColumn
          width: parent.width - 64
          x: 32
          y: 32
          spacing: 24

          Text {
            text: activeTab === "system" ? "Shell Behavior" : (activeTab === "appearance" ? "UI Appearance" : "Hyprland Layout")
            color: Colors.fgMain
            font.pixelSize: 26
            font.weight: Font.Bold
            font.letterSpacing: -0.5
          }

          ColumnLayout {
            visible: activeTab === "system"
            spacing: 20
            Layout.fillWidth: true

            SectionLabel { text: "Shell" }

            GridLayout {
              columns: 2
              columnSpacing: 16
              rowSpacing: 16
              Layout.fillWidth: true

              ToggleCard { label: "Floating Bar"; icon: "󰖲"; configKey: "barFloating" }
              ToggleCard { label: "Blur Effects"; icon: "󰃠"; configKey: "blurEnabled" }
            }

            ConfigSlider {
              label: "Notification Width"
              min: 280
              max: 520
              value: Config.notifWidth
              onMoved: (v) => Config.notifWidth = v
            }

            ConfigSlider {
              label: "Popup Duration"
              min: 2000
              max: 10000
              step: 500
              value: Config.popupTimer
              unit: "ms"
              onMoved: (v) => Config.popupTimer = v
            }

            SectionLabel { text: "Launcher" }

            ModeSelector {
              label: "Default Mode"
              currentValue: Config.launcherDefaultMode
              options: settingsRoot.launcherModeOptions
              onSelected: (modeValue) => Config.launcherDefaultMode = modeValue
            }

            GridLayout {
              columns: 2
              columnSpacing: 16
              rowSpacing: 16
              Layout.fillWidth: true

              ToggleCard { label: "Show Mode Hints"; icon: "󰌌"; configKey: "launcherShowModeHints" }
              ToggleCard { label: "Show Home Sections"; icon: "󰆍"; configKey: "launcherShowHomeSections" }
            }

            SectionLabel { text: "Control Center" }

            GridLayout {
              columns: 2
              columnSpacing: 16
              rowSpacing: 16
              Layout.fillWidth: true

              ToggleCard { label: "Quick Links"; icon: "󰖩"; configKey: "controlCenterShowQuickLinks" }
              ToggleCard { label: "Media Widget"; icon: "󰝚"; configKey: "controlCenterShowMediaWidget" }
            }

            ConfigSlider {
              label: "Control Center Width"
              min: 320
              max: 460
              value: Config.controlCenterWidth
              onMoved: (v) => Config.controlCenterWidth = v
            }

            SectionLabel { text: "Feedback" }

            ConfigSlider {
              label: "OSD Duration"
              min: 1000
              max: 5000
              step: 250
              value: Config.osdDuration
              unit: "ms"
              onMoved: (v) => Config.osdDuration = v
            }
          }

          ColumnLayout {
            visible: activeTab === "appearance"
            spacing: 20
            Layout.fillWidth: true

            SectionLabel { text: "Bar" }

            ConfigSlider { label: "Bar Height"; min: 20; max: 60; value: Config.barHeight; onMoved: (v) => Config.barHeight = v }
            ConfigSlider { label: "Bar Margin"; min: 0; max: 40; value: Config.barMargin; onMoved: (v) => Config.barMargin = v }
            ConfigSlider { label: "Bar Opacity"; min: 0.3; max: 1.0; value: Config.barOpacity; step: 0.05; unit: "%"; onMoved: (v) => Config.barOpacity = v }
            ConfigSlider { label: "Glass Opacity"; min: 0.1; max: 1.0; value: Config.glassOpacity; step: 0.05; onMoved: (v) => Config.glassOpacity = v }

            RowLayout {
              spacing: 20
              Text { text: "Floating Bar"; color: Colors.fgMain; font.pixelSize: 14; Layout.fillWidth: true }
              Switch { checked: Config.barFloating; onToggled: Config.barFloating = !Config.barFloating }
            }

            SectionLabel { text: "OSD" }

            ConfigSlider {
              label: "OSD Size"
              min: 140
              max: 260
              value: Config.osdSize
              onMoved: (v) => Config.osdSize = v
            }
          }

          ColumnLayout {
            visible: activeTab === "layout"
            spacing: 24
            Layout.fillWidth: true

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
              min: 0
              max: 50
              value: settingsRoot.layoutGapsOut
              onMoved: (v) => {
                settingsRoot.layoutGapsOut = v;
                Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_out", v.toString()]);
              }
            }

            ConfigSlider {
              label: "Inner Gaps"
              min: 0
              max: 30
              value: settingsRoot.layoutGapsIn
              onMoved: (v) => {
                settingsRoot.layoutGapsIn = v;
                Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_in", v.toString()]);
              }
            }

            ConfigSlider {
              label: "Active Opacity"
              min: 0.5
              max: 1.0
              value: settingsRoot.layoutActiveOpacity
              step: 0.05
              onMoved: (v) => {
                settingsRoot.layoutActiveOpacity = v;
                Quickshell.execDetached(["hyprctl", "keyword", "decoration:active_opacity", v.toString()]);
              }
            }
          }
        }
      }
    }

    component SectionLabel: Text {
      color: Colors.textDisabled
      font.pixelSize: 10
      font.weight: Font.Black
      font.letterSpacing: 1.2
      Layout.topMargin: 6
    }

    component TabBtn: Rectangle {
      property string label
      property string icon
      property string tabId
      Layout.fillWidth: true
      height: 44
      radius: 10
      color: activeTab === tabId ? Colors.highlight : "transparent"

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        spacing: 14
        Text {
          text: icon
          color: activeTab === tabId ? Colors.primary : Colors.fgDim
          font.family: Colors.fontMono
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
        anchors.fill: parent
        hoverEnabled: true
        onEntered: if (activeTab !== tabId) parent.color = Colors.highlightLight
        onExited: if (activeTab !== tabId) parent.color = "transparent"
        onClicked: activeTab = tabId
      }
    }

    component ConfigSlider: ColumnLayout {
      property string label
      property real min
      property real max
      property real value
      property real step: 1
      property string unit: step < 1 ? "%" : "px"
      signal moved(real v)
      spacing: 12
      Layout.fillWidth: true

      RowLayout {
        Text { text: label; color: Colors.fgMain; font.pixelSize: 13; font.weight: Font.Medium }
        Item { Layout.fillWidth: true }
        Text {
          text: (unit === "ms" ? Math.round(value) : (step < 1 ? Math.round(value * 100) : Math.round(value))) + unit
          color: Colors.fgSecondary
          font.pixelSize: 11
          font.family: Colors.fontMono
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 6
        color: Colors.surface
        radius: 3
        Rectangle {
          width: parent.width * ((value - min) / (max - min))
          height: parent.height
          color: Colors.primary
          radius: 3
        }
        MouseArea {
          anchors.fill: parent
          function updateValue(mouse) {
            var raw = min + (mouse.x / width) * (max - min);
            var val = Math.round(raw / step) * step;
            moved(Math.max(min, Math.min(max, val)));
          }
          onPressed: (mouse) => updateValue(mouse)
          onPositionChanged: (mouse) => {
            if (pressed) updateValue(mouse);
          }
        }
      }
    }

    component Switch: Rectangle {
      property bool checked
      signal toggled()
      width: 40
      height: 20
      radius: 10
      color: checked ? Colors.primary : Colors.surface

      Rectangle {
        width: 14
        height: 14
        radius: 7
        color: "white"
        anchors.verticalCenter: parent.verticalCenter
        x: checked ? parent.width - width - 3 : 3
        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
      }

      MouseArea { anchors.fill: parent; onClicked: toggled() }
    }

    component ToggleCard: Rectangle {
      property string label
      property string icon
      property string configKey

      Layout.fillWidth: true
      implicitHeight: 84
      radius: Colors.radiusMedium
      color: toggleHover.containsMouse ? Colors.highlightLight : Colors.bgWidget
      border.color: Config[configKey] ? Colors.primary : Colors.border
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        Text {
          text: icon
          color: Config[configKey] ? Colors.primary : Colors.textSecondary
          font.family: Colors.fontMono
          font.pixelSize: 20
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 3
          Text { text: label; color: Colors.fgMain; font.pixelSize: 13; font.weight: Font.DemiBold }
          Text { text: Config[configKey] ? "Enabled" : "Disabled"; color: Colors.textSecondary; font.pixelSize: 11 }
        }

        Switch {
          checked: Config[configKey]
          onToggled: Config[configKey] = !Config[configKey]
        }
      }

      MouseArea {
        id: toggleHover
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Config[configKey] = !Config[configKey]
      }
    }

    component ModeSelector: ColumnLayout {
      property string label
      property string currentValue
      property var options: []
      signal selected(string modeValue)
      spacing: 12
      Layout.fillWidth: true

      Text { text: label; color: Colors.fgMain; font.pixelSize: 13; font.weight: Font.Medium }

      Flow {
        Layout.fillWidth: true
        width: parent.width
        spacing: 10

        Repeater {
          model: options
          delegate: Rectangle {
            width: 96
            height: 38
            radius: 19
            color: currentValue === modelData.value ? Colors.highlight : Colors.bgWidget
            border.color: currentValue === modelData.value ? Colors.primary : Colors.border
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: modelData.label
              color: currentValue === modelData.value ? Colors.primary : Colors.fgMain
              font.pixelSize: 12
              font.weight: Font.DemiBold
            }

            MouseArea {
              anchors.fill: parent
              onClicked: selected(modelData.value)
            }
          }
        }
      }
    }
  }
}
