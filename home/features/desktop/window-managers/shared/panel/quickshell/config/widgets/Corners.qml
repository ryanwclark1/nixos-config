import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    
    // Configurable radius
    property int cornerRadius: 18

    Repeater {
        model: Quickshell.screens
        
        delegate: PanelWindow {
            screen: modelData
            
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-corners"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusiveZone: -1
            
            // Allow clicks to pass through the corners to windows underneath
            mask: Region {
                // Empty region means this window intercepts zero mouse events
            }

            // Create four corners
            Repeater {
                model: [
                    { top: true, left: true, rotation: 0 },
                    { top: true, left: false, rotation: 90 },
                    { top: false, left: false, rotation: 180 },
                    { top: false, left: true, rotation: 270 }
                ]
                
                delegate: Item {
                    width: root.cornerRadius
                    height: root.cornerRadius
                    
                    anchors.top: modelData.top ? parent.top : undefined
                    anchors.bottom: !modelData.top ? parent.bottom : undefined
                    anchors.left: modelData.left ? parent.left : undefined
                    anchors.right: !modelData.left ? parent.right : undefined
                    
                    transformOrigin: Item.Center
                    rotation: modelData.rotation
                    
                    // The corner effect: we draw an inverted curve
                    Shape {
                        anchors.fill: parent
                        // Smooth antialiasing
                        layer.enabled: true
                        layer.samples: 4
                        
                        ShapePath {
                            fillColor: "black" // Matches monitor bezel
                            strokeWidth: 0
                            
                            // Start at top-left
                            startX: 0
                            startY: 0
                            
                            // Draw top line to top-right
                            PathLine { x: root.cornerRadius; y: 0 }
                            
                            // Draw curve down to bottom-left
                            PathArc {
                                x: 0
                                y: root.cornerRadius
                                radiusX: root.cornerRadius
                                radiusY: root.cornerRadius
                                useLargeArc: false
                            }
                            
                            // Draw left line back to top-left
                            PathLine { x: 0; y: 0 }
                        }
                    }
                }
            }
        }
    }
}
