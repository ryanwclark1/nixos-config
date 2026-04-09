import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import "."
import "../../shared"
import "../../services"

Scope {
  id: root
  readonly property int _startupSuppressMs: 2000

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
  property double _lastCriticalOsdAt: 0
  property string _lastCriticalSummaryShown: ""

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
    if (osdType === "critical") return 1.0;
    if (osdType === "brightness") return SystemStatus.brightness;
    if (osdType === "kbdbrightness") return displayKbdBrightness;
    if (osdType === "mic") return displaySourceVolume;
    if (osdType === "capslock") return capslockState ? 1.0 : 0.0;
    if (osdType === "numlock") return numlockState ? 1.0 : 0.0;
    if (osdType === "scrolllock") return scrolllockState ? 1.0 : 0.0;
    return displaySinkVolume;
  }

  readonly property bool isLockKey: osdType === "capslock" || osdType === "numlock" || osdType === "scrolllock"
  readonly property bool isCriticalAlert: osdType === "critical"

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
    if (osdType === "critical") return "warning.svg";
    if (osdType === "capslock") return capslockState ? "keyboard-shift-filled.svg" : "keyboard-shift.svg";
    if (osdType === "numlock") return numlockState ? "number-symbol.svg" : "number-symbol.svg";
    if (osdType === "scrolllock") return scrolllockState ? "scroll-vertical.svg" : "scroll-vertical.svg";
    if (osdType === "brightness") return "brightness-high.svg";
    if (osdType === "kbdbrightness") return "keyboard.svg";
    if (osdType === "mic") return displaySourceMuted ? "mic-off.svg" : "mic.svg";
    if (osdType === "volume") return displaySinkMuted ? "speaker-mute.svg" : "speaker.svg";
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
  readonly property string location: isCriticalAlert ? "center" : Config.osdPosition
  readonly property bool posTop: location === "top" || location.indexOf("top") === 0
  readonly property bool posBottom: location === "bottom" || location.indexOf("bottom") === 0
  readonly property bool posLeft: location.indexOf("left") !== -1
  readonly property bool posRight: location.indexOf("right") !== -1
  readonly property bool posVCenter: location === "center"
  readonly property bool posHCenter: location === "center" || location.indexOf("center") !== -1 || (!posLeft && !posRight && (posTop || posBottom))

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

  function showCriticalOsdIfNeeded() {
    if (!startupComplete || !SystemStatus.isCritical)
      return;

    var summary = String(SystemStatus.criticalSummary || "");
    var now = Date.now();
    var cooldownElapsed = root._lastCriticalOsdAt <= 0
      || (now - root._lastCriticalOsdAt) >= Math.max(0, Config.osdCriticalCooldownMs);
    var summaryChanged = summary !== root._lastCriticalSummaryShown;

    if (!summaryChanged && !cooldownElapsed)
      return;

    root._lastCriticalSummaryShown = summary;
    root._lastCriticalOsdAt = now;
    showOsd("critical");
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
      if (SystemStatus.isCritical)
        root.showCriticalOsdIfNeeded();
    }
    function onCriticalSummaryChanged() {
      if (SystemStatus.isCritical)
        root.showCriticalOsdIfNeeded();
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
    interval: root._startupSuppressMs
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
        readonly property int usableWidth: Math.max(0, screen.width - edgeMargins.left - edgeMargins.right)
        readonly property int usableHeight: Math.max(0, screen.height - edgeMargins.top - edgeMargins.bottom)

        // Delayed unmap: stay mapped while exit animations run.
        // Keep this compositor-agnostic; OSD is safe to render on all screens.
        property bool _wantVisible: root.shouldShowOsd
        visible: osdWindow._wantVisible || osdFadeAnim.running || osdScaleAnim.running

        // --- 9-position anchoring ---
        anchors.top: root.posTop || root.posVCenter
        anchors.bottom: root.posBottom
        anchors.left: root.posLeft || root.posHCenter
        anchors.right: root.posRight

        // Bar-aware margins: offset OSD when bar is at same edge
        margins.top: {
          if (root.posVCenter) return edgeMargins.top + Math.max(0, (usableHeight - implicitHeight) / 2);
          if (!root.posTop) return 0;
          return edgeMargins.top;
        }
        margins.bottom: {
          return root.posBottom ? edgeMargins.bottom : 0;
        }
        margins.left: {
          if (root.posHCenter) return edgeMargins.left + Math.max(0, (usableWidth - implicitWidth) / 2);
          if (root.posLeft) return edgeMargins.left;
          return 0;
        }
        margins.right: {
          return root.posRight ? edgeMargins.right : 0;
        }

        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-osd"

        // Size depends on style
        implicitWidth: Math.max(1, root.isCriticalAlert ? criticalWidth : (Config.osdStyle === "pill" ? pillWidth : Config.osdSize))
        implicitHeight: Math.max(1, root.isCriticalAlert ? criticalHeight : (Config.osdStyle === "pill" ? pillHeight : Config.osdSize))

        readonly property int pillWidth: 280
        readonly property int pillHeight: 56
        readonly property int criticalWidth: 320
        readonly property int criticalHeight: 148

        mask: Region {
          item: content
        }

        Rectangle {
          id: content
          anchors.fill: parent
          radius: root.isCriticalAlert ? Appearance.radiusLarge : (Config.osdStyle === "pill" ? height / 2 : 28)
          color: Colors.cardSurface
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
            Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
          }

          Loader {
            active: root.isCriticalAlert
            anchors.fill: parent
            sourceComponent: Component {
              OsdCriticalAlert {
                osdIcon: root.osdIcon
                osdColor: root.osdColor
                osdLabel: root.osdLabel
              }
            }
          }

          // Circular style (original)
          Loader {
            active: !root.isCriticalAlert && Config.osdStyle === "circular"
            anchors.fill: parent
            sourceComponent: Component {
              OsdCircularGauge {
                currentValue: root.currentValue
                osdColor: root.osdColor
                osdIcon: root.osdIcon
                osdLabel: root.osdLabel
                osdType: root.osdType
              }
            }
          }

          // Pill style (horizontal progress bar)
          Loader {
            id: pillLoader
            active: !root.isCriticalAlert && Config.osdStyle === "pill"
            anchors.fill: parent
            sourceComponent: Component {
              OsdPill {
                currentValue: root.currentValue
                maxValue: root.maxValue
                osdColor: root.osdColor
                osdIcon: root.osdIcon
                osdLabel: root.osdLabel
                osdType: root.osdType
                isLockKey: root.isLockKey
              }
            }
          }

          Connections {
            target: root
            enabled: pillLoader.item !== null
            function onOsdShown() { if (pillLoader.item) pillLoader.item.triggerPulse(); }
          }
        }
      }
    }
  }
}
