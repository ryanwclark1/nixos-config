import QtQuick
import Quickshell
import Quickshell.Wayland
import "../features/bar"
import "../features/audio"
import "../features/clipboard"
import "../features/media"
import "../features/network"
import "../features/power"
import "../features/screenshot"
import "../features/ssh"
import "../features/status"
import "../features/system/surfaces"
import "../features/time"
import "../services"

Item {
    id: root

    required property QtObject shellRoot
    required property QtObject surfaceService
    required property var notifManager

    BarContextPopup {
        id: barContextPopup
    }

    Connections {
        target: root.surfaceService
        function onActiveSurfaceIdChanged() { barContextPopup.close(); }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Item {
                id: screenBars
                required property ShellScreen modelData
                property var bars: Config.barsForScreen(modelData)

                Variants {
                    model: screenBars.bars

                    delegate: Component {
                        PanelWindow {
                            id: barWindow
                            required property var modelData
                            readonly property var barConfig: modelData
                            readonly property string barPosition: (barConfig && barConfig.position) ? barConfig.position : "top"
                            readonly property string barId: (barConfig && barConfig.id) ? barConfig.id : ""
                            readonly property bool vertical: Config.isVerticalBar(barPosition)
                            readonly property int marginValue: Config.floatingInset(barConfig)
                            readonly property int thicknessValue: Config.barThickness(barConfig)
                            screen: screenBars.modelData

                            function surfaceContext(surfaceId) {
                                return root.shellRoot.surfaceContextFor(surfaceId, screenBars.modelData, barId);
                            }

                            function popupVisible(surfaceId) {
                                return root.shellRoot.isSurfacePresentedOnBar(surfaceId, screenBars.modelData, barId);
                            }

                            function popupPreferredEdge(surfaceId) {
                                var context = surfaceContext(surfaceId);
                                return context ? context.position : barPosition;
                            }

                            function popupAnchorXFor(surfaceId, popupWidth) {
                                return root.shellRoot.popupAnchorX(surfaceContext(surfaceId), popupWidth, screen ? screen.width : width);
                            }

                            function popupAnchorYFor(surfaceId, popupHeight) {
                                return root.shellRoot.popupAnchorY(surfaceContext(surfaceId), popupHeight, screen ? screen.height : height);
                            }

                            function wirePopup(popup, surfaceId) {
                                popup.anchor.window = barWindow;
                                popup.preferredEdge = Qt.binding(function() {
                                    return barWindow.popupPreferredEdge(surfaceId);
                                });
                                popup.anchor.rect.x = Qt.binding(function() {
                                    return barWindow.popupAnchorXFor(surfaceId, popup.width);
                                });
                                popup.anchor.rect.y = Qt.binding(function() {
                                    return barWindow.popupAnchorYFor(surfaceId, popup.height);
                                });
                                popup.wantVisible = Qt.binding(function() {
                                    return barWindow.popupVisible(surfaceId);
                                });
                                popup.closeRequested.connect(function() {
                                    root.shellRoot.closeSurface(surfaceId);
                                });
                            }

                            anchors {
                                top: barPosition === "top" || barPosition === "left" || barPosition === "right"
                                bottom: barPosition === "bottom" || barPosition === "left" || barPosition === "right"
                                left: barPosition === "left" || barPosition === "top" || barPosition === "bottom"
                                right: barPosition === "right" || barPosition === "top" || barPosition === "bottom"
                            }
                            margins {
                                top: (barPosition === "top" || (vertical && barConfig && barConfig.floating)) ? marginValue : 0
                                bottom: (barPosition === "bottom" || (vertical && barConfig && barConfig.floating)) ? marginValue : 0
                                left: (barPosition === "left" || (!vertical && barConfig && barConfig.floating)) ? marginValue : 0
                                right: (barPosition === "right" || (!vertical && barConfig && barConfig.floating)) ? marginValue : 0
                            }

                            color: "transparent"
                            implicitWidth: vertical ? panel.implicitWidth : 0
                            implicitHeight: vertical ? 0 : panel.implicitHeight

                            WlrLayershell.layer: WlrLayer.Top
                            WlrLayershell.namespace: "quickshell-bar-" + barId
                            WlrLayershell.exclusiveZone: panel.isAutoHidden ? 0 : (vertical ? width + marginValue : height + marginValue)
                            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                            Panel {
                                id: panel
                                anchors.fill: parent
                                manager: root.notifManager
                                anchorWindow: barWindow
                                screenRef: screenBars.modelData
                                barConfig: barWindow.barConfig
                                activeSurfaceId: root.shellRoot.barOwnsSurface(root.shellRoot.activeSurfaceContext, screenBars.modelData, barWindow.barId) ? root.shellRoot.activeSurfaceId : ""
                                activeSurfaceContext: root.shellRoot.activeSurfaceContext
                                onSurfaceRequested: (surfaceId, context) => root.shellRoot.toggleSurface(surfaceId, context)
                                onContextMenuRequested: (actions, rect) => barContextPopup.show(actions, rect, barWindow.barPosition, barWindow)
                            }

                            BluetoothMenu { Component.onCompleted: barWindow.wirePopup(this, "bluetoothMenu") }
                            AudioMenu { Component.onCompleted: barWindow.wirePopup(this, "audioMenu") }
                            NetworkMenu { Component.onCompleted: barWindow.wirePopup(this, "networkMenu") }
                            VpnMenu { Component.onCompleted: barWindow.wirePopup(this, "vpnMenu") }
                            ClipboardMenu { Component.onCompleted: barWindow.wirePopup(this, "clipboardMenu") }
                            RecordingMenu { Component.onCompleted: barWindow.wirePopup(this, "recordingMenu") }
                            PrivacyMenu { Component.onCompleted: barWindow.wirePopup(this, "privacyMenu") }
                            MusicMenu { Component.onCompleted: barWindow.wirePopup(this, "musicMenu") }
                            BatteryMenu { Component.onCompleted: barWindow.wirePopup(this, "batteryMenu") }
                            SystemStatsMenu { Component.onCompleted: barWindow.wirePopup(this, "systemStatsMenu") }
                            PrinterMenu { Component.onCompleted: barWindow.wirePopup(this, "printerMenu") }
                            ScreenshotMenu { Component.onCompleted: barWindow.wirePopup(this, "screenshotMenu") }

                            WeatherMenu {
                                implicitHeight: Math.min(600, root.shellRoot.popupMaxHeight((barWindow.screen && barWindow.screen.height) ? barWindow.screen.height : barWindow.height))
                                Component.onCompleted: barWindow.wirePopup(this, "weatherMenu")
                            }
                            SshMenu {
                                implicitHeight: Math.min(620, root.shellRoot.popupMaxHeight((barWindow.screen && barWindow.screen.height) ? barWindow.screen.height : barWindow.height))
                                surfaceContext: barWindow.surfaceContext("sshMenu")
                                Component.onCompleted: barWindow.wirePopup(this, "sshMenu")
                            }
                            DateTimeMenu {
                                implicitHeight: Math.min(560, root.shellRoot.popupMaxHeight((barWindow.screen && barWindow.screen.height) ? barWindow.screen.height : barWindow.height))
                                Component.onCompleted: barWindow.wirePopup(this, "dateTimeMenu")
                            }
                            CavaPopup {
                                cavaData: panel.fullCavaData || ""
                                Component.onCompleted: barWindow.wirePopup(this, "cavaPopup")
                            }
                        }
                    }
                }
            }
        }
    }
}
