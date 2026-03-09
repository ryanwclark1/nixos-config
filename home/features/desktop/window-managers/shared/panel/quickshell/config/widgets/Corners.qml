import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
  id: root
  
  anchors.fill: parent
  color: "transparent"
  
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-corners"
  exclusiveZone: -1
  
  // Create four corners
  Repeater {
    model: [
      { top: true, left: true, rotation: 0 },
      { top: true, right: true, rotation: 90 },
      { bottom: true, left: true, rotation: 270 },
      { bottom: true, right: true, rotation: 180 }
    ]
    
    delegate: Item {
      width: 24; height: 24
      anchors.top: modelData.top ? parent.top : undefined
      anchors.bottom: modelData.bottom ? parent.bottom : undefined
      anchors.left: modelData.left ? parent.left : undefined
      anchors.right: modelData.right ? parent.right : undefined
      
      // The corner effect: a square with a circle cut out
      Rectangle {
        anchors.fill: parent
        color: "#000000" // Standard black for screen corners
        
        // This is the "cutout" part
        Rectangle {
          width: 48; height: 48 // 2x the corner size
          radius: 24
          color: "transparent"
          border.color: "transparent"
          
          anchors.top: modelData.top ? parent.top : undefined
          anchors.bottom: modelData.bottom ? parent.bottom : undefined
          anchors.left: modelData.left ? parent.left : undefined
          anchors.right: modelData.right ? parent.right : undefined
          
          // Use a ShaderEffect or simple radius trick to create the inverted corner
          // Simplified: Black square, then transparent circle on top
          // The parent has clip: true or we use a mask.
        }
        
        // Clean implementation of inverted radius:
        // We actually want to render the gap between the screen edge and the desktop
        Canvas {
          anchors.fill: parent
          onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = "black";
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(24, 0);
            ctx.arcTo(0, 0, 0, 24, 24);
            ctx.closePath();
            ctx.fill();
          }
          rotation: modelData.rotation
        }
      }
    }
  }
}
