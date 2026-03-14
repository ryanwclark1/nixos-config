import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

Rectangle {
  id: root

  required property var launcher

  radius: Colors.radiusLarge
  color: Colors.withAlpha(Colors.surface, 0.45)
  border.color: Colors.border
  border.width: 1

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.launcher.sidebarCompact ? Colors.spacingS : Colors.spacingM
    spacing: root.launcher.sidebarCompact ? Colors.spacingXS : Colors.paddingSmall

    Text { visible: !root.launcher.sidebarCompact; text: "Launcher"; color: Colors.text; font.pixelSize: Colors.fontSizeXL; font.weight: Font.DemiBold }
    Text { visible: !root.launcher.sidebarCompact; text: "Modes"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }

    Repeater {
      model: root.launcher.primaryModes
      delegate: Rectangle {
        Layout.fillWidth: true
        implicitHeight: root.launcher.sidebarCompact ? 40 : 46
        radius: Colors.radiusMedium
        color: root.launcher.mode === modelData ? Colors.highlight : Colors.bgWidget
        Behavior on color { ColorAnimation { duration: Colors.durationFast } }
        border.color: root.launcher.mode === modelData ? Colors.primary : "transparent"
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.margins: root.launcher.sidebarCompact ? Colors.spacingXS : Colors.paddingSmall
          spacing: root.launcher.sidebarCompact ? Colors.spacingXS : Colors.paddingSmall
          Text {
            text: root.launcher.modeIcons[modelData] || "•"
            color: root.launcher.mode === modelData ? Colors.primary : Colors.textSecondary
            font.family: Colors.fontMono
            font.pixelSize: root.launcher.sidebarCompact ? Colors.fontSizeXL : Colors.fontSizeLarge
            Layout.alignment: Qt.AlignVCenter | (root.launcher.sidebarCompact ? Qt.AlignHCenter : 0)
          }
          ColumnLayout {
            visible: !root.launcher.sidebarCompact
            Layout.fillWidth: true
            spacing: 0
            Text { text: root.launcher.modeInfo(modelData).label; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.DemiBold }
            Text { text: root.launcher.modeInfo(modelData).hint; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; elide: Text.ElideRight; Layout.fillWidth: true }
          }
        }

        SharedWidgets.StateLayer { id: modeStateLayer; hovered: modeHover.containsMouse; pressed: modeHover.pressed; visible: root.launcher.mode !== modelData }
        MouseArea {
          id: modeHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: (mouse) => {
            modeStateLayer.burst(mouse.x, mouse.y);
            root.launcher.open(modelData, true);
          }
        }
      }
    }

    Item { Layout.fillHeight: true }

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 74
      radius: Colors.radiusMedium
      color: Colors.bgWidget
      border.color: Colors.border
      border.width: 1
      visible: Config.launcherShowModeHints && !root.launcher.sidebarCompact

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        spacing: Colors.spacingXXS
        Text { text: "Controls"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
        Text { text: root.launcher.tabControlHintText; color: Colors.text; font.pixelSize: Colors.fontSizeSmall }
        Text { text: root.launcher.launcherControlHintText; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; wrapMode: Text.WordWrap }
      }
    }
  }
}
