import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../widgets" as SharedWidgets

ColumnLayout {
  id: root

  property string label
  property string currentValue
  property var options: []
  signal modeSelected(string modeValue)

  spacing: Colors.spacingM
  Layout.fillWidth: true

  Text { text: root.label; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium }

  Flow {
    Layout.fillWidth: true
    width: parent.width
    spacing: Colors.paddingSmall

    Repeater {
      model: root.options
      delegate: SharedWidgets.FilterChip {
        label: modelData.label
        selected: root.currentValue === modelData.value
        onClicked: root.modeSelected(modelData.value)
      }
    }
  }
}
