import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import Quickshell.Wayland
import "../modules"
import "../services"

Scope {
  id: root

  PwObjectTracker {
    objects: [ Pipewire.defaultAudioSink, Pipewire.defaultAudioSource ]
  }

  // --- State ---
  property bool shouldShowOsd: false
  property string osdType: "volume"
  property bool capslockState: false
  property bool numlockState: false
  property bool scrolllockState: false
  property bool suppressPipewireOsd: true
  property bool startupComplete: false
  signal osdShown()
  property real displaySinkVolume: 0
  property bool displaySinkMuted: false
  property real displaySourceVolume: 0
  property bool displaySourceMuted: false
  property real displayKbdBrightness: 0

  Component.onDestruction: {
    hideTimer.stop();
    if (root.osdType === "brightness") SystemStatus.subscriberCount--;
    if (root.osdType === "kbdbrightness") BrightnessService.subscriberCount--;
  }

  // Pipewire reactive bindings
  property real sinkVolume: {
    var v = Pipewire.defaultAudioSink?.audio?.volume;
    return (v !== undefined && !isNaN(v)) ? (Config.osdOverdrive ? Math.min(v, 1.5) : Colors.clamp01(v)) : 0;
  }
  property bool sinkMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false
  property real sourceVolume: {
    var v = Pipewire.defaultAudioSource?.audio?.volume;
    return (v !== undefined && !isNaN(v)) ? Colors.clamp01(v) : 0;
  }
  property bool sourceMuted: Pipewire.defaultAudioSource?.audio?.muted ?? false

  // --- OSD helpers ---
  readonly property real maxValue: {
    if ((osdType === "volume" || osdType === "mic") && Config.osdOverdrive) return 1.5;
    return 1.0;
  }

  readonly property real currentValue: {
    if (osdType === "brightness") return SystemStatus.brightness;
    if (osdType === "kbdbrightness") return displayKbdBrightness;
    if (osdType === "mic") return displaySourceVolume;
    if (osdType === "capslock") return capslockState ? 1.0 : 0.0;
    if (osdType === "numlock") return numlockState ? 1.0 : 0.0;
    if (osdType === "scrolllock") return scrolllockState ? 1.0 : 0.0;
    return displaySinkVolume;
  }

  readonly property bool isLockKey: osdType === "capslock" || osdType === "numlock" || osdType === "scrolllock"

  // Color lerp helper for smooth gradients between two colors
  function lerpColor(a, b, t) {
    return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1.0);
  }

  readonly property color osdColor: {
    if (osdType === "critical") return Colors.error;
    if (osdType === "capslock") return capslockState ? Colors.primary : Colors.textDisabled;
    if (osdType === "numlock") return numlockState ? Colors.primary : Colors.textDisabled;
    if (osdType === "scrolllock") return scrolllockState ? Colors.primary : Colors.textDisabled;
    if (osdType === "mic" && displaySourceMuted) return Colors.error;
    if (osdType === "volume" && displaySinkMuted) return Colors.error;
    // Overdrive: red when above 100%
    if (osdType === "volume" && Config.osdOverdrive && displaySinkVolume > 1.0) return Colors.error;
    // Volume color interpolation: primary → accent when > 50%
    if (osdType === "volume" && displaySinkVolume > 0.5) {
      var t = Math.min(1.0, (displaySinkVolume - 0.5) * 2.0);
      return lerpColor(Colors.primary, Colors.accent, t);
    }
    return Colors.primary;
  }

  readonly property string osdIcon: {
    if (osdType === "critical") return "󰀪";
    if (osdType === "capslock") return capslockState ? "󰬶" : "󰬵";
    if (osdType === "numlock") return numlockState ? "󰎠" : "󰎡";
    if (osdType === "scrolllock") return scrolllockState ? "󱅮" : "󱅯";
    if (osdType === "brightness") return "󰃠";
    if (osdType === "kbdbrightness") return "󰌌";
    if (osdType === "mic") return displaySourceMuted ? "󰍭" : "󰍬";
    if (osdType === "volume") return displaySinkMuted ? "󰝟" : "󰕾";
    return "";
  }

  readonly property string osdLabel: {
    if (osdType === "critical") return "CRITICAL STATE";
    if (osdType === "capslock") return capslockState ? "CAPS ON" : "CAPS OFF";
    if (osdType === "numlock") return numlockState ? "NUM ON" : "NUM OFF";
    if (osdType === "scrolllock") return scrolllockState ? "SCROLL ON" : "SCROLL OFF";
    if (osdType === "brightness") return Math.round(SystemStatus.brightness * 100) + "%";
    if (osdType === "kbdbrightness") return Math.round(displayKbdBrightness * 100) + "%";
    if (osdType === "mic") return displaySourceMuted ? "MUTED" : Math.round(displaySourceVolume * 100) + "%";
    if (osdType === "volume" && displaySinkMuted) return "MUTED";
    return Math.round(displaySinkVolume * 100) + "%";
  }

  // --- Position helpers ---
  readonly property string location: Config.osdPosition
  readonly property bool posTop: location === "top" || location.indexOf("top") === 0
  readonly property bool posBottom: location === "bottom" || location.indexOf("bottom") === 0
  readonly property bool posLeft: location.indexOf("left") !== -1
  readonly property bool posRight: location.indexOf("right") !== -1
  readonly property bool posCenter: location === "center"

  function showOsd(type) {
    if (!startupComplete) return;
    // Unsubscribe previous brightness subscription if switching OSD type
    if (root.osdType === "brightness" && type !== "brightness") SystemStatus.subscriberCount--;
    if (root.osdType === "kbdbrightness" && type !== "kbdbrightness") BrightnessService.subscriberCount--;
    root.osdType = type;
    root.shouldShowOsd = true;
    if (type === "brightness") SystemStatus.subscriberCount++;
    if (type === "kbdbrightness") BrightnessService.subscriberCount++;
    hideTimer.restart();
    root.osdShown();
  }

  function showAudioOsd(percent, muted, volumeProp, mutedProp, type) {
    var parsed = parseFloat(percent);
    if (!isNaN(parsed)) {
      var maxPct = (Config.osdOverdrive && (type === "volume")) ? 150 : 100;
      root[volumeProp] = Math.min(parsed / 100.0, maxPct / 100.0);
    }
    if (muted === "true" || muted === "false") root[mutedProp] = (muted === "true");
    showOsd(type);
  }

  IpcHandler {
    target: "Osd"

    function showVolume(percent: string, muted: string) {
      root.showAudioOsd(percent, muted, "displaySinkVolume", "displaySinkMuted", "volume");
    }

    function showMic(percent: string, muted: string) {
      root.showAudioOsd(percent, muted, "displaySourceVolume", "displaySourceMuted", "mic");
    }

    function showCapslock(state: string) {
      root.capslockState = (state === "on");
      root.showOsd("capslock");
    }

    function showNumlock(state: string) {
      root.numlockState = (state === "on");
      root.showOsd("numlock");
    }

    function showScrolllock(state: string) {
      root.scrolllockState = (state === "on");
      root.showOsd("scrolllock");
    }

    function showBrightness(percent: string) {
      var val = parseFloat(percent);
      if (isNaN(val)) val = 0;
      SystemStatus.brightness = val / 100.0;
      root.showOsd("brightness");
    }

    function showKbdBrightness(percent: string) {
      var val = parseFloat(percent);
      if (isNaN(val)) val = 0;
      root.displayKbdBrightness = val / 100.0;
      root.showOsd("kbdbrightness");
    }
  }

  function onPipewireChanged(displayProp, value, type) {
    root[displayProp] = value;
    if (!root.suppressPipewireOsd) showOsd(type);
  }

  onSinkVolumeChanged: onPipewireChanged("displaySinkVolume", sinkVolume, "volume")
  onSinkMutedChanged: onPipewireChanged("displaySinkMuted", sinkMuted, "volume")
  onSourceVolumeChanged: onPipewireChanged("displaySourceVolume", sourceVolume, "mic")
  onSourceMutedChanged: onPipewireChanged("displaySourceMuted", sourceMuted, "mic")

  Connections {
    target: SystemStatus
    function onIsCriticalChanged() {
      if (SystemStatus.isCritical) showOsd("critical");
    }
  }

  Component.onCompleted: {
    root.displaySinkVolume = root.sinkVolume;
    root.displaySinkMuted = root.sinkMuted;
    root.displaySourceVolume = root.sourceVolume;
    root.displaySourceMuted = root.sourceMuted;
  }

  // Startup suppression: 2s gate to prevent spurious OSD on shell init
  Timer {
    id: startupTimer
    interval: 2000
    running: true
    onTriggered: {
      root.suppressPipewireOsd = false;
      root.startupComplete = true;
    }
  }

  Timer {
    id: hideTimer
    interval: Config.osdDuration
    onTriggered: {
      if (root.osdType === "brightness") SystemStatus.subscriberCount--;
      if (root.osdType === "kbdbrightness") BrightnessService.subscriberCount--;
      root.shouldShowOsd = false;
    }
  }

  // Per-screen OSD windows
  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: osdWindow
        required property ShellScreen modelData
        screen: modelData
        readonly property var edgeMargins: Config.reservedEdgesForScreen(modelData, "")

        // Delayed unmap: stay mapped while exit animations run.
        // Keep this compositor-agnostic; OSD is safe to render on all screens.
        property bool _wantVisible: root.shouldShowOsd
        visible: _wantVisible || osdFadeAnim.running || osdScaleAnim.running

        // --- 9-position anchoring ---
        anchors.top: root.posTop || root.posCenter
        anchors.bottom: root.posBottom
        anchors.left: root.posLeft || root.posCenter
        anchors.right: root.posRight

        // Bar-aware margins: offset OSD when bar is at same edge
        margins.top: {
          if (root.posCenter)
            return screen ? Math.max(edgeMargins.top, edgeMargins.top + ((screen.height - edgeMargins.top - edgeMargins.bottom - implicitHeight) / 2)) : 0;
          if (!root.posTop) return 0;
          return edgeMargins.top;
        }
        margins.bottom: root.posBottom ? edgeMargins.bottom : 0
        margins.left: {
          if (root.posCenter)
            return screen ? Math.max(edgeMargins.left, edgeMargins.left + ((screen.width - edgeMargins.left - edgeMargins.right - implicitWidth) / 2)) : 0;
          if (root.posLeft) return edgeMargins.left;
          // Horizontal center for top/bottom
          if (!root.posLeft && !root.posRight && (root.posTop || root.posBottom))
            return screen ? Math.max(edgeMargins.left, edgeMargins.left + ((screen.width - edgeMargins.left - edgeMargins.right - implicitWidth) / 2)) : 0;
          return 0;
        }
        margins.right: root.posRight ? edgeMargins.right : 0

        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-osd"

        // Size depends on style
        implicitWidth: Config.osdStyle === "pill" ? pillWidth : Config.osdSize
        implicitHeight: Config.osdStyle === "pill" ? pillHeight : Config.osdSize

        readonly property int pillWidth: 280
        readonly property int pillHeight: 56

        mask: Region {
          item: content
        }

        Rectangle {
          id: content
          anchors.fill: parent
          radius: Config.osdStyle === "pill" ? height / 2 : 28
          color: Colors.withAlpha(Colors.surface, 0.85)
          border.color: root.osdColor
          border.width: 2

          gradient: SurfaceGradient {}

          // Inner highlight
          InnerHighlight { highlightOpacity: 0.15 }

          opacity: root.shouldShowOsd ? 1.0 : 0.0
          scale: root.shouldShowOsd ? 1.0 : 0.92
          transform: Translate { y: root.shouldShowOsd ? 0 : 10 }

          // Asymmetric enter/exit: fast-in, slow-out
          Behavior on opacity {
            NumberAnimation {
              id: osdFadeAnim
              duration: root.shouldShowOsd ? 200 : 300
              easing.type: Easing.OutCubic
            }
          }
          Behavior on scale {
            SpringAnimation {
              id: osdScaleAnim
              spring: 4.5
              damping: 0.3
              epsilon: 0.005
            }
          }
          Behavior on transform {
            SpringAnimation {
              spring: 4.0
              damping: 0.35
              epsilon: 0.005
            }
          }

          // Layer during animation for GPU-accelerated compositing
          layer.enabled: osdFadeAnim.running || osdScaleAnim.running

          // Inner ambient glow that brightens with value
          Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            color: Colors.withAlpha(root.osdColor, 0.06 + (root.currentValue / root.maxValue) * 0.08)
            Behavior on color { ColorAnimation { duration: Colors.durationFast } }
          }

          // Circular style (original)
          Loader {
            active: Config.osdStyle === "circular"
            anchors.fill: parent
            sourceComponent: ColumnLayout {
              anchors.fill: parent
              anchors.margins: 18
              spacing: Colors.paddingSmall

              CircularGauge {
                Layout.alignment: Qt.AlignHCenter
                width: 78
                height: 78
                thickness: 6
                value: Math.min(root.currentValue / root.maxValue, 1.0)
                color: root.osdColor
                icon: root.osdIcon
              }

              Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.osdLabel
                color: Colors.text
                font.pixelSize: Colors.fontSizeXL
                font.weight: Font.Black
                font.family: Colors.fontMono
              }

              Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.osdType === "kbdbrightness" ? "KBD BRIGHTNESS" : root.osdType.toUpperCase()
                color: root.osdColor
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Colors.letterSpacingExtraWide
              }
            }
          }

          // Pill style (horizontal progress bar)
          Loader {
            active: Config.osdStyle === "pill"
            anchors.fill: parent
            sourceComponent: RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Colors.spacingL
              anchors.rightMargin: Colors.spacingL
              spacing: Colors.spacingM

              Text {
                id: pillIconText
                text: root.osdIcon
                color: root.osdColor
                font.pixelSize: Colors.fontSizeXL
                font.family: Colors.fontMono
                scale: 1.0

                SequentialAnimation {
                  id: pillIconPulse
                  NumberAnimation { target: pillIconText; property: "scale"; to: 1.22; duration: 80; easing.type: Easing.OutQuad }
                  NumberAnimation { target: pillIconText; property: "scale"; to: 1.0; duration: Colors.durationFast; easing.type: Easing.OutElastic }
                }

                Connections {
                  target: root
                  function onOsdShown() { pillIconPulse.restart(); }
                }
              }

              // Progress track (draggable for volume/brightness)
              Item {
                id: osdTrack
                Layout.fillWidth: true
                Layout.preferredHeight: osdTrackMouse.pressed ? 12 : 6
                Behavior on Layout.preferredHeight { NumberAnimation { duration: Colors.durationSnap; easing.type: Easing.OutCubic } }

                Rectangle {
                  anchors.fill: parent
                  radius: parent.height / 2
                  color: Colors.withAlpha(root.osdColor, 0.2)
                }

                // Tick marks at 25%, 50%, 75%
                Repeater {
                  model: root.isLockKey ? [] : [0.25, 0.50, 0.75]
                  Rectangle {
                    x: osdTrack.width * modelData - 1
                    y: -1; width: 2; height: osdTrack.height + 2
                    radius: 1
                    color: Colors.withAlpha(Colors.text, 0.2)
                    visible: (root.currentValue / root.maxValue) < modelData
                  }
                }

                Rectangle {
                  width: {
                    if (root.isLockKey) return root.currentValue * parent.width;
                    return parent.width * Math.min(1.0, root.currentValue / root.maxValue);
                  }
                  height: parent.height
                  radius: parent.height / 2
                  color: root.osdColor

                  Behavior on width { NumberAnimation { duration: Colors.durationSnap; easing.type: Easing.OutCubic } }
                }

                // Overdrive marker at 100% when max > 1.0
                Rectangle {
                  visible: root.maxValue > 1.0 && !root.isLockKey
                  x: parent.width * (1.0 / root.maxValue)
                  y: -2
                  width: 2
                  height: parent.height + 4
                  radius: 1
                  color: Colors.withAlpha(Colors.text, 0.4)
                }

                // Drag interaction for volume/brightness adjustment
                MouseArea {
                  id: osdTrackMouse
                  anchors.fill: parent
                  anchors.topMargin: -12
                  anchors.bottomMargin: -12
                  enabled: !root.isLockKey
                  hoverEnabled: true
                  cursorShape: root.isLockKey ? Qt.ArrowCursor : Qt.PointingHandCursor

                  function applyValue(mouseX) {
                    var ratio = Math.max(0, Math.min(1.0, mouseX / osdTrack.width));
                    var value = ratio * root.maxValue;
                    if (root.osdType === "volume") {
                      var pct = Math.round(value * 100);
                      Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", pct + "%"]);
                    } else if (root.osdType === "mic") {
                      var pct = Math.round(value * 100);
                      Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", pct + "%"]);
                    } else if (root.osdType === "brightness") {
                      var pct = Math.round(value * 100);
                      Quickshell.execDetached(["brightnessctl", "set", pct + "%"]);
                    } else if (root.osdType === "kbdbrightness") {
                      BrightnessService.setKbdBrightness(value);
                    }
                    hideTimer.restart();
                  }

                  onPressed: (mouse) => applyValue(mouse.x)
                  onPositionChanged: (mouse) => { if (pressed) applyValue(mouse.x); }
                }
              }

              Text {
                text: root.osdLabel
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.Bold
                font.family: Colors.fontMono
                Layout.minimumWidth: 70
                horizontalAlignment: Text.AlignRight
              }
            }
          }
        }
      }
    }
  }
}
