import QtQuick
import QtQuick.Layouts
import "../services"

ColumnLayout {
  id: root

  // ── Required properties ────────────────────
  required property string sectionLabel
  required property string icon
  required property string mutedIcon
  required property real volume
  required property bool muted
  required property string target       // wpctl target, e.g. "@DEFAULT_AUDIO_SINK@"
  required property var deviceModel     // list of {id, name, volume, muted, isDefault}
  required property int defaultDeviceId
  required property string emptyIcon
  required property string emptyMessage
  required property bool compactMode

  signal sliderMoved(real value)

  spacing: Colors.spacingM

  function _percentText(value, muted) {
    return muted ? "Muted" : Math.round(value * 100) + "%";
  }

  SectionLabel { label: root.sectionLabel }

  Rectangle {
    Layout.fillWidth: true
    radius: Colors.radiusMedium
    color: Colors.withAlpha(Colors.surface, 0.4)
    border.color: Colors.border
    border.width: 1
    implicitHeight: controlCol.implicitHeight + 2 * Colors.spacingM

    gradient: SurfaceGradient {}

    // Inner highlight
    InnerHighlight { }

    ColumnLayout {
      id: controlCol
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Colors.spacingM
      spacing: Colors.spacingS

      // Normal (non-compact) header row
      RowLayout {
        visible: !root.compactMode
        Layout.fillWidth: true
        Text { text: root.icon; color: root.muted ? Colors.error : Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
        Text { text: root.sectionLabel.charAt(0) + root.sectionLabel.slice(1).toLowerCase(); color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium }
        Item { Layout.fillWidth: true }
        StatusChip {
          text: root._percentText(root.volume, root.muted)
          chipColor: root.muted ? Colors.error : Colors.textSecondary
        }
        MuteButton {
          target: root.target
          muted: root.muted
          icon: root.icon; mutedIcon: root.mutedIcon
        }
      }

      // Compact header layout
      ColumnLayout {
        visible: root.compactMode
        Layout.fillWidth: true
        spacing: Colors.spacingXS

        RowLayout {
          Layout.fillWidth: true
          Text { text: root.icon; color: root.muted ? Colors.error : Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
          Text { text: root.sectionLabel.charAt(0) + root.sectionLabel.slice(1).toLowerCase(); color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium }
          Item { Layout.fillWidth: true }
          MuteButton {
            target: root.target
            muted: root.muted
            icon: root.icon; mutedIcon: root.mutedIcon
          }
        }

        StatusChip {
          text: root._percentText(root.volume, root.muted)
          chipColor: root.muted ? Colors.error : Colors.textSecondary
        }
      }

      SliderTrack {
        Layout.fillWidth: true
        value: root.volume
        muted: root.muted
        icon: root.icon
        mutedIcon: root.mutedIcon
        onSliderMoved: (v) => root.sliderMoved(v)
      }
    }
  }

  // ── Device cards ─────────────────────────
  Repeater {
    model: root.deviceModel
    delegate: Rectangle {
      id: deviceCard
      Layout.fillWidth: true
      implicitHeight: root.compactMode ? 56 : 46
      radius: Colors.radiusMedium
      property bool isDefault: modelData.id === root.defaultDeviceId
      property bool isHovered: deviceHover.containsMouse
      color: isDefault ? Colors.withAlpha(Colors.primary, 0.16) : (isHovered ? Colors.withAlpha(Colors.primary, 0.12) : Colors.withAlpha(Colors.surface, 0.35))
      border.color: isDefault ? Colors.primary : Colors.border
      border.width: 1
      Behavior on color { ColorAnimation { duration: Colors.durationFast } }

      InnerHighlight { highlightOpacity: 0.15; hoveredOpacity: 0.3; hovered: deviceCard.isDefault }

      RowLayout {
        anchors.fill: parent
        anchors.margins: Colors.paddingSmall
        spacing: Colors.paddingSmall
        Text { text: deviceCard.isDefault ? "󰄬" : root.icon; color: deviceCard.isDefault ? Colors.primary : Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge }
        Text { text: modelData.name; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: deviceCard.isDefault ? Font.DemiBold : Font.Normal; elide: Text.ElideRight; Layout.fillWidth: true }
        Text { text: Math.min(Math.round(modelData.volume * 100), 100) + "%"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS }
        Text { visible: !root.compactMode; text: deviceCard.isDefault ? "Default" : "Select"; color: deviceCard.isDefault ? Colors.primary : Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium }
      }

      MouseArea { id: deviceHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: AudioService.setDefaultDevice(modelData.id) }
    }
  }

  EmptyState {
    Layout.fillWidth: true
    Layout.topMargin: Colors.spacingXS
    Layout.bottomMargin: Colors.spacingXS
    visible: root.deviceModel.length === 0
    icon: root.emptyIcon
    message: root.emptyMessage
  }
}
