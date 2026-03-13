import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Wayland
import Quickshell.Widgets
import "."
import "../modules"
import "../services"
import "../widgets" as SharedWidgets

PanelWindow {
  id: root

  property string surfaceEdge: "right"
  property int panelWidth: Config.controlCenterWidth
  property int panelHeight: 640
  property real panelX: 0
  readonly property var edgeMargins: Config.reservedEdgesForScreen(screen, "")
  property int reservedTop: edgeMargins.top
  property int reservedRight: edgeMargins.right
  property int reservedBottom: edgeMargins.bottom
  property int reservedLeft: edgeMargins.left
  anchors {
    top: surfaceEdge === "right" || surfaceEdge === "left" || surfaceEdge === "top"
    right: surfaceEdge === "right"
    bottom: surfaceEdge === "right" || surfaceEdge === "left" || surfaceEdge === "bottom"
    left: surfaceEdge === "left" || surfaceEdge === "top" || surfaceEdge === "bottom"
  }
  margins.top: surfaceEdge === "right" || surfaceEdge === "left" || surfaceEdge === "top" ? reservedTop : 0
  margins.right: surfaceEdge === "right" ? reservedRight : 0
  margins.bottom: surfaceEdge === "right" || surfaceEdge === "left" || surfaceEdge === "bottom" ? reservedBottom : 0
  margins.left: surfaceEdge === "left" ? reservedLeft : ((surfaceEdge === "top" || surfaceEdge === "bottom") ? panelX : 0)

  implicitWidth: panelWidth
  implicitHeight: surfaceEdge === "top" || surfaceEdge === "bottom" ? panelHeight : 0
  color: "transparent"
  mask: Region {
    item: sidebarContent
  }
  WlrLayershell.layer: WlrLayer.Top
  // Command center has no text inputs; keep keyboard with focused app (e.g. Ghostty).
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  WlrLayershell.namespace: "quickshell"

  property var manager: null
  property bool showContent: false
  property var pendingPowerCmd: null
  property int pendingPowerIndex: -1
  property var previousFocusedToplevel: null
  signal closeRequested()

  function focusedToplevel() {
    if (typeof ToplevelManager !== "undefined" && ToplevelManager.activeToplevel) {
      return ToplevelManager.activeToplevel;
    }
    return null;
  }

  onShowContentChanged: {
    if (showContent) {
      root.previousFocusedToplevel = focusedToplevel();
    } else {
      if (sidebarContent.activeFocus) sidebarContent.focus = false;
      if (root.previousFocusedToplevel) restoreFocusTimer.restart();
    }
  }

  Timer {
    id: restoreFocusTimer
    interval: 60
    repeat: false
    onTriggered: {
      if (!root.previousFocusedToplevel) return;
      if (root.previousFocusedToplevel.activate) root.previousFocusedToplevel.activate();
      root.previousFocusedToplevel = null;
    }
  }

  Timer {
    id: powerConfirmTimer
    interval: 3000
    onTriggered: { root.pendingPowerCmd = null; root.pendingPowerIndex = -1; }
  }
  visible: {
    if (surfaceEdge === "right") return showContent || sidebarContent.x < panelWidth;
    if (surfaceEdge === "left") return showContent || sidebarContent.x > -panelWidth;
    if (surfaceEdge === "top") return showContent || sidebarContent.y > -sidebarContent.height;
    return showContent || sidebarContent.y < sidebarContent.height;
  }

  SharedWidgets.Ref { service: AudioService }
  Loader { active: root.showContent; sourceComponent: SharedWidgets.Ref { service: SystemStatus } }
  Loader { active: root.showContent; sourceComponent: SharedWidgets.Ref { service: RecordingService } }

  Rectangle {
    id: sidebarContent
    width: root.panelWidth; height: root.surfaceEdge === "top" || root.surfaceEdge === "bottom" ? root.panelHeight : parent.height; color: Colors.bgGlass; border.color: Colors.border; border.width: 1; radius: Colors.radiusLarge
    x: {
      if (root.surfaceEdge === "right") return root.showContent ? 0 : root.panelWidth + 10;
      if (root.surfaceEdge === "left") return root.showContent ? 0 : -root.panelWidth - 10;
      return 0;
    }
    y: {
      if (root.surfaceEdge === "top") return root.showContent ? 0 : -height - 10;
      if (root.surfaceEdge === "bottom") return root.showContent ? 0 : height + 10;
      return 0;
    }
    opacity: root.showContent ? 1.0 : 0.0
    Behavior on x { NumberAnimation { id: ccSlideAnim; duration: 300; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { id: ccFadeAnim; duration: 250 } }
    layer.enabled: ccSlideAnim.running || ccFadeAnim.running

    Keys.onEscapePressed: root.closeRequested()

    ColumnLayout {
      anchors.fill: parent; anchors.margins: Colors.paddingLarge; spacing: Colors.spacingXL
      RowLayout {
        Layout.fillWidth: true
        Text { text: "Command Center"; color: Colors.text; font.pixelSize: Colors.fontSizeHuge; font.weight: Font.DemiBold; font.letterSpacing: -0.5 }
        Item { Layout.fillWidth: true }
        Rectangle {
          width: 32; height: 32; radius: height / 2; color: "transparent"
          Text { anchors.centerIn: parent; text: "󰒓"; color: Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
          SharedWidgets.StateLayer {
            id: settingsStateLayer
            hovered: settingsHover.containsMouse
            pressed: settingsHover.pressed
          }
          MouseArea {
            id: settingsHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => { settingsStateLayer.burst(mouse.x, mouse.y); root.closeRequested(); Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "toggle"]); }
          }
        }
        Rectangle {
          width: 32; height: 32; radius: height / 2; color: "transparent"
          Text { anchors.centerIn: parent; text: "󰅖"; color: Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
          SharedWidgets.StateLayer {
            id: closeStateLayer
            hovered: closeHover.containsMouse
            pressed: closeHover.pressed
          }
          MouseArea { id: closeHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: (mouse) => { closeStateLayer.burst(mouse.x, mouse.y); root.closeRequested(); } }
        }
      }

      Flickable {
        Layout.fillWidth: true; Layout.fillHeight: true; contentHeight: mainCol.height; clip: true
        boundsBehavior: Flickable.StopAtBounds; flickableDirection: Flickable.VerticalFlick
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
          id: mainCol; width: parent.width; spacing: 20

          component QuickLinkCard: Rectangle {
            property string icon
            property string title
            property string subtitle
            property var clickCommand: []

            Layout.fillWidth: true
            implicitHeight: 68
            radius: Colors.radiusMedium
            color: Colors.bgWidget
            border.color: Colors.border
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: Colors.spacingM
              spacing: Colors.spacingM

              Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: height / 2
                color: Colors.withAlpha(Colors.primary, 0.12)

                Text {
                  anchors.centerIn: parent
                  text: icon
                  color: Colors.primary
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeXL
                }
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                  text: title
                  color: Colors.text
                  font.pixelSize: Colors.fontSizeMedium
                  font.weight: Font.DemiBold
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }

                Text {
                  text: subtitle
                  color: Colors.textSecondary
                  font.pixelSize: Colors.fontSizeXS
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
              }

              Text {
                text: "󰄮"
                color: Colors.textSecondary
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeMedium
              }
            }

            SharedWidgets.StateLayer {
              id: stateLayer
              hovered: quickLinkHover.containsMouse
              pressed: quickLinkHover.pressed
            }

            MouseArea {
              id: quickLinkHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: (mouse) => { stateLayer.burst(mouse.x, mouse.y); Quickshell.execDetached(clickCommand); }
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS
            visible: Config.controlCenterShowQuickLinks

            QuickLinkCard {
              icon: "󰕾"
              title: "Audio Controls"
              subtitle: "Devices, volume, and mute"
              clickCommand: ["quickshell", "ipc", "call", "Shell", "toggleAudioMenu"]
            }

            QuickLinkCard {
              icon: "󰖩"
              title: "Network Controls"
              subtitle: "Wi-Fi, VPN, and Tailscale"
              clickCommand: ["quickshell", "ipc", "call", "Shell", "toggleNetworkMenu"]
            }
          }

          UserWidget {
            opacity: root.showContent ? 1 : 0
            visible: opacity > 0
            scale: root.showContent ? 1 : 0.95
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
          }

          // Quick Toggles Grid
          GridLayout {
            columns: 2; Layout.fillWidth: true; rowSpacing: 10; columnSpacing: 10
            opacity: root.showContent ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

            QuickToggle {
              icon: "󰂯"; label: "Bluetooth"; active: !!(Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled)
              onClicked: { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled; }
            }
            QuickToggle {
              icon: "󰒲"; label: "DND"; active: !!(root.manager && root.manager.dndEnabled)
              onClicked: { if (root.manager) root.manager.dndEnabled = !root.manager.dndEnabled; }
            }
            QuickToggle {
              id: nightLightToggle; icon: "󰖔"; label: "Night Light"; active: false
              onClicked: { Quickshell.execDetached(["os-toggle-nightlight"]); active = !active; nightLightVerify.restart(); }
              SharedWidgets.CommandPoll {
                id: nightLightPoll
                interval: 5000
                running: root.showContent
                command: ["sh", "-c", "hyprctl hyprsunset temperature 2>/dev/null | grep -v '6000' >/dev/null && echo 'on' || echo 'off'"]
                parse: function(out) { return String(out || "").trim(); }
                onUpdated: nightLightToggle.active = (nightLightPoll.value === "on")
              }
              Timer {
                id: nightLightVerify; interval: 500; repeat: false
                onTriggered: nightLightPoll.poll()
              }
            }
            QuickToggle {
              icon: "󰑊"; label: "Recording"; active: RecordingService.isRecording
              onClicked: {
                if (RecordingService.isRecording) RecordingService.stopRecording();
                else RecordingService.startRecording("fullscreen");
              }
            }
          }

          MediaWidget {
            opacity: root.showContent ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
          }

          // Sliders
          ColumnLayout {
            Layout.fillWidth: true; spacing: 15
            opacity: root.showContent ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 550; easing.type: Easing.OutCubic } }

            ColumnLayout {
              Layout.fillWidth: true; spacing: 6
              RowLayout {
                Layout.fillWidth: true
                Text { text: "󰃠  BRIGHTNESS"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
                Item { Layout.fillWidth: true }
                Text {
                  text: SystemStatus.brightnessAvailable ? Math.round(SystemStatus.brightness * 100) + "%" : "Unavailable"
                  color: SystemStatus.brightnessAvailable ? Colors.textSecondary : Colors.warning
                  font.pixelSize: Colors.fontSizeXS
                }
              }
              SharedWidgets.SliderTrack {
                Layout.fillWidth: true
                value: SystemStatus.brightness
                icon: "󰃠"
                enabled: SystemStatus.brightnessAvailable
                opacity: enabled ? 1.0 : 0.4
                onSliderMoved: (v) => SystemStatus.setBrightness(Math.max(0.01, v))
              }
              Text {
                text: SystemStatus.brightnessStatus
                color: SystemStatus.brightnessAvailable ? Colors.success : Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                Layout.fillWidth: true
                elide: Text.ElideRight
              }
            }

            ColumnLayout {
              Layout.fillWidth: true; spacing: 6
              RowLayout {
                Layout.fillWidth: true
                Text { text: "󰕾  OUTPUT"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
                Item { Layout.fillWidth: true }
                Text { text: AudioService.outputMuted ? "Muted" : Math.round(AudioService.outputVolume * 100) + "%"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS }
              }
              RowLayout {
                Layout.fillWidth: true
                spacing: 10
                SharedWidgets.MuteButton {
                  target: "@DEFAULT_AUDIO_SINK@"
                  muted: AudioService.outputMuted
                  icon: "󰕾"; mutedIcon: "󰝟"
                  size: 32; showBorder: true
                }
                SharedWidgets.SliderTrack {
                  Layout.fillWidth: true
                  value: AudioService.outputVolume
                  muted: AudioService.outputMuted
                  icon: "󰕾"
                  mutedIcon: "󰝟"
                  onSliderMoved: (v) => AudioService.setVolume("@DEFAULT_AUDIO_SINK@", v)
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true; spacing: 6
              RowLayout {
                Layout.fillWidth: true
                Text { text: "󰍬  INPUT"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
                Item { Layout.fillWidth: true }
                Text { text: AudioService.inputMuted ? "Muted" : Math.round(AudioService.inputVolume * 100) + "%"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS }
              }
              RowLayout {
                Layout.fillWidth: true
                spacing: 10
                SharedWidgets.MuteButton {
                  target: "@DEFAULT_AUDIO_SOURCE@"
                  muted: AudioService.inputMuted
                  icon: "󰍬"; mutedIcon: "󰍭"
                  size: 32; showBorder: true
                }
                SharedWidgets.SliderTrack {
                  Layout.fillWidth: true
                  value: AudioService.inputVolume
                  muted: AudioService.inputMuted
                  icon: "󰍬"
                  mutedIcon: "󰍭"
                  onSliderMoved: (v) => AudioService.setVolume("@DEFAULT_AUDIO_SOURCE@", v)
                }
              }
            }

          }

          RowLayout {
            Layout.fillWidth: true; spacing: Colors.spacingM
            opacity: root.showContent ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            Rectangle {
              Layout.fillWidth: true; height: 60; color: Colors.bgWidget; radius: Colors.radiusSmall; border.color: Colors.border; border.width: 1
              Column { anchors.centerIn: parent; spacing: 2
                Text { text: "CPU TEMP"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
                Text { text: SystemStatus.cpuTemp; color: Colors.primary; font.pixelSize: Colors.fontSizeLarge; font.weight: Font.Bold }
              }
            }
            Rectangle {
              Layout.fillWidth: true; height: 60; color: Colors.bgWidget; radius: Colors.radiusSmall; border.color: Colors.border; border.width: 1
              Column { anchors.centerIn: parent; spacing: 2
                Text { text: "GPU TEMP"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
                Text { text: SystemStatus.gpuTemp; color: Colors.accent; font.pixelSize: Colors.fontSizeLarge; font.weight: Font.Bold }
              }
            }
          }

          SystemGraphs { opacity: root.showContent ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 650; easing.type: Easing.OutCubic } } }
          ProcessWidget { opacity: root.showContent ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } } }
          NetworkGraphs { opacity: root.showContent ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 750; easing.type: Easing.OutCubic } } }
          DiskWidget { opacity: root.showContent ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } } }
          GPUWidget { opacity: root.showContent ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 850; easing.type: Easing.OutCubic } } }
          UpdateWidget { opacity: root.showContent ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } } }
          ScratchpadWidget { opacity: root.showContent ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 950; easing.type: Easing.OutCubic } } }

        }
      }

      RowLayout {
        Layout.fillWidth: true; spacing: 10
        Repeater {
          model: [
            { icon: "󰐥", cmd: ["systemctl", "poweroff"], confirm: true },
            { icon: "󰑐", cmd: ["systemctl", "reboot"], confirm: true },
            { icon: "󰌾", cmd: CompositorAdapter.lockCommand(), confirm: false }
          ]
          delegate: Rectangle {
            required property var modelData
            required property int index
            Layout.fillWidth: true; height: 40
            color: root.pendingPowerIndex === index ? Colors.error : Colors.surface
            radius: Colors.radiusXS
            Behavior on color { ColorAnimation { duration: 160 } }

            Text {
              anchors.centerIn: parent
              text: root.pendingPowerIndex === index ? "Confirm?" : modelData.icon
              color: root.pendingPowerIndex === index ? Colors.background : Colors.text
              font.family: root.pendingPowerIndex === index ? undefined : Colors.fontMono
              font.pixelSize: root.pendingPowerIndex === index ? Colors.fontSizeSmall : Colors.fontSizeXL
              font.weight: root.pendingPowerIndex === index ? Font.Bold : Font.Normal
            }

            SharedWidgets.StateLayer {
              id: powerStateLayer
              hovered: powerHover.containsMouse
              pressed: powerHover.pressed
            }

            MouseArea {
              id: powerHover
              anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: (mouse) => {
                powerStateLayer.burst(mouse.x, mouse.y);
                if (!modelData.confirm) {
                  // Lock doesn't need confirmation
                  Quickshell.execDetached(modelData.cmd);
                  return;
                }
                if (root.pendingPowerIndex === index) {
                  Quickshell.execDetached(modelData.cmd);
                  root.pendingPowerCmd = null;
                  root.pendingPowerIndex = -1;
                  powerConfirmTimer.stop();
                } else {
                  root.pendingPowerCmd = modelData.cmd;
                  root.pendingPowerIndex = index;
                  powerConfirmTimer.restart();
                }
              }
            }
          }
        }
      }
    }
  }
}
