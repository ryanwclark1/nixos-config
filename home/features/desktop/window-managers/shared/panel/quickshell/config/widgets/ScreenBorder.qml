import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
  id: win

  property color frameColor: Colors.background
  property int thickness: 7
  property int borderRadius: Colors.radiusSmall

  anchors { top: true; bottom: true; left: true; right: true }

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "quickshell-border"
  exclusiveZone: 0
  mask: Region {}
  color: "transparent"

  // Top Bar
  Rectangle {
    height: win.thickness
    anchors { top: parent.top; left: parent.left; right: parent.right }
    color: win.frameColor
    Behavior on color { ColorAnimation { duration: 200 } }
  }

  // Bottom Bar
  Rectangle {
    height: win.thickness
    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
    color: win.frameColor
    Behavior on color { ColorAnimation { duration: 200 } }
  }

  // Left Bar
  Rectangle {
    width: win.thickness
    anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
    anchors.topMargin: win.thickness; anchors.bottomMargin: win.thickness
    color: win.frameColor
    Behavior on color { ColorAnimation { duration: 200 } }
  }

  // Right Bar
  Rectangle {
    width: win.thickness
    anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
    anchors.topMargin: win.thickness; anchors.bottomMargin: win.thickness
    color: win.frameColor
    Behavior on color { ColorAnimation { duration: 200 } }
  }

  // Corner canvases
  Canvas {
    width: win.borderRadius; height: win.borderRadius
    anchors { top: parent.top; left: parent.left }
    anchors.topMargin: win.thickness; anchors.leftMargin: win.thickness
    property color c: win.frameColor
    onCChanged: requestPaint()
    onPaint: win.drawInvertedCorner(getContext("2d"), width, height, "TL")
  }

  Canvas {
    width: win.borderRadius; height: win.borderRadius
    anchors { top: parent.top; right: parent.right }
    anchors.topMargin: win.thickness; anchors.rightMargin: win.thickness
    property color c: win.frameColor
    onCChanged: requestPaint()
    onPaint: win.drawInvertedCorner(getContext("2d"), width, height, "TR")
  }

  Canvas {
    width: win.borderRadius; height: win.borderRadius
    anchors { bottom: parent.bottom; left: parent.left }
    anchors.bottomMargin: win.thickness; anchors.leftMargin: win.thickness
    property color c: win.frameColor
    onCChanged: requestPaint()
    onPaint: win.drawInvertedCorner(getContext("2d"), width, height, "BL")
  }

  Canvas {
    width: win.borderRadius; height: win.borderRadius
    anchors { bottom: parent.bottom; right: parent.right }
    anchors.bottomMargin: win.thickness; anchors.rightMargin: win.thickness
    property color c: win.frameColor
    onCChanged: requestPaint()
    onPaint: win.drawInvertedCorner(getContext("2d"), width, height, "BR")
  }

  function drawInvertedCorner(ctx, w, h, type) {
    ctx.reset();
    ctx.fillStyle = win.frameColor;

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
