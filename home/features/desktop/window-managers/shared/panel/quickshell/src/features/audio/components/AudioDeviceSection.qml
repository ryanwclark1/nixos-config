import QtQuick
import QtQuick.Layouts
import "."
import "../../../services"
import "../../../services/IconHelpers.js" as IconHelpers
import "../../../shared"
import "../../../widgets"

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
  property bool useCompactDevicePicker: false
  property bool pickerExpanded: false
  property int compactPickerMaxHeight: 224

  signal sliderMoved(real value)

  spacing: Appearance.spacingM

  function _percentText(value, muted) {
    return muted ? "Muted" : Math.round(value * 100) + "%";
  }

  function _currentDevice() {
    for (var i = 0; i < root.deviceModel.length; ++i) {
      if (root.deviceModel[i].id === root.defaultDeviceId)
        return root.deviceModel[i];
    }
    return root.deviceModel.length > 0 ? root.deviceModel[0] : null;
  }

  function _devicePercentText(device) {
    return device ? root._percentText(device.volume, device.muted) : "";
  }

  onUseCompactDevicePickerChanged: {
    if (!useCompactDevicePicker)
      pickerExpanded = false;
  }

  SectionLabel { label: root.sectionLabel }

  ThemedContainer {
    variant: "card"
    showGradient: true
    Layout.fillWidth: true
    implicitHeight: controlCol.implicitHeight + 2 * Appearance.spacingM

    ColumnLayout {
      id: controlCol
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Appearance.spacingM
      spacing: Appearance.spacingS

      // Normal (non-compact) header row
      RowLayout {
        visible: !root.compactMode
        Layout.fillWidth: true
        Loader {
          property string _ic: root.icon
          sourceComponent: String(_ic).endsWith(".svg") ? _adsSvgNorm : _adsNerdNorm
        }
        Component { id: _adsSvgNorm; SvgIcon { source: root.icon; color: root.muted ? Colors.error : Colors.primary; size: Appearance.fontSizeXL } }
        Component { id: _adsNerdNorm; Text { text: root.icon; color: root.muted ? Colors.error : Colors.primary; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeXL } }
        Text { text: root.sectionLabel.charAt(0) + root.sectionLabel.slice(1).toLowerCase(); color: Colors.text; font.pixelSize: Appearance.fontSizeMedium; font.weight: Font.Medium }
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
        spacing: Appearance.spacingXS

        RowLayout {
          Layout.fillWidth: true
          Loader {
            property string _ic: root.icon
            sourceComponent: String(_ic).endsWith(".svg") ? _adsSvg : _adsNerd
          }
          Component { id: _adsSvg; SvgIcon { source: root.icon; color: root.muted ? Colors.error : Colors.primary; size: Appearance.fontSizeXL } }
          Component { id: _adsNerd; Text { text: root.icon; color: root.muted ? Colors.error : Colors.primary; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeXL } }
          Text { text: root.sectionLabel.charAt(0) + root.sectionLabel.slice(1).toLowerCase(); color: Colors.text; font.pixelSize: Appearance.fontSizeMedium; font.weight: Font.Medium }
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

  Rectangle {
    id: compactPickerSummary
    Layout.fillWidth: true
    visible: root.useCompactDevicePicker && root.deviceModel.length > 0
    implicitHeight: 52
    radius: Appearance.radiusMedium
    color: compactSummaryHover.containsMouse ? Colors.primarySubtle : Colors.cardSurface
    border.color: root.pickerExpanded ? Colors.primary : Colors.border
    border.width: 1

    RowLayout {
      anchors.fill: parent
      anchors.margins: Appearance.paddingSmall
      spacing: Appearance.paddingSmall

      Loader {
        readonly property string rowIcon: root._currentDevice() && root._currentDevice().isDefault ? "checkmark.svg" : root.icon
        readonly property color rowColor: root._currentDevice() && root._currentDevice().isDefault ? Colors.primary : Colors.textSecondary
        sourceComponent: rowIcon.endsWith(".svg") ? deviceRowSvgIcon : deviceRowGlyphIcon
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Text {
          text: root._currentDevice() ? root._currentDevice().name : ""
          color: Colors.text
          font.pixelSize: Appearance.fontSizeMedium
          font.weight: Font.DemiBold
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Text {
          text: "Default device"
          color: Colors.textSecondary
          font.pixelSize: Appearance.fontSizeXS
          Layout.fillWidth: true
          elide: Text.ElideRight
        }
      }

      NumericText {
        text: root._devicePercentText(root._currentDevice())
        color: Colors.textSecondary
        font.pixelSize: Appearance.fontSizeXS
      }

      SvgIcon {
        source: IconHelpers.disclosureIcon(root.pickerExpanded)
        color: root.pickerExpanded ? Colors.primary : Colors.textSecondary
        size: Appearance.fontSizeMedium
      }
    }

    MouseArea {
      id: compactSummaryHover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.pickerExpanded = !root.pickerExpanded
    }
  }

  Rectangle {
    id: compactPickerList
    Layout.fillWidth: true
    visible: root.useCompactDevicePicker && root.pickerExpanded && root.deviceModel.length > 0
    radius: Appearance.radiusMedium
    color: Colors.cardSurface
    border.color: Colors.border
    border.width: 1
    implicitHeight: Math.min(compactPickerView.contentHeight + Appearance.spacingXS * 2, root.compactPickerMaxHeight)

    ListView {
      id: compactPickerView
      anchors.fill: parent
      anchors.margins: Appearance.spacingXS
      clip: true
      spacing: Appearance.spacingXXS
      boundsBehavior: Flickable.StopAtBounds
      implicitHeight: contentHeight
      model: root.deviceModel

      delegate: Rectangle {
        id: compactDeviceCard
        required property var modelData
        required property int index
        width: compactPickerView.width
        height: 42
        radius: Appearance.radiusSmall
        property bool isDefault: modelData.id === root.defaultDeviceId
        color: isDefault ? Colors.primaryStrong : (compactDeviceHover.containsMouse ? Colors.primarySubtle : "transparent")
        border.color: isDefault ? Colors.primary : "transparent"
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Appearance.paddingSmall
          anchors.rightMargin: Appearance.paddingSmall
          spacing: Appearance.paddingSmall

          Loader {
            readonly property string rowIcon: compactDeviceCard.isDefault ? "checkmark.svg" : root.icon
            readonly property color rowColor: compactDeviceCard.isDefault ? Colors.primary : Colors.textSecondary
            sourceComponent: rowIcon.endsWith(".svg") ? deviceRowSvgIcon : deviceRowGlyphIcon
          }

          Text {
            text: modelData.name
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall
            font.weight: compactDeviceCard.isDefault ? Font.DemiBold : Font.Medium
            elide: Text.ElideRight
            Layout.fillWidth: true
          }

          NumericText {
            text: root._devicePercentText(modelData)
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeXS
          }
        }

        MouseArea {
          id: compactDeviceHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            AudioService.setDefaultDevice(modelData.id);
            root.pickerExpanded = false;
          }
        }
      }
    }
  }

  // ── Device cards ─────────────────────────
  Repeater {
    model: root.useCompactDevicePicker ? [] : root.deviceModel
    delegate: Rectangle {
      id: deviceCard
      Layout.fillWidth: true
      implicitHeight: root.compactMode ? 56 : 46
      radius: Appearance.radiusMedium
      property bool isDefault: modelData.id === root.defaultDeviceId
      property bool isHovered: deviceHover.containsMouse
      color: isDefault ? Colors.primaryStrong : (isHovered ? Colors.primarySubtle : Colors.cardSurface)
      border.color: isDefault ? Colors.primary : Colors.border
      border.width: 1
      Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }

      InnerHighlight { highlightOpacity: 0.15; hoveredOpacity: 0.3; hovered: deviceCard.isDefault }

      RowLayout {
        anchors.fill: parent
        anchors.margins: Appearance.paddingSmall
        spacing: Appearance.paddingSmall
        Loader {
          readonly property string rowIcon: deviceCard.isDefault ? "checkmark.svg" : root.icon
          readonly property color rowColor: deviceCard.isDefault ? Colors.primary : Colors.textSecondary
          sourceComponent: rowIcon.endsWith(".svg") ? deviceRowSvgIcon : deviceRowGlyphIcon
        }
        Text { text: modelData.name; color: Colors.text; font.pixelSize: Appearance.fontSizeMedium; font.weight: deviceCard.isDefault ? Font.DemiBold : Font.Normal; elide: Text.ElideRight; Layout.fillWidth: true }
        NumericText { text: Math.min(Math.round(modelData.volume * 100), 100) + "%"; color: Colors.textSecondary; font.pixelSize: Appearance.fontSizeXS }
        Text { visible: !root.compactMode; text: deviceCard.isDefault ? "Default" : "Select"; color: deviceCard.isDefault ? Colors.primary : Colors.textSecondary; font.pixelSize: Appearance.fontSizeXS; font.weight: Font.Medium }
      }

      MouseArea { id: deviceHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: AudioService.setDefaultDevice(modelData.id) }
    }
  }

  Component {
    id: deviceRowSvgIcon
    SvgIcon {
      source: parent.rowIcon
      color: parent.rowColor
      size: Appearance.fontSizeLarge
    }
  }

  Component {
    id: deviceRowGlyphIcon
    Text {
      text: parent.rowIcon
      color: parent.rowColor
      font.family: Appearance.fontMono
      font.pixelSize: Appearance.fontSizeLarge
    }
  }

  EmptyState {
    Layout.fillWidth: true
    Layout.topMargin: Appearance.spacingXS
    Layout.bottomMargin: Appearance.spacingXS
    visible: root.deviceModel.length === 0
    icon: root.emptyIcon
    message: root.emptyMessage
  }
}
