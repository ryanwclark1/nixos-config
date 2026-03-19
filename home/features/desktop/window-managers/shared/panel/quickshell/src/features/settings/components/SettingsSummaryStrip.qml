pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../services"

Flow {
    id: root

    property var ownerMeta: null

    readonly property var summaryItems: {
        if (!ownerMeta)
            return [];
        return [
            {
                label: "Service",
                value: ownerMeta.service || "-"
            },
            {
                label: "Domain",
                value: ownerMeta.configDomain || "-"
            },
            {
                label: "Surface",
                value: ownerMeta.surface || "none"
            }
        ];
    }

    width: parent ? parent.width : implicitWidth
    spacing: Colors.spacingS
    visible: summaryItems.length > 0

    Repeater {
        model: root.summaryItems

        delegate: Rectangle {
            required property var modelData

            radius: Colors.radiusPill
            color: Colors.withAlpha(Colors.surface, 0.58)
            border.color: Colors.border
            border.width: 1
            implicitHeight: 26
            implicitWidth: valueText.implicitWidth + Colors.spacingM * 2

            Text {
                id: valueText
                anchors.centerIn: parent
                text: modelData.label + ": " + modelData.value
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXXS
                font.weight: Font.DemiBold
                font.letterSpacing: Colors.letterSpacingWide
            }
        }
    }
}
