import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../shared"

// A single on-screen keyboard key.
// Supports normal keys, modifier keys (Ctrl/Alt), and the 3-state Shift key
// (tap = one-shot shift, double-tap within 300 ms = caps lock, tap-in-caps = off).
Rectangle {
    id: root

    // ── Key data ────────────────────────────────────────────────────────────
    required property var keyData

    readonly property string key:     keyData.label     || ""
    readonly property string type:    keyData.keytype   || "normal"
    readonly property var    keycode: keyData.keycode
    readonly property string shape:   keyData.shape     || "normal"

    readonly property bool isShift:     YdotoolService.shiftKeys.indexOf(keycode) !== -1
    readonly property bool isBackspace: key.toLowerCase() === "backspace"
    readonly property bool isEnter:     key.toLowerCase() === "enter" || key.toLowerCase() === "return"
    readonly property bool isEmpty:     shape === "empty"

    // ── Sizing ───────────────────────────────────────────────────────────────
    readonly property real baseW: 45
    readonly property real baseH: 45

    readonly property var _widthMult: ({
        "normal":  1,
        "fn":      1,
        "tab":     1.6,
        "caps":    1.9,
        "shift":   2.5,
        "control": 1.3,
        "empty":   1
    })
    readonly property var _heightMult: ({
        "normal":  1,
        "fn":      0.7,
        "tab":     1,
        "caps":    1,
        "shift":   1,
        "control": 1,
        "empty":   0.7
    })

    implicitWidth:  baseW * (_widthMult[shape]  !== undefined ? _widthMult[shape]  : 1)
    implicitHeight: baseH * (_heightMult[shape] !== undefined ? _heightMult[shape] : 1)

    // space / expand keys stretch to fill available row width
    Layout.fillWidth: shape === "space" || shape === "expand"

    // ── Appearance ───────────────────────────────────────────────────────────
    radius: Colors.radiusSmall
    color: {
        if (isEmpty)
            return "transparent";
        if (isShift && YdotoolService.shiftMode > 0)
            return Colors.primarySubtle;
        if (_isModToggled)
            return Colors.primarySubtle;
        return Colors.cardSurface;
    }

    border.color: {
        if (isEmpty)            return "transparent";
        if (isShift && YdotoolService.shiftMode === 2) return Colors.primary;
        if (isShift && YdotoolService.shiftMode === 1) return Colors.withAlpha(Colors.primary, 0.6);
        if (_isModToggled)      return Colors.withAlpha(Colors.primary, 0.6);
        return Colors.border;
    }
    border.width: isEmpty ? 0 : 1

    Behavior on color        { CAnim {} }
    Behavior on border.color { CAnim {} }

    // ── Modifier toggle state (Ctrl / Alt, non-shift modkeys) ────────────────
    property bool _isModToggled: false

    // ── Caps-lock double-tap detection ───────────────────────────────────────
    Timer {
        id: capsTimer
        property bool hasStarted: false
        property bool canCaps:    false
        interval: 300
        onTriggered: { canCaps = false }
    }

    Connections {
        target: YdotoolService
        enabled: isShift
        function onShiftModeChanged() {
            if (YdotoolService.shiftMode === 0)
                capsTimer.hasStarted = false;
        }
    }

    // ── Press / release logic ────────────────────────────────────────────────
    function _onDown() {
        if (isEmpty) return;
        YdotoolService.press(root.keycode);
        // Engage shift on first press if not already active
        if (isShift && YdotoolService.shiftMode === 0)
            YdotoolService.shiftMode = 1;
    }

    function _onRelease() {
        if (isEmpty) return;

        if (root.type === "normal") {
            // Regular key: release it and drop one-shot shift if active
            YdotoolService.release(root.keycode);
            if (YdotoolService.shiftMode === 1)
                YdotoolService.releaseShiftKeys();

        } else if (isShift) {
            // 3-state shift: off → shift → caps → off
            if (YdotoolService.shiftMode === 1) {
                if (!capsTimer.hasStarted) {
                    // First tap ended — start double-tap window
                    capsTimer.hasStarted = true;
                    capsTimer.canCaps    = true;
                    capsTimer.restart();
                } else if (capsTimer.canCaps) {
                    // Second tap within window → caps lock
                    YdotoolService.shiftMode = 2;
                    capsTimer.stop();
                    capsTimer.canCaps    = false;
                    capsTimer.hasStarted = false;
                } else {
                    YdotoolService.releaseShiftKeys();
                }
            } else if (YdotoolService.shiftMode === 2) {
                // Tap in caps lock → turn off
                YdotoolService.releaseShiftKeys();
            }

        } else if (root.type === "modkey") {
            // Non-shift modkey (Ctrl, Alt): toggle latched state
            _isModToggled = !_isModToggled;
            if (!_isModToggled)
                YdotoolService.release(root.keycode);
        }
    }

    // ── Label text ───────────────────────────────────────────────────────────
    readonly property string _displayLabel: {
        if (isBackspace) return "";   // icon handled below
        if (isEnter)     return "";   // icon handled below
        if (YdotoolService.shiftMode === 2)
            return keyData.labelCaps  || keyData.labelShift || key;
        if (YdotoolService.shiftMode === 1)
            return keyData.labelShift || key;
        return key;
    }

    // ── Content ──────────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: !isEmpty

        // Backspace nerd-font icon
        Text {
            visible: isBackspace
            anchors.centerIn: parent
            text: ""
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeLarge
            color: Colors.text
        }

        // Enter nerd-font icon
        Text {
            visible: isEnter
            anchors.centerIn: parent
            text: ""
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeLarge
            color: Colors.text
        }

        // Regular label
        Text {
            visible: !isBackspace && !isEnter
            anchors.centerIn: parent
            text: _displayLabel
            font.family: Colors.fontMono
            font.pixelSize: shape === "fn" ? Colors.fontSizeXS : Colors.fontSizeMedium
            font.weight: (isShift && YdotoolService.shiftMode > 0) || _isModToggled
                         ? Font.Bold : Font.Normal
            color: (isShift && YdotoolService.shiftMode > 0) || _isModToggled
                   ? Colors.primary : Colors.text
            Behavior on color { CAnim {} }
        }

        // Interactive state layer
        StateLayer {
            id: stateLayer
            anchors.fill: parent
            radius: root.radius
            hovered: keyMouse.containsMouse
            pressed: keyMouse.pressed
            stateColor: Colors.text
        }
    }

    // ── Mouse area ───────────────────────────────────────────────────────────
    MouseArea {
        id: keyMouse
        anchors.fill: parent
        enabled: !isEmpty
        hoverEnabled: true
        cursorShape: isEmpty ? Qt.ArrowCursor : Qt.PointingHandCursor

        onPressed:  (e) => { root._onDown();    stateLayer.burst(e.x, e.y); }
        onReleased: ()  => { root._onRelease(); }
    }
}
