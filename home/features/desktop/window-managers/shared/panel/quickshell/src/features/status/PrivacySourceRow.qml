import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../shared" as Shared

Rectangle {
  id: root

  property string icon: ""
  property string label: ""
  property bool active: false

  Layout.fillWidth: true
  implicitHeight: 44
  radius: Appearance.radiusMedium
  color: root.active
    ? Colors.withAlpha(Colors.warning, 0.10)
    : Colors.cardSurface
  border.color: root.active ? Colors.withAlpha(Colors.warning, 0.3) : Colors.border
  border.width: 1
  Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationNormal } }

  RowLayout {
    anchors.fill: parent
    anchors.margins: Appearance.spacingM
    spacing: Appearance.paddingSmall

    Loader {
      sourceComponent: String(root.icon).endsWith(".svg") ? _pSvg : _pNerd
    }
    Component { id: _pSvg; Shared.SvgIcon { source: root.icon; color: root.active ? Colors.warning : Colors.textDisabled; size: Appearance.fontSizeXL } }
    Component { id: _pNerd; Text { text: root.icon; color: root.active ? Colors.warning : Colors.textDisabled; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeXL } }

    Text {
      text: root.label
      color: Colors.text
      font.pixelSize: Appearance.fontSizeMedium
      Layout.fillWidth: true
    }

    // Blinking active indicator
    Rectangle {
      width: 8; height: 8; radius: Appearance.radiusXS
      color: root.active ? Colors.warning : Colors.textDisabled
      opacity: root.active ? 1.0 : 0.3
      Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationNormal } }

      SequentialAnimation on opacity {
        running: root.active
        loops: Animation.Infinite
        NumberAnimation { from: 1.0; to: 0.3; duration: Appearance.durationPulse; easing.type: Easing.InOutSine }
        NumberAnimation { from: 0.3; to: 1.0; duration: Appearance.durationPulse; easing.type: Easing.InOutSine }
      }
    }

    Text {
      text: root.active ? "Active" : "Idle"
      color: root.active ? Colors.warning : Colors.textDisabled
      font.pixelSize: Appearance.fontSizeSmall
      font.weight: Font.Medium
    }
  }
}
