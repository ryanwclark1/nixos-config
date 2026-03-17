import QtQuick
import QtQuick.Layouts
import "../services"

RowLayout {
    id: root

    required property string hintText
    required property string primaryAction
    required property string secondaryAction
    required property string tertiaryAction
    property bool compact: false

    Layout.fillWidth: true
    spacing: root.compact ? Colors.spacingXS : Colors.paddingSmall

    Text {
        Layout.fillWidth: true
        text: root.hintText
        color: Colors.textSecondary
        font.pixelSize: root.compact ? Colors.fontSizeXS : Colors.fontSizeSmall
        elide: Text.ElideRight
        maximumLineCount: 1
        wrapMode: Text.NoWrap
    }

    Row {
        spacing: root.compact ? Colors.spacingXXS : Colors.spacingXS

        Rectangle {
            radius: Colors.radiusPill
            color: Colors.withAlpha(Colors.primary, 0.12)
            border.color: Colors.withAlpha(Colors.primary, 0.3)
            border.width: 1
            implicitHeight: root.compact ? 22 : 24
            implicitWidth: primaryText.implicitWidth + (root.compact ? 12 : 14)

            Text {
                id: primaryText
                anchors.centerIn: parent
                text: root.primaryAction
                color: Colors.primary
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            radius: Colors.radiusPill
            color: Colors.withAlpha(Colors.textSecondary, 0.08)
            border.color: Colors.withAlpha(Colors.primary, 0.14)
            border.width: 1
            implicitHeight: root.compact ? 22 : 24
            implicitWidth: secondaryText.implicitWidth + (root.compact ? 12 : 14)

            Text {
                id: secondaryText
                anchors.centerIn: parent
                text: root.secondaryAction
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            radius: Colors.radiusPill
            color: Colors.surface
            border.color: Colors.withAlpha(Colors.primary, 0.12)
            border.width: 1
            implicitHeight: root.compact ? 22 : 24
            implicitWidth: tertiaryText.implicitWidth + (root.compact ? 12 : 14)

            Text {
                id: tertiaryText
                anchors.centerIn: parent
                text: root.tertiaryAction
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.DemiBold
            }
        }
    }
}
