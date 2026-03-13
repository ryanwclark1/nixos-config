import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../widgets" as SharedWidgets

Rectangle {
  id: root

  property string label
  property string icon
  property string configKey: ""
  property bool checked: configKey ? Config[configKey] : false
  signal toggled()

  Layout.fillWidth: true
  implicitHeight: 84
  radius: Colors.radiusMedium
  color: Colors.bgWidget
  border.color: (configKey ? Config[configKey] : root.checked) ? Colors.primary : Colors.border
  border.width: 1

  readonly property bool _active: configKey ? Config[configKey] : root.checked

  SharedWidgets.StateLayer {
    id: toggleStateLayer
    hovered: toggleHover.containsMouse
    pressed: toggleHover.pressed
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: Colors.spacingM
    spacing: Colors.spacingM

    Text {
      text: root.icon
      color: root._active ? Colors.primary : Colors.textSecondary
      font.family: Colors.fontMono
      font.pixelSize: Colors.fontSizeHuge
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 3
      Text { text: root.label; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
      Text { text: root._active ? "Enabled" : "Disabled"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeSmall; Layout.fillWidth: true; elide: Text.ElideRight }
    }

    SharedWidgets.DankToggle {
      checked: root._active
      onToggled: {
        if (root.configKey)
          Config[root.configKey] = !Config[root.configKey];
        else
          root.toggled();
      }
    }
  }

  MouseArea {
    id: toggleHover
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: (mouse) => {
      toggleStateLayer.burst(mouse.x, mouse.y);
      if (root.configKey)
        Config[root.configKey] = !Config[root.configKey];
      else
        root.toggled();
    }
  }
}
