import QtQuick
import Quickshell
import Quickshell.Wayland
import "."
import "../features/background"
import "../features/desktop"
import "../features/dock"
import "../services"
import "../shared"

Item {
    id: root
    property bool showBorders: false
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

                WallpaperLayer {
                    id: wallpaperLayer
                    visible: Config.wallpaperUseShellRenderer
                    transitionType: Config.wallpaperTransitionType
                    transitionDuration: Config.wallpaperTransitionDuration

                    // Connect to WallpaperService signals
                    Connections {
                        target: WallpaperService
                        function onWallpaperApplied(imagePath, monitorName) {
                            // Apply if this is for our monitor or for all monitors
                            var screenName = modelData.name || "";
                            if (monitorName === "" || monitorName === screenName) {
                                wallpaperLayer.showSolid = false;
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

    Variants {
        model: Quickshell.screens

        delegate: Component {
            ToastOverlay {
                required property ShellScreen modelData
                screenModel: modelData
            }
        }
    }

    Corners {
        id: screenCorners
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            ScreenBorder {
                required property ShellScreen modelData
                screen: modelData
                visible: root.showBorders
            }
        }
    }
}
