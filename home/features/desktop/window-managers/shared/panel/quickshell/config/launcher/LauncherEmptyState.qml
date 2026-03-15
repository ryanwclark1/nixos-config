import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
    id: root

    required property string icon
    required property string title
    required property string subtitle
    required property string primaryCta
    required property string secondaryCta
    required property string primaryHint
    required property string primaryHintIcon
    required property string secondaryHint
    required property string secondaryHintIcon

    signal primaryClicked
    signal secondaryClicked

    color: Colors.bgWidget
    radius: Colors.radiusMedium
    border.color: Colors.border
    border.width: 1
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Colors.spacingS

        Text {
            text: root.icon
            color: Colors.textDisabled
            font.family: Colors.fontMono
            font.pixelSize: 26
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: root.title
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            font.weight: Font.DemiBold
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: root.subtitle
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeSmall
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Colors.spacingS

            Rectangle {
                radius: Colors.radiusPill
                color: Colors.primary
                implicitHeight: 30
                implicitWidth: emptyPrimaryText.implicitWidth + 20

                Text {
                    id: emptyPrimaryText
                    anchors.centerIn: parent
                    text: root.primaryCta
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.primaryClicked()
                }
            }

            Rectangle {
                visible: root.secondaryCta !== ""
                radius: Colors.radiusPill
                color: Colors.surface
                border.color: Colors.border
                border.width: 1
                implicitHeight: 30
                implicitWidth: emptySecondaryText.implicitWidth + 20

                Text {
                    id: emptySecondaryText
                    anchors.centerIn: parent
                    text: root.secondaryCta
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.secondaryClicked()
                }
            }
        }

        RowLayout {
            Layout.maximumWidth: Math.min(parent.width - 24, 460)
            Layout.alignment: Qt.AlignHCenter
            spacing: Colors.spacingXS

            Text {
                text: root.primaryHintIcon
                color: Colors.textDisabled
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeSmall
                visible: text !== ""
                Layout.alignment: Qt.AlignTop
            }

            Text {
                text: root.primaryHint
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }

        RowLayout {
            visible: root.secondaryHint !== ""
            Layout.maximumWidth: Math.min(parent.width - 24, 460)
            Layout.alignment: Qt.AlignHCenter
            spacing: Colors.spacingXS

            Text {
                text: root.secondaryHintIcon
                color: Colors.textDisabled
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeSmall
                visible: text !== ""
                Layout.alignment: Qt.AlignTop
            }

            Text {
                text: root.secondaryHint
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }
    }
}
