import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../services"

Scope {
    id: root

    readonly property int cornerRadius: Config.screenCornerRadius
    readonly property bool _anyEnabled: Config.showScreenCorners || Config.showScreenBorders

    // Border properties
    readonly property color _frameColor: Colors.bg
    readonly property int _thickness: 7
    readonly property int _borderRadius: Appearance.radiusSmall

    Variants {
        model: Quickshell.screens

        delegate: Component {
        PanelWindow {
            required property ShellScreen modelData
            screen: modelData
            visible: root._anyEnabled

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-screen-decor"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusiveZone: -1
            mask: Region {}

            // ── Screen corners ──
            Repeater {
                model: Config.showScreenCorners ? [
                    { top: true, left: true, rotation: 0 },
                    { top: true, left: false, rotation: 90 },
                    { top: false, left: false, rotation: 180 },
                    { top: false, left: true, rotation: 270 }
                ] : []

                delegate: Item {
                    width: root.cornerRadius
                    height: root.cornerRadius

                    anchors.top: modelData.top ? parent.top : undefined
                    anchors.bottom: !modelData.top ? parent.bottom : undefined
                    anchors.left: modelData.left ? parent.left : undefined
                    anchors.right: !modelData.left ? parent.right : undefined

                    transformOrigin: Item.Center
                    rotation: modelData.rotation

                    Shape {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.samples: 4

                        ShapePath {
                            fillColor: Colors.bg
                            strokeWidth: 0

                            startX: 0
                            startY: 0

                            PathLine { x: root.cornerRadius; y: 0 }

                            PathArc {
                                x: 0
                                y: root.cornerRadius
                                radiusX: root.cornerRadius
                                radiusY: root.cornerRadius
                                useLargeArc: false
                            }

                            PathLine { x: 0; y: 0 }
                        }
                    }
                }
            }

            // ── Screen border frame ──
            // Top bar
            Rectangle {
                visible: Config.showScreenBorders
                height: root._thickness
                anchors { top: parent.top; left: parent.left; right: parent.right }
                color: root._frameColor
                Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationNormal } }
            }

            // Bottom bar
            Rectangle {
                visible: Config.showScreenBorders
                height: root._thickness
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                color: root._frameColor
                Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationNormal } }
            }

            // Left bar
            Rectangle {
                visible: Config.showScreenBorders
                width: root._thickness
                anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                anchors.topMargin: root._thickness; anchors.bottomMargin: root._thickness
                color: root._frameColor
                Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationNormal } }
            }

            // Right bar
            Rectangle {
                visible: Config.showScreenBorders
                width: root._thickness
                anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                anchors.topMargin: root._thickness; anchors.bottomMargin: root._thickness
                color: root._frameColor
                Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationNormal } }
            }

            // Border inner corner canvases
            Canvas {
                visible: Config.showScreenBorders
                width: root._borderRadius; height: root._borderRadius
                anchors { top: parent.top; left: parent.left }
                anchors.topMargin: root._thickness; anchors.leftMargin: root._thickness
                renderTarget: Canvas.FramebufferObject
                property color c: root._frameColor
                onCChanged: requestPaint()
                onPaint: root._drawInvertedCorner(getContext("2d"), width, height, "TL")
            }

            Canvas {
                visible: Config.showScreenBorders
                width: root._borderRadius; height: root._borderRadius
                anchors { top: parent.top; right: parent.right }
                anchors.topMargin: root._thickness; anchors.rightMargin: root._thickness
                renderTarget: Canvas.FramebufferObject
                property color c: root._frameColor
                onCChanged: requestPaint()
                onPaint: root._drawInvertedCorner(getContext("2d"), width, height, "TR")
            }

            Canvas {
                visible: Config.showScreenBorders
                width: root._borderRadius; height: root._borderRadius
                anchors { bottom: parent.bottom; left: parent.left }
                anchors.bottomMargin: root._thickness; anchors.leftMargin: root._thickness
                renderTarget: Canvas.FramebufferObject
                property color c: root._frameColor
                onCChanged: requestPaint()
                onPaint: root._drawInvertedCorner(getContext("2d"), width, height, "BL")
            }

            Canvas {
                visible: Config.showScreenBorders
                width: root._borderRadius; height: root._borderRadius
                anchors { bottom: parent.bottom; right: parent.right }
                anchors.bottomMargin: root._thickness; anchors.rightMargin: root._thickness
                renderTarget: Canvas.FramebufferObject
                property color c: root._frameColor
                onCChanged: requestPaint()
                onPaint: root._drawInvertedCorner(getContext("2d"), width, height, "BR")
            }
        }
        }
    }

    function _drawInvertedCorner(ctx, w, h, type) {
        ctx.reset();
        ctx.fillStyle = root._frameColor;

        if (type === "TL") {
            ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(w, 0);
            ctx.arc(w, h, w, 1.5 * Math.PI, Math.PI, true);
            ctx.lineTo(0, 0); ctx.fill();
        } else if (type === "TR") {
            ctx.beginPath(); ctx.moveTo(w, 0); ctx.lineTo(w, h);
            ctx.arc(0, h, w, 0, 1.5 * Math.PI, true);
            ctx.lineTo(w, 0); ctx.fill();
        } else if (type === "BL") {
            ctx.beginPath(); ctx.moveTo(0, h); ctx.lineTo(0, 0);
            ctx.arc(w, 0, w, Math.PI, 0.5 * Math.PI, true);
            ctx.lineTo(0, h); ctx.fill();
        } else if (type === "BR") {
            ctx.beginPath(); ctx.moveTo(w, h); ctx.lineTo(0, h);
            ctx.arc(0, 0, w, 0.5 * Math.PI, 0, true);
            ctx.lineTo(w, h); ctx.fill();
        }
    }
}
