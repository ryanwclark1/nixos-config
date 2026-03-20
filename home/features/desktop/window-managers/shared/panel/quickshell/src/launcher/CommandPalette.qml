import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../shared"
import "../services"
import "../widgets" as SharedWidgets
import "LauncherEntryRegistry.js" as EntryRegistry

PanelWindow {
    id: root

    property bool showContent: false
    property string searchQuery: ""
    property int selectedIndex: 0
    signal closeRequested

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: showContent ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:command-palette"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"
    visible: showContent || fadeAnim.running

    readonly property var allActions: EntryRegistry.buildCommandPaletteActions({
        openDashboard: () => { Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "openTab", "dashboard"]); },
        openSettings: () => { Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "open"]); },
        openNotifications: () => { Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "openSurface", "notifCenter"]); },
        openControlCenter: () => { Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "openSurface", "controlCenter"]); },
        openNetworkControls: () => { Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "openSurface", "networkMenu"]); },
        openAudioControls: () => { Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "openSurface", "audioMenu"]); },
        openVpnControls: () => { Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "openSurface", "vpnMenu"]); },
        openPowerMenu: () => { Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "openSurface", "powerMenu"]); },
        openScreenshotMenu: () => { Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "openSurface", "screenshotMenu"]); },
        openAiChat: () => { Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "openSurface", "aiChat"]); },
        toggleEcoMode: () => { Config.autoEcoMode = !Config.autoEcoMode; },
        toggleDesktopEditMode: () => { Config.desktopEditMode = !Config.desktopEditMode; },
        toggleDynamicTheme: () => { Config.useDynamicTheming = !Config.useDynamicTheming; },
        reloadShell: () => { Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "reloadConfig"]); }
    })

    readonly property var filteredActions: {
        if (!searchQuery) return allActions;
        var q = searchQuery.toLowerCase();
        return allActions.filter(a => {
            var label = String(a.label || "").toLowerCase();
            var category = String(a.category || "").toLowerCase();
            var description = String(a.description || "").toLowerCase();
            var keywords = String(a.keywords || "").toLowerCase();
            return label.includes(q) || category.includes(q) || description.includes(q) || keywords.includes(q);
        });
    }

    onFilteredActionsChanged: selectedIndex = 0

    function executeSelected() {
        if (filteredActions.length > 0 && selectedIndex >= 0 && selectedIndex < filteredActions.length) {
            var a = filteredActions[selectedIndex];
            a.action();
            root.closeRequested();
        }
    }

    // Backdrop
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
        Rectangle {
            anchors.fill: parent
            color: Colors.withAlpha(Colors.background, Config.settingsBackdropOpacity)
            opacity: root.showContent ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { id: fadeAnim; duration: Colors.durationNormal } }
        }
    }

    SharedWidgets.ElasticNumber {
        id: _elasticScale
        target: root.showContent ? 1.0 : 0.95
        fastDuration: Colors.durationSnap
        slowDuration: Colors.durationSlow
        fastWeight: 0.45
    }

    SharedWidgets.ThemedContainer {
        id: paletteBox
        variant: "card"
        radius: Colors.radiusLarge
        width: 680
        height: Math.min(500, contentCol.implicitHeight + Colors.paddingLarge * 2)
        anchors.centerIn: parent
        clip: true

        opacity: root.showContent ? 1.0 : 0.0
        scale: _elasticScale.value
        Behavior on opacity { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: Colors.paddingLarge
            spacing: Colors.spacingL

            // Search Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingM

                Text {
                    text: "󰍉"
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXL
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    focus: root.showContent
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeLarge
                    font.weight: Font.Medium
                    property string placeholder: "Type a shell action..."
                    
                    Text {
                        text: parent.placeholder
                        visible: !parent.text && !parent.activeFocus
                        color: Colors.textDisabled
                        font: parent.font
                    }

                    onTextChanged: root.searchQuery = text

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            root.closeRequested();
                        } else if (event.key === Qt.Key_Down) {
                            if (root.filteredActions.length > 0)
                                root.selectedIndex = (root.selectedIndex + 1) % root.filteredActions.length;
                        } else if (event.key === Qt.Key_Up) {
                            if (root.filteredActions.length > 0)
                                root.selectedIndex = (root.selectedIndex - 1 + root.filteredActions.length) % root.filteredActions.length;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.executeSelected();
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.border
            }

            // Results
            ListView {
                id: resultsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.filteredActions
                clip: true
                spacing: Colors.spacingXS
                currentIndex: root.selectedIndex

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: resultsList.width
                    height: modelData.description ? 58 : 48
                    radius: Colors.radiusMedium
                    color: root.selectedIndex === index ? Colors.primarySubtle : "transparent"
                    border.color: root.selectedIndex === index ? Colors.withAlpha(Colors.primary, 0.3) : "transparent"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Colors.spacingM
                        anchors.rightMargin: Colors.spacingM
                        spacing: Colors.spacingM

                        Text {
                            text: modelData.icon
                            color: root.selectedIndex === index ? Colors.primary : Colors.textSecondary
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeLarge
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: modelData.label
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                font.weight: root.selectedIndex === index ? Font.Bold : Font.Normal
                                Layout.fillWidth: true
                            }

                            Text {
                                visible: !!modelData.description
                                text: modelData.description || ""
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: modelData.category
                            color: Colors.textDisabled
                            font.pixelSize: Colors.fontSizeXXS
                            font.weight: Font.Black
                            font.capitalization: Font.AllUppercase
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selectedIndex = index
                        onClicked: root.executeSelected()
                    }
                }
            }
        }
    }

    onShowContentChanged: {
        if (showContent) {
            searchInput.text = "";
            searchInput.forceActiveFocus();
        }
    }
}
