import QtQuick
import "../services"
import "../widgets" as SharedWidgets

// StatPill — parameterised bar pill for CPU / RAM / GPU stats.
// Accepts icon, color, label and stat key; renders icon-only, compact or wide.
Item {
  id: root

  property string statKey: ""
  property string icon: ""
  property color iconColor: Colors.primary
  property string label: ""
  property var widgetInstance: null
  property var anchorWindow: null

  // Bound by parent from Panel.qml helper functions:
  property bool compact: false
  property bool iconOnly: false
  property string valueText: ""
  property string compactValueText: ""
  property string tooltipText: ""
  property bool isActive: false

  signal clicked()

  implicitWidth: pill.implicitWidth
  implicitHeight: pill.implicitHeight

  SharedWidgets.Ref { service: SystemStatus }

  SharedWidgets.BarPill {
    id: pill
    anchors.centerIn: parent
    anchorWindow: root.anchorWindow
    isActive: root.isActive
    tooltipText: root.tooltipText
    horizontalPadding: (root.compact || root.iconOnly) ? 5 : 8
    onClicked: root.clicked()

    Loader {
      active: true
      sourceComponent: root.iconOnly ? iconContent : (root.compact ? compactContent : wideContent)
    }
  }

  Component {
    id: iconContent
    Text {
      text: root.icon
      color: root.iconColor
      font.pixelSize: Colors.fontSizeMedium
      font.family: Colors.fontMono
    }
  }

  Component {
    id: compactContent
    Column {
      spacing: 1

      Text {
        text: root.icon
        color: root.iconColor
        font.pixelSize: Colors.fontSizeMedium
        font.family: Colors.fontMono
        anchors.horizontalCenter: parent.horizontalCenter
      }

      Text {
        text: root.compactValueText
        color: Colors.text
        font.pixelSize: Colors.fontSizeXS
        font.weight: Font.DemiBold
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }
  }

  Component {
    id: wideContent
    Row {
      spacing: Colors.spacingS

      Text {
        text: root.icon
        color: root.iconColor
        font.pixelSize: Colors.fontSizeLarge
        font.family: Colors.fontMono
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: root.label + " " + root.valueText
        color: Colors.text
        font.pixelSize: Colors.fontSizeMedium
        font.weight: Font.DemiBold
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
}
