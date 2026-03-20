import QtQuick
import QtQuick.Shapes
import "../../../services"

Item {
  id: root
  property real value: 0.0 // 0 to 1
  property color color: Colors.primary
  property int thickness: 2
  property alias icon: iconText.text
  readonly property real safeThickness: Math.max(1, Math.min(root.thickness, Math.min(root.width, root.height) / 2))
  readonly property real innerDiameter: Math.max(0, Math.min(root.width, root.height) - (safeThickness * 2))

  width: 24
  height: 24

  Item {
    id: innerContent
    anchors.centerIn: parent
    width: root.innerDiameter
    height: root.innerDiameter

    Text {
      id: iconText
      anchors.centerIn: parent
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      font.family: Appearance.fontMono
      font.pixelSize: Math.max(Appearance.fontSizeSmall, innerContent.width * 0.42)
      color: root.color
    }
  }

  Shape {
    id: shape
    anchors.fill: parent
    layer.enabled: true
    layer.samples: 4

    ShapePath {
      fillColor: "transparent"
      strokeColor: Colors.withAlpha(root.color, 0.2)
      strokeWidth: root.safeThickness
      capStyle: ShapePath.RoundCap
      PathAngleArc {
        centerX: root.width / 2; centerY: root.height / 2
        radiusX: (root.width - root.safeThickness) / 2; radiusY: (root.height - root.safeThickness) / 2
        startAngle: 0
        sweepAngle: 360
      }
    }

    ShapePath {
      fillColor: "transparent"
      strokeColor: root.color
      strokeWidth: root.safeThickness
      capStyle: ShapePath.RoundCap

      PathAngleArc {
        centerX: root.width / 2; centerY: root.height / 2
        radiusX: (root.width - root.safeThickness) / 2; radiusY: (root.height - root.safeThickness) / 2
        startAngle: -90
        sweepAngle: root.value * 360
      }
    }
  }

}
