import QtQuick
import QtQuick.Shapes
import "../services"

Item {
  id: root
  property real value: 0.0 // 0 to 1
  property color color: Colors.primary
  property int thickness: 2
  property alias icon: iconText.text

  width: 24
  height: 24

  Text {
    id: iconText
    anchors.centerIn: parent
    font.family: Colors.fontMono
    font.pixelSize: Colors.fontSizeSmall
    color: root.color
  }

  Shape {
    id: shape
    anchors.fill: parent
    layer.enabled: true
    layer.samples: 4

    ShapePath {
      fillColor: "transparent"
      strokeColor: Colors.withAlpha(root.color, 0.2)
      strokeWidth: root.thickness
      capStyle: ShapePath.RoundCap
      PathAngleArc {
        centerX: root.width / 2; centerY: root.height / 2
        radiusX: (root.width - root.thickness) / 2; radiusY: (root.height - root.thickness) / 2
        startAngle: 0
        sweepAngle: 360
      }
    }

    ShapePath {
      fillColor: "transparent"
      strokeColor: root.color
      strokeWidth: root.thickness
      capStyle: ShapePath.RoundCap

      PathAngleArc {
        centerX: root.width / 2; centerY: root.height / 2
        radiusX: (root.width - root.thickness) / 2; radiusY: (root.height - root.thickness) / 2
        startAngle: -90
        sweepAngle: root.value * 360
      }
    }
  }

}
