import QtQuick
import Quickshell
import Quickshell.Wayland
import "../bar"
import "../menu"
import "../services"
import "../widgets"

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
                                onSurfaceRequested: (surfaceId, context) => root.shellRoot.toggleSurface(surfaceId, context)
                                onContextMenuRequested: (actions, rect) => barContextPopup.show(actions, rect, barWindow.barPosition, barWindow)
                            }

                            BluetoothMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("bluetoothMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("bluetoothMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("bluetoothMenu", height)
                                wantVisible: barWindow.popupVisible("bluetoothMenu")
                                onCloseRequested: root.shellRoot.closeSurface("bluetoothMenu")
                            }

                            AudioMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("audioMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("audioMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("audioMenu", height)
                                wantVisible: barWindow.popupVisible("audioMenu")
                                onCloseRequested: root.shellRoot.closeSurface("audioMenu")
                            }

                            NetworkMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("networkMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("networkMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("networkMenu", height)
                                wantVisible: barWindow.popupVisible("networkMenu")
                                onCloseRequested: root.shellRoot.closeSurface("networkMenu")
                            }

                            VpnMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("vpnMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("vpnMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("vpnMenu", height)
                                wantVisible: barWindow.popupVisible("vpnMenu")
                                onCloseRequested: root.shellRoot.closeSurface("vpnMenu")
                            }

                            ClipboardMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("clipboardMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("clipboardMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("clipboardMenu", height)
                                wantVisible: barWindow.popupVisible("clipboardMenu")
                                onCloseRequested: root.shellRoot.closeSurface("clipboardMenu")
                            }

                            RecordingMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("recordingMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("recordingMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("recordingMenu", height)
                                wantVisible: barWindow.popupVisible("recordingMenu")
                                onCloseRequested: root.shellRoot.closeSurface("recordingMenu")
                            }

                            PrivacyMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("privacyMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("privacyMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("privacyMenu", height)
                                wantVisible: barWindow.popupVisible("privacyMenu")
                                onCloseRequested: root.shellRoot.closeSurface("privacyMenu")
                            }

                            MusicMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("musicMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("musicMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("musicMenu", height)
                                wantVisible: barWindow.popupVisible("musicMenu")
                                onCloseRequested: root.shellRoot.closeSurface("musicMenu")
                            }

                            BatteryMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("batteryMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("batteryMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("batteryMenu", height)
                                wantVisible: barWindow.popupVisible("batteryMenu")
                                onCloseRequested: root.shellRoot.closeSurface("batteryMenu")
                            }

                            WeatherMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("weatherMenu")
                                implicitHeight: Math.min(600, root.shellRoot.popupMaxHeight((barWindow.screen && barWindow.screen.height) ? barWindow.screen.height : barWindow.height))
                                anchor.rect.x: barWindow.popupAnchorXFor("weatherMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("weatherMenu", implicitHeight)
                                wantVisible: barWindow.popupVisible("weatherMenu")
                                onCloseRequested: root.shellRoot.closeSurface("weatherMenu")
                            }

                            SshMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("sshMenu")
                                implicitHeight: Math.min(620, root.shellRoot.popupMaxHeight((barWindow.screen && barWindow.screen.height) ? barWindow.screen.height : barWindow.height))
                                anchor.rect.x: barWindow.popupAnchorXFor("sshMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("sshMenu", implicitHeight)
                                wantVisible: barWindow.popupVisible("sshMenu")
                                surfaceContext: barWindow.surfaceContext("sshMenu")
                                onCloseRequested: root.shellRoot.closeSurface("sshMenu")
                            }

                            DateTimeMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("dateTimeMenu")
                                implicitHeight: Math.min(560, root.shellRoot.popupMaxHeight((barWindow.screen && barWindow.screen.height) ? barWindow.screen.height : barWindow.height))
                                anchor.rect.x: barWindow.popupAnchorXFor("dateTimeMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("dateTimeMenu", implicitHeight)
                                wantVisible: barWindow.popupVisible("dateTimeMenu")
                                onCloseRequested: root.shellRoot.closeSurface("dateTimeMenu")
                            }

                            SystemStatsMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("systemStatsMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("systemStatsMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("systemStatsMenu", height)
                                wantVisible: barWindow.popupVisible("systemStatsMenu")
                                onCloseRequested: root.shellRoot.closeSurface("systemStatsMenu")
                            }

                            PrinterMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("printerMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("printerMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("printerMenu", height)
                                wantVisible: barWindow.popupVisible("printerMenu")
                                onCloseRequested: root.shellRoot.closeSurface("printerMenu")
                            }

                            ScreenshotMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("screenshotMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("screenshotMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("screenshotMenu", height)
                                wantVisible: barWindow.popupVisible("screenshotMenu")
                                onCloseRequested: root.shellRoot.closeSurface("screenshotMenu")
                            }

                            CavaPopup {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("cavaPopup")
                                anchor.rect.x: barWindow.popupAnchorXFor("cavaPopup", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("cavaPopup", height)
                                wantVisible: barWindow.popupVisible("cavaPopup")
                                cavaData: panel.fullCavaData || ""
                                onCloseRequested: root.shellRoot.closeSurface("cavaPopup")
                            }
                        }
                    }
                }
            }
        }
    }
}
