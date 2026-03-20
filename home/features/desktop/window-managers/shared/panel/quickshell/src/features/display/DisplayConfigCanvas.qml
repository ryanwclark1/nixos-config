import QtQuick
import "../../services"
import "../../shared"

Item {
  id: root
  required property var monitors
  required property int selectedIndex
  required property real scaleFactor
  required property real canvasOffsetX
  required property real canvasOffsetY
  required property real canvasW
  required property real canvasH
  required property bool loading

  signal monitorSelected(int index)
  signal monitorDragged(int index, real newDragX, real newDragY)

  clip: true

  // Grid background
  Rectangle {
    anchors { fill: parent; margins: Appearance.spacingS }
    color: Qt.rgba(0, 0, 0, 0.18)
    radius: Appearance.radiusMedium
    border.color: Colors.border
    border.width: 1

    // Dot grid pattern via Canvas
    Canvas {
      anchors.fill: parent
      renderTarget: Canvas.FramebufferObject
      renderStrategy: Canvas.Cooperative
      onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.fillStyle = Qt.rgba(Colors.textDisabled.r, Colors.textDisabled.g, Colors.textDisabled.b, 0.18);
        var step = 24;
        for (var gx = step; gx < width; gx += step) {
          for (var gy = step; gy < height; gy += step) {
            ctx.beginPath();
            ctx.arc(gx, gy, 1.2, 0, Math.PI * 2);
            ctx.fill();
          }
        }
      }
    }

    // Loading state
    Text {
      visible: root.loading
      anchors.centerIn: parent
      text: "Loading monitors…"
      color: Colors.textDisabled
      font.pixelSize: Appearance.fontSizeMedium
    }

    // Empty state
    Text {
      visible: !root.loading && root.monitors.length === 0
      anchors.centerIn: parent
      text: "No monitors detected"
      color: Colors.textDisabled
      font.pixelSize: Appearance.fontSizeMedium
    }

    // Monitor rectangles
    Repeater {
      model: root.monitors

      delegate: Item {
        id: monDelegate
        required property var modelData
        required property int index

        // Position and size on canvas (in scaled pixels)
        x: modelData.dragX
        y: modelData.dragY
        width:  modelData.width  * root.scaleFactor
        height: modelData.height * root.scaleFactor

        property bool isSelected: root.selectedIndex === index
        property bool isDragging: false
        property real _pressX: 0
        property real _pressY: 0
        property real _origDragX: 0
        property real _origDragY: 0

        // Monitor body
        Rectangle {
          anchors.fill: parent
          color: monDelegate.isSelected
                 ? Colors.primaryMid
                 : Colors.cardSurface
          border.color: monDelegate.isSelected
                        ? Colors.primary
                        : (dragArea.containsMouse ? Colors.withAlpha(Colors.primary, 0.5) : Colors.border)
          border.width: monDelegate.isSelected ? 2 : 1
          radius: Appearance.radiusSmall

          Behavior on color        { enabled: !Colors.isTransitioning; CAnim {} }
          Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }

          // Monitor name
          Text {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Appearance.spacingS }
            text: monDelegate.modelData.name
            color: monDelegate.isSelected ? Colors.primary : Colors.text
            font.pixelSize: Math.max(9, Math.min(13, monDelegate.height * 0.12))
            font.weight: Font.Bold
            elide: Text.ElideRight
            width: parent.width - 8
            horizontalAlignment: Text.AlignHCenter
          }

          // Resolution + rate
          Text {
            anchors.centerIn: parent
            text: monDelegate.modelData.width + "×" + monDelegate.modelData.height
                  + "\n" + monDelegate.modelData.refreshRate.toFixed(0) + "Hz"
                  + "  @" + monDelegate.modelData.scale.toFixed(2) + "×"
            color: Colors.textSecondary
            font.pixelSize: Math.max(8, Math.min(11, monDelegate.height * 0.10))
            font.family: Appearance.fontMono
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.3
          }

          // Drag cursor indicator (bottom-right small glyph)
          Text {
            anchors { bottom: parent.bottom; right: parent.right; margins: 5 }
            text: "󰆾"
            color: Colors.withAlpha(Colors.textDisabled, 0.6)
            font.family: Appearance.fontMono
            font.pixelSize: Appearance.fontSizeXS
            visible: monDelegate.height > 40
          }
        }

        MouseArea {
          id: dragArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: isDragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

          onPressed: (mouse) => {
            root.monitorSelected(monDelegate.index);
            monDelegate.isDragging    = true;
            monDelegate._pressX   = mouse.x;
            monDelegate._pressY   = mouse.y;
            monDelegate._origDragX = monDelegate.modelData.dragX;
            monDelegate._origDragY = monDelegate.modelData.dragY;
          }

          onPositionChanged: (mouse) => {
            if (!monDelegate.isDragging) return;
            var dx = mouse.x - monDelegate._pressX;
            var dy = mouse.y - monDelegate._pressY;
            var newX = monDelegate._origDragX + dx;
            var newY = monDelegate._origDragY + dy;

            // Clamp within canvas
            var maxX = root.canvasW - monDelegate.width;
            var maxY = root.canvasH - monDelegate.height;
            newX = Math.max(0, Math.min(newX, maxX));
            newY = Math.max(0, Math.min(newY, maxY));

            root.monitorDragged(monDelegate.index, newX, newY);
          }

          onReleased: {
            monDelegate.isDragging = false;
          }
        }
      }
    }
  }
}
