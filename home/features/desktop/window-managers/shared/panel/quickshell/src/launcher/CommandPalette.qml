import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../widgets" as SharedWidgets

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

    readonly property var allActions: [
        { id: "dashboard", label: "Open Dashboard", icon: "󰕮", category: "System", action: () => { Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "openTab", "dashboard"]); } },
        { id: "eco-mode", label: "Toggle Eco Mode", icon: "󰂃", category: "Power", action: () => { Config.autoEcoMode = !Config.autoEcoMode; } },
        { id: "edit-mode", label: "Toggle Desktop Edit Mode", icon: "󰏘", category: "Desktop", action: () => { Config.desktopEditMode = !Config.desktopEditMode; } },
        { id: "dynamic-theme", label: "Toggle Dynamic Theme", icon: "󰏘", category: "Visuals", action: () => { Config.useDynamicTheming = !Config.useDynamicTheming; } },
        { id: "reload", label: "Reload Shell", icon: "󰑓", category: "System", action: () => { Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "reloadConfig"]); } },
        { id: "wallpapers", label: "Change Wallpaper", icon: "󰸉", category: "Visuals", action: () => { Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "openTab", "wallpaper"]); } },
        { id: "settings", label: "Open Settings", icon: "󰒓", category: "System", action: () => { Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "open"]); } },
        { id: "screenshot", label: "Take Screenshot", icon: "󰄀", category: "System", action: () => { Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "openSurface", "screenshotMenu"]); } },
        { id: "ai", label: "Ask AI Assistant", icon: "󰚩", category: "Intelligence", action: () => { Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "openSurface", "aiChat"]); } }
    ]

    readonly property var filteredActions: {
        if (!searchQuery) return allActions;
        var q = searchQuery.toLowerCase();
        return allActions.filter(a => a.label.toLowerCase().includes(q) || a.category.toLowerCase().includes(q));
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

    Rectangle {
        id: paletteBox
        width: 600
        height: Math.min(500, contentCol.implicitHeight + Colors.paddingLarge * 2)
        anchors.centerIn: parent
        color: Colors.cardSurface
        radius: Colors.radiusLarge
        border.color: Colors.border
        border.width: 1
        clip: true

        opacity: root.showContent ? 1.0 : 0.0
        scale: root.showContent ? 1.0 : 0.95
        Behavior on opacity { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Colors.durationSlow; easing.type: Easing.OutBack } }

        SharedWidgets.InnerHighlight {}

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
                    property string placeholder: "Type a command..."
                    
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
                            root.selectedIndex = (root.selectedIndex + 1) % root.filteredActions.length;
                        } else if (event.key === Qt.Key_Up) {
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
                    height: 48
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

                        Text {
                            text: modelData.label
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeMedium
                            font.weight: root.selectedIndex === index ? Font.Bold : Font.Normal
                            Layout.fillWidth: true
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
