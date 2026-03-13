import QtQuick
import QtQuick.Layouts
import "../../services"

RowLayout {
  id: root

  property var owner: null
  spacing: Colors.spacingS
  visible: !!owner

  function ownerField(name, fallback) {
    if (!owner || owner[name] === undefined || owner[name] === null || owner[name] === "") return fallback;
    return String(owner[name]);
  }

  function ownerChip(label, value) {
    return label + ": " + value;
  }

  Repeater {
    model: [
      { key: "service", label: "Service", fallback: "-" },
      { key: "configDomain", label: "Domain", fallback: "-" },
      { key: "surface", label: "Surface", fallback: "none" }
    ]

    delegate: Rectangle {
      required property var modelData
      implicitHeight: 24
      implicitWidth: badgeText.implicitWidth + 16
      radius: Colors.radiusPill
      color: Colors.bgWidget
      border.color: Colors.border
      border.width: 1

      Text {
        id: badgeText
        anchors.centerIn: parent
        text: root.ownerChip(modelData.label, root.ownerField(modelData.key, modelData.fallback))
        color: Colors.fgSecondary
        font.pixelSize: Colors.fontSizeXS
      }
    }
  }
}
