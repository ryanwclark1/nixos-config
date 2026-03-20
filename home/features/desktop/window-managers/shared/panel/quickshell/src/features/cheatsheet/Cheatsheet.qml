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

    visible: root.isVisible || _fadeAnim.running

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

    // Scrim background
    Rectangle {
        anchors.fill: parent
        color: Colors.overlayScrim
        opacity: root.isVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Appearance.durationFast } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // Elastic scale: fast track snaps to target, slow track settles — combined
    // weight produces a spring-like overshoot without spring physics.
    ElasticNumber {
        id: _elasticScale
        target: root.isVisible ? 1.0 : 0.95
        fastDuration: Appearance.durationSnap
        slowDuration: Appearance.durationPanelOpen
        fastWeight: 0.45
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
        radius: Appearance.radiusLarge

        opacity: root.isVisible ? 1.0 : 0.0
        scale: _elasticScale.value
        focus: root.isVisible
        Keys.onEscapePressed: root.close()
        Behavior on opacity { NumberAnimation { id: _fadeAnim; duration: Appearance.durationNormal; easing.type: Easing.OutCubic } }
        layer.enabled: _fadeAnim.running || _elasticScale.running

        InnerHighlight { highlightOpacity: 0.12 }
        SurfaceGradient {}

        // Block click-through to scrim
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.paddingLarge
            spacing: Appearance.spacingLG

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingM

                Text {
                    text: "Keyboard Shortcuts"
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeHuge
                    font.weight: Font.DemiBold
                    font.letterSpacing: Appearance.letterSpacingTight
                }

                Item { Layout.fillWidth: true }

                // Search
                SearchBar {
                    id: searchBar
                    Layout.preferredWidth: 260
                    placeholder: "Filter shortcuts..."
                }

                IconButton {
                    size: Appearance.iconSizeMedium
                    icon: "keyboard.svg"
                    tooltipText: "Close"
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
