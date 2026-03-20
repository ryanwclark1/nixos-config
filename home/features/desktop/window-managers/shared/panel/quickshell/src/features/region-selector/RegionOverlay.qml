import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"
import "../../shared"

PanelWindow {
    id: root

    signal dismissRequested()
    signal regionSelected(real x, real y, real w, real h)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell:regionSelector"
    exclusionMode: ExclusionMode.Ignore

    // ── Selection state ─────────────────────────
    property real dragStartX: 0
    property real dragStartY: 0
    property real draggingX: 0
    property real draggingY: 0
    property bool dragging: false

    readonly property real regionX: Math.min(dragStartX, draggingX)
    readonly property real regionY: Math.min(dragStartY, draggingY)
    readonly property real regionWidth: Math.abs(draggingX - dragStartX)
    readonly property real regionHeight: Math.abs(draggingY - dragStartY)
    readonly property bool hasRegion: regionWidth > 5 && regionHeight > 5

    // ── Overlay color ───────────────────────────
    readonly property color overlayColor: Qt.rgba(0, 0, 0, 0.4)

    // ── Keyboard handling ───────────────────────
    Item {
        focus: true
        anchors.fill: parent

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.dismissRequested();
            }
        }
    }

    // ── Mouse interaction ───────────────────────
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.dismissRequested();
                return;
            }
            root.dragStartX = mouse.x;
            root.dragStartY = mouse.y;
            root.draggingX = mouse.x;
            root.draggingY = mouse.y;
            root.dragging = true;
        }

        onPositionChanged: mouse => {
            if (!root.dragging) return;
            root.draggingX = mouse.x;
            root.draggingY = mouse.y;
        }

        onReleased: mouse => {
            if (mouse.button === Qt.RightButton) return;
            root.dragging = false;
            if (root.hasRegion) {
                // Clamp to screen bounds
                var rx = Math.max(0, root.regionX);
                var ry = Math.max(0, root.regionY);
                var rw = Math.min(root.regionWidth, root.width - rx);
                var rh = Math.min(root.regionHeight, root.height - ry);
                root.regionSelected(rx, ry, rw, rh);
            } else {
                // Click without drag — dismiss
                root.dismissRequested();
            }
        }

        // ── Dark overlay with transparent cut-out ──
        // Uses the "huge border" trick: a transparent rectangle at the
        // selection position with a massive border that covers the screen.
        Rectangle {
            id: darkenOverlay
            x: root.regionX - border.width
            y: root.regionY - border.width
            width: root.regionWidth + border.width * 2
            height: root.regionHeight + border.width * 2
            color: "transparent"
            border.color: root.overlayColor
            border.width: Math.max(root.width, root.height) * 2
            visible: root.dragging && root.hasRegion
        }

        // Full-screen scrim when not dragging a region
        Rectangle {
            anchors.fill: parent
            color: root.overlayColor
            visible: !root.dragging || !root.hasRegion
        }

        // ── Selection border ───────────────────────
        Rectangle {
            x: root.regionX
            y: root.regionY
            width: root.regionWidth
            height: root.regionHeight
            color: "transparent"
            border.color: Colors.primary
            border.width: 2
            visible: root.dragging && root.hasRegion
            z: 2
        }

        // ── Crosshair lines ────────────────────────
        Rectangle {
            x: mouseArea.mouseX
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Colors.text
            opacity: 0.2
            z: 3
        }
        Rectangle {
            y: mouseArea.mouseY
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Colors.text
            opacity: 0.2
            z: 3
        }

        // ── Dimension label ────────────────────────
        Rectangle {
            visible: root.dragging && root.hasRegion
            x: root.regionX + root.regionWidth - width
            y: root.regionY + root.regionHeight + Appearance.spacingS
            width: dimLabel.implicitWidth + Appearance.spacingM * 2
            height: dimLabel.implicitHeight + Appearance.spacingXS * 2
            radius: Appearance.radiusXS
            color: Colors.popupSurface
            border.color: Colors.border
            border.width: 1
            z: 4

            Text {
                id: dimLabel
                anchors.centerIn: parent
                text: Math.round(root.regionWidth) + " x " + Math.round(root.regionHeight)
                color: Colors.text
                font.family: Appearance.fontMono
                font.pixelSize: Appearance.fontSizeSmall
            }
        }
    }
}
