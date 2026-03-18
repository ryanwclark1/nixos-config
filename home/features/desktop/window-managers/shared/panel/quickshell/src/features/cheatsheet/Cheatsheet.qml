import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"
import "../../shared"

PanelWindow {
    id: root

    property bool isVisible: false

    RetainableLock {
        id: _visLock
        locked: root.isVisible || _fadeAnim.running
    }
    visible: _visLock.retained

    anchors {
        top: true; bottom: true; left: true; right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell:cheatsheet"
    exclusiveZone: 0
    color: "transparent"

    function open()   { root.isVisible = true; }
    function close()  { root.isVisible = false; }
    function toggle() { root.isVisible ? close() : open(); }

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { root.toggle(); }
        function open():   void { root.open(); }
        function close():  void { root.close(); }
    }

    GlobalShortcut {
        name: "cheatsheetToggle"
        description: "Toggle keybinding cheatsheet"
        onPressed: root.toggle()
    }

    Keys.onEscapePressed: root.close()

    // Scrim background
    Rectangle {
        anchors.fill: parent
        color: Colors.overlayScrim
        opacity: root.isVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Colors.durationFast } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // Content card
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 1200)
        height: Math.min(parent.height - 80, 800)
        color: Colors.popupSurface
        border.color: Colors.border
        border.width: 1
        radius: Colors.radiusLarge

        opacity: root.isVisible ? 1.0 : 0.0
        scale: root.isVisible ? 1.0 : 0.95
        Behavior on opacity { NumberAnimation { id: _fadeAnim; duration: Colors.durationNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Colors.durationPanelOpen; easing.type: Easing.OutBack; overshoot: 1.3 } }
        layer.enabled: _fadeAnim.running

        InnerHighlight { highlightOpacity: 0.12 }
        SurfaceGradient {}

        // Block click-through to scrim
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.paddingLarge
            spacing: Colors.spacingLG

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingM

                Text {
                    text: "Keyboard Shortcuts"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeHuge
                    font.weight: Font.DemiBold
                    font.letterSpacing: Colors.letterSpacingTight
                }

                Item { Layout.fillWidth: true }

                // Search
                SearchBar {
                    id: searchBar
                    Layout.preferredWidth: 260
                    placeholder: "Filter shortcuts..."
                }

                IconButton {
                    size: 32
                    icon: "\u{f0156}"
                    onClicked: root.close()
                }
            }

            // Keybinds content
            CheatsheetContent {
                Layout.fillWidth: true
                Layout.fillHeight: true
                searchQuery: searchBar.text
            }
        }
    }
}
