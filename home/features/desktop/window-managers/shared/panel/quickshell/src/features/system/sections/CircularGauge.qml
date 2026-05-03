import QtQuick
import QtQuick.Shapes
import "../../../services"
import "../../../widgets" as SharedWidgets

Item {
  id: root
  property real value: 0.0 // 0 to 1
  property color color: Colors.primary
  property int thickness: 2
  property string icon: ""
  property real iconScale: 1.0
  readonly property real safeThickness: Math.max(1, Math.min(root.thickness * root.iconScale, Math.min(root.width, root.height) / 2))
  readonly property real innerDiameter: Math.max(0, Math.min(root.width, root.height) - (safeThickness * 2))

  width: 24 * iconScale
  height: 24 * iconScale
  implicitWidth: width
  implicitHeight: height

  Item {
    id: innerContent
    anchors.centerIn: parent
    width: root.innerDiameter
    height: root.innerDiameter

    Loader {
      anchors.centerIn: parent
      sourceComponent: String(root.icon).endsWith(".svg") ? _cgSvg : _cgNerd
    }
    Component { id: _cgSvg; SharedWidgets.SvgIcon { source: root.icon; color: root.color; size: Math.max(Appearance.fontSizeSmall, innerContent.width * 0.42) } }
    Component { id: _cgNerd; Text { text: root.icon; font.family: Appearance.fontMono; font.pixelSize: Math.max(Appearance.fontSizeSmall, innerContent.width * 0.42); color: root.color; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } }
  }

  Shape {
    id: shape
    anchors.fill: parent

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
