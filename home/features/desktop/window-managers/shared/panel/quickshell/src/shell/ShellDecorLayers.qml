import QtQuick
import Quickshell
import Quickshell.Wayland
import "."
import "../features/background"
import "../features/desktop"
import "../features/dock"
import "../services"
import "../services/WeatherVisuals.js" as WeatherVisuals
import "../shared"

Item {
    id: root
    property bool startupComplete: false
    readonly property bool _backgroundAutoHidden: Config.backgroundAutoHide && CompositorAdapter.hasFullscreenWindow

    Dock {
        id: dock
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                required property ShellScreen modelData
                screen: modelData

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }
                color: "transparent"
                exclusiveZone: -1
                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                Item {
                    anchors.fill: parent
                    opacity: root.startupComplete ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.durationSlow
                            easing.type: Easing.OutCubic
                        }
                    }

                    Ref { service: WeatherService; active: Config.weatherOverlayEnabled }

                    WallpaperLayer {
                        id: wallpaperLayer
                        visible: Config.wallpaperUseShellRenderer
                        transitionType: Config.wallpaperTransitionType
                        transitionDuration: Config.wallpaperTransitionDuration
                        showVideo: Config.wallpaperVideoEnabled && Config.wallpaperVideoPath !== ""
                        videoSource: showVideo ? "file://" + Config.wallpaperVideoPath : ""

                        // Connect to WallpaperService signals
                        Connections {
                            target: WallpaperService
                            function onWallpaperApplied(imagePath, monitorName, isCycled) {
                                // Apply if this is for our monitor or for all monitors
                                var screenName = modelData.name || "";
                                if (monitorName === "" || monitorName === screenName) {
                                    wallpaperLayer.showSolid = false;
                                    // Use slower transition for auto-cycle
                                    if (isCycled) {
                                        wallpaperLayer.transitionDuration = Math.round(Config.wallpaperTransitionDuration * 1.5);
                                    } else {
                                        wallpaperLayer.transitionDuration = Config.wallpaperTransitionDuration;
                                    }
                                    wallpaperLayer.currentSource = "file://" + imagePath;
                                }
                            }
                            function onSolidColorApplied(colorHex, monitorName) {
                                var screenName = modelData.name || "";
                                if (monitorName === "" || monitorName === screenName) {
                                    wallpaperLayer.showSolid = true;
                                    wallpaperLayer.solidColor = "#" + colorHex.slice(0, 6);
                                }
                            }
                        }

                        // Load initial wallpaper from persisted config
                        Component.onCompleted: {
                            if (!Config.wallpaperUseShellRenderer) return;
                            var screenName = modelData.name || "";
                            var path = WallpaperService.wallpapers[screenName]
                                || WallpaperService.wallpapers["__all__"] || "";
                            if (path) {
                                currentSource = "file://" + path;
                            }
                            // Check if solid color is active
                            var solidHex = WallpaperService.solidColorForMonitor(screenName);
                            if (solidHex) {
                                showSolid = true;
                                solidColor = "#" + solidHex.slice(0, 6);
                            }
                        }
                    }

                    // Weather overlay — animated rain/snow/fog.
                    // Load lazily so disabled weather overlays do not instantiate a ShaderEffect
                    // without a valid shader binding.
                    Loader {
                        anchors.fill: parent
                        active: Config.weatherOverlayEnabled
                        sourceComponent: weatherOverlayComponent
                    }

                    Component {
                        id: weatherOverlayComponent

                        ShaderEffect {
                            id: weatherOverlay
                            anchors.fill: parent
                            visible: _weatherVisual.overlayScene !== "none"
                            layer.enabled: visible

                            readonly property var _weatherVisual: WeatherVisuals.visualForCondition(WeatherService.condition)

                            property real time: 0
                            NumberAnimation on time {
                                from: 0; to: 1000
                                duration: 1000000
                                loops: Animation.Infinite
                                running: weatherOverlay.visible
                            }

                            property real intensity: _weatherVisual.intensity

                            fragmentShader: {
                                if (_weatherVisual.overlayScene === "rain") return _rainShader;
                                if (_weatherVisual.overlayScene === "snow") return _snowShader;
                                if (_weatherVisual.overlayScene === "fog") return _fogShader;
                                return "";
                            }

                            readonly property string _rainShader: "
                                varying highp vec2 qt_TexCoord0;
                                uniform lowp float qt_Opacity;
                                uniform highp float time;
                                uniform highp float intensity;

                                highp float rand(highp vec2 co) {
                                    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
                                }

                                void main() {
                                    highp vec2 uv = qt_TexCoord0;
                                    highp float t = time * 0.5;

                                    // Rain streaks — multiple layers for depth
                                    highp float rain = 0.0;
                                    for (int i = 0; i < 3; i++) {
                                        highp float fi = float(i);
                                        highp float speed = 2.0 + fi * 0.8;
                                        highp float scale = 40.0 + fi * 20.0;
                                        highp vec2 ruv = vec2(uv.x * scale, (uv.y + t * speed) * scale * 0.3);
                                        highp float drop = rand(floor(ruv));
                                        highp float streak = smoothstep(0.97 - intensity * 0.04, 1.0, drop);
                                        rain += streak * (0.15 - fi * 0.03);
                                    }

                                    gl_FragColor = vec4(0.7, 0.75, 0.85, rain * intensity * 0.4) * qt_Opacity;
                                }
                            "

                            readonly property string _snowShader: "
                                varying highp vec2 qt_TexCoord0;
                                uniform lowp float qt_Opacity;
                                uniform highp float time;
                                uniform highp float intensity;

                                highp float rand(highp vec2 co) {
                                    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
                                }

                                void main() {
                                    highp vec2 uv = qt_TexCoord0;
                                    highp float t = time * 0.15;

                                    highp float snow = 0.0;
                                    for (int i = 0; i < 4; i++) {
                                        highp float fi = float(i);
                                        highp float speed = 0.3 + fi * 0.15;
                                        highp float scale = 15.0 + fi * 10.0;
                                        highp float drift = sin(t * (0.5 + fi * 0.3) + uv.y * 3.0) * 0.02;
                                        highp vec2 suv = vec2((uv.x + drift) * scale, (uv.y + t * speed) * scale);
                                        highp float flake = rand(floor(suv));
                                        highp float size = smoothstep(0.96 - intensity * 0.03, 1.0, flake);
                                        snow += size * (0.12 - fi * 0.02);
                                    }

                                    gl_FragColor = vec4(1.0, 1.0, 1.0, snow * intensity * 0.5) * qt_Opacity;
                                }
                            "

                            readonly property string _fogShader: "
                                varying highp vec2 qt_TexCoord0;
                                uniform lowp float qt_Opacity;
                                uniform highp float time;
                                uniform highp float intensity;

                                highp float hash(highp vec2 p) {
                                    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
                                }

                                highp float noise(highp vec2 p) {
                                    highp vec2 i = floor(p);
                                    highp vec2 f = fract(p);
                                    f = f * f * (3.0 - 2.0 * f);
                                    highp float a = hash(i);
                                    highp float b = hash(i + vec2(1.0, 0.0));
                                    highp float c = hash(i + vec2(0.0, 1.0));
                                    highp float d = hash(i + vec2(1.0, 1.0));
                                    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
                                }

                                void main() {
                                    highp vec2 uv = qt_TexCoord0;
                                    highp float t = time * 0.05;

                                    highp float fog = 0.0;
                                    fog += noise(uv * 3.0 + vec2(t, 0.0)) * 0.5;
                                    fog += noise(uv * 6.0 + vec2(-t * 0.7, t * 0.3)) * 0.3;
                                    fog += noise(uv * 12.0 + vec2(t * 0.5, -t * 0.2)) * 0.2;

                                    // Denser at bottom
                                    fog *= (0.5 + uv.y * 0.5);

                                    gl_FragColor = vec4(0.85, 0.87, 0.9, fog * intensity * 0.25) * qt_Opacity;
                                }
                            "

                            Rectangle {
                                anchors.fill: parent
                                visible: weatherOverlay._weatherVisual.flash
                                radius: Math.max(width, height)
                                color: Colors.withAlpha("#ffffff", 0.45)
                                opacity: 0

                                SequentialAnimation on opacity {
                                    running: weatherOverlay.visible && parent.visible
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: Math.round(Appearance.durationAmbient * 1.3) }
                                    NumberAnimation { to: 0.14; duration: Appearance.durationFlash; easing.type: Easing.OutCubic }
                                    NumberAnimation { to: 0.0; duration: Appearance.durationFast; easing.type: Easing.InCubic }
                                    PauseAnimation { duration: Math.round(Appearance.durationAmbient * 0.8) }
                                    NumberAnimation { to: 0.07; duration: Appearance.durationFlash; easing.type: Easing.OutCubic }
                                    NumberAnimation { to: 0.0; duration: Appearance.durationSnap; easing.type: Easing.InCubic }
                                }
                            }
                        }
                    }

                    DesktopWidgets {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.leftMargin: 80
                        anchors.topMargin: 120
                    }

                    Loader {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: parent.height * 0.4
                        visible: Config.backgroundVisualizerEnabled && !root._backgroundAutoHidden
                        sourceComponent: Config.backgroundUseShaderVisualizer ? shaderVisualizerComponent : standardVisualizerComponent
                    }

                    Component {
                        id: standardVisualizerComponent
                        BackgroundVisualizer {}
                    }

                    Component {
                        id: shaderVisualizerComponent
                        BackgroundShaderVisualizer {}
                    }

                    BackgroundClock {
                        visible: Config.backgroundClockEnabled && !root._backgroundAutoHidden
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            ToastOverlay {
                required property ShellScreen modelData
                screenModel: modelData
            }
        }
    }

    ScreenDecor {}

    // Debug log overlay — visible when Config.debug is true
    Loader {
        active: Config.debug
        sourceComponent: Component {
            PanelWindow {
                id: debugLogWindow
                screen: Quickshell.screens[0]
                anchors {
                    bottom: true
                    right: true
                }
                margins.bottom: 60
                margins.right: 16
                implicitWidth: 480
                implicitHeight: 320
                color: "transparent"
                exclusiveZone: 0
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-debug"

                mask: Region { item: debugOverlay }

                LiveLogOverlay {
                    id: debugOverlay
                    anchors.fill: parent
                    title: "Debug Log"
                    command: ["journalctl", "--user", "-u", "quickshell", "-f", "--no-pager", "-o", "short-iso"]
                    running: true
                }

                Connections {
                    target: debugOverlay
                    function onCloseRequested() { Config.debug = false; }
                }
            }
        }
    }
}
