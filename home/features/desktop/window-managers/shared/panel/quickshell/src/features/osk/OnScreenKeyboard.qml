import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"
import "../../shared"
import "../../widgets" as SharedWidgets

// On-Screen Keyboard
// Anchors to the bottom edge of the screen as a layer-shell Overlay surface.
// Toggled via IPC target "osk" or GlobalShortcut "oskToggle".
PanelWindow {
    id: root

    // ── Visibility / RetainableLock ──────────────────────────────────────────
    property bool isVisible: false

    visible: root.isVisible || _enterAnim.running || _exitAnim.running

    // ── Layer shell config ───────────────────────────────────────────────────
    anchors {
        bottom: true
        left:   true
        right:  true
    }

    color: "transparent"

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None   // don't steal keyboard focus
    WlrLayershell.namespace:     "quickshell:osk"

    // Pinned = reserve vertical space so windows don't overlap the keyboard
    property bool pinned: Config.oskPinnedOnStartup
    exclusiveZone: pinned && isVisible ? oskBg.height + 2 : 0

    implicitWidth:  oskBg.width
    implicitHeight: oskBg.height + Appearance.spacingL   // room for shadow

    // ── Public API ───────────────────────────────────────────────────────────
    function open()   { root.isVisible = true;  }
    function close()  { root.isVisible = false; YdotoolService.releaseAllKeys(); }
    function toggle() { root.isVisible ? root.close() : root.open(); }

    // ── IPC ──────────────────────────────────────────────────────────────────
    IpcHandler {
        target: "osk"
        function toggle(): void { root.toggle(); }
        function open():   void { root.open();   }
        function close():  void { root.close();  }
    }

    // ── Shadow behind background ─────────────────────────────────────────────
    ElevationShadow {
        elevation:    12
        shadowRadius: oskBg.radius
        // ElevationShadow uses anchors.fill parent so it needs to be a sibling
        // anchored to oskBg — we use a simple wrapper Item
        z: -1
        anchors.fill: oskBg
        anchors.topMargin:    -8
        anchors.bottomMargin: -4
        anchors.leftMargin:   -8
        anchors.rightMargin:  -8
    }

    // ── Background card ──────────────────────────────────────────────────────
    Rectangle {
        id: oskBg

        anchors {
            bottom:       parent.bottom
            left:         parent.left
            right:        parent.right
            bottomMargin: Appearance.spacingS
            leftMargin:   Appearance.spacingM
            rightMargin:  Appearance.spacingM
        }

        color:        Colors.popupSurface
        border.color: Colors.border
        border.width: 1
        radius:       Appearance.radiusLarge
        focus:        root.isVisible
        Keys.onEscapePressed: root.close()

        implicitWidth:  oskRow.implicitWidth  + Appearance.paddingMedium * 2
        implicitHeight: oskRow.implicitHeight + Appearance.paddingMedium * 2

        // ── Slide-up enter / slide-down exit ─────────────────────────────────
        property real _slideOffset: root.isVisible ? 0 : implicitHeight + Appearance.spacingM
        Behavior on _slideOffset {
            NumberAnimation {
                id: _enterAnim
                duration: Appearance.durationPanelOpen
                easing.type: Easing.OutCubic
            }
        }
        // Separate behavior for exit so we can track it in RetainableLock
        // (reuse _enterAnim running flag — one animation object covers both)
        transform: Translate { y: oskBg._slideOffset }

        property real _fadeOpacity: root.isVisible ? 1.0 : 0.0
        opacity: _fadeOpacity
        Behavior on _fadeOpacity {
            NumberAnimation {
                id: _exitAnim
                duration: Appearance.durationPanelClose
                easing.type: Easing.OutCubic
            }
        }

        layer.enabled: _enterAnim.running || _exitAnim.running

        // Block click-through
        MouseArea { anchors.fill: parent }

        // ── Content row ───────────────────────────────────────────────────────
        RowLayout {
            id: oskRow

            anchors {
                fill:          parent
                leftMargin:    Appearance.paddingMedium
                rightMargin:   Appearance.paddingMedium
                topMargin:     Appearance.paddingMedium
                bottomMargin:  Appearance.paddingMedium
            }
            spacing: Appearance.spacingM

            // ── Control column (pin + hide) ───────────────────────────────────
            ColumnLayout {
                spacing: Appearance.spacingXS
                Layout.alignment: Qt.AlignVCenter

                // Pin button
                Rectangle {
                    id: pinBtn
                    width: 40; height: 40
                    radius: Appearance.radiusSmall
                    color: root.pinned ? Colors.primarySubtle : Colors.cardSurface
                    border.color: root.pinned ? Colors.primary : Colors.border
                    border.width: 1

                    Behavior on color        { enabled: !Colors.isTransitioning; CAnim {} }
                    Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: Appearance.fontMono
                        font.pixelSize: Appearance.fontSizeMedium
                        color: root.pinned ? Colors.primary : Colors.textSecondary
                        Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
                    }

                    StateLayer {
                        id: pinStateLayer
                        radius: parent.radius
                        hovered: pinMouse.containsMouse
                        pressed: pinMouse.pressed
                    }
                    MouseArea {
                        id: pinMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: (e) => {
                            pinStateLayer.burst(e.x, e.y);
                            root.pinned = !root.pinned;
                        }
                    }
                }

                // Hide button
                Rectangle {
                    id: hideBtn
                    width: 40; height: 40
                    radius: Appearance.radiusSmall
                    color: Colors.cardSurface
                    border.color: Colors.border
                    border.width: 1

                    SharedWidgets.SvgIcon {
                        anchors.centerIn: parent
                        source: "keyboard.svg"
                        size: Appearance.fontSizeMedium
                        color: Colors.textSecondary
                    }

                    StateLayer {
                        id: hideStateLayer
                        radius: parent.radius
                        hovered: hideMouse.containsMouse
                        pressed: hideMouse.pressed
                    }
                    MouseArea {
                        id: hideMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: (e) => {
                            hideStateLayer.burst(e.x, e.y);
                            root.close();
                        }
                    }
                }
            }

            // ── Vertical divider ─────────────────────────────────────────────
            Rectangle {
                Layout.fillHeight: true
                Layout.topMargin:    Appearance.spacingM
                Layout.bottomMargin: Appearance.spacingM
                implicitWidth: 1
                color: Colors.border
            }

            // ── Keyboard grid ────────────────────────────────────────────────
            OskContent {
                id: oskContent
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
