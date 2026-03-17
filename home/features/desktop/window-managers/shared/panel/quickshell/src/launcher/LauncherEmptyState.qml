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

    color: Colors.withAlpha(Colors.surface, 0.4)
    radius: Colors.radiusLarge
    border.color: Colors.withAlpha(Colors.primary, 0.12)
    border.width: 1
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Colors.spacingM
        width: Math.min(parent.width - 64, 460)

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Colors.spacingXS

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 64
                height: 64
                radius: Colors.radiusPill
                color: Colors.withAlpha(Colors.primary, 0.1)
                border.color: Colors.withAlpha(Colors.primary, 0.2)
                border.width: 1
                Layout.bottomMargin: Colors.spacingS

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeHuge
                }
            }

            Text {
                text: root.title
                color: Colors.text
                font.pixelSize: Colors.fontSizeLarge
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                text: root.subtitle
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeSmall
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Colors.spacingS
            Layout.topMargin: Colors.spacingS

            Rectangle {
                radius: Colors.radiusMedium
                color: Colors.primary
                implicitHeight: 38
                implicitWidth: emptyPrimaryText.implicitWidth + 32
                scale: primaryHover.containsMouse ? 1.02 : 1.0
                Behavior on scale { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }

                Text {
                    id: emptyPrimaryText
                    anchors.centerIn: parent
                    text: root.primaryCta
                    color: Colors.surface
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: primaryHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.primaryClicked()
                }
            }

            Rectangle {
                visible: root.secondaryCta !== ""
                radius: Colors.radiusMedium
                color: Colors.withAlpha(Colors.surface, 0.6)
                border.color: Colors.border
                border.width: 1
                implicitHeight: 38
                implicitWidth: emptySecondaryText.implicitWidth + 32
                scale: secondaryHover.containsMouse ? 1.02 : 1.0
                Behavior on scale { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }

                Text {
                    id: emptySecondaryText
                    anchors.centerIn: parent
                    text: root.secondaryCta
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: secondaryHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.secondaryClicked()
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Colors.spacingM
            spacing: Colors.spacingS
            visible: root.primaryHint !== ""

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.withAlpha(Colors.border, 0.4)
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Colors.spacingS
                opacity: 0.7

                Text {
                    text: root.primaryHintIcon
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeSmall
                    visible: text !== ""
                }

                Text {
                    text: root.primaryHint
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
