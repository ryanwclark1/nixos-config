import QtQuick
import QtQuick.Layouts
import "../services"
import "../shared"

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
    property color accentColor: Colors.primary

    signal primaryClicked
    signal secondaryClicked

    color: Colors.withAlpha(Colors.surface, 0.34)
    radius: Colors.radiusXL
    border.color: Colors.withAlpha(root.accentColor, 0.18)
    border.width: 1
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Colors.spacingM
        width: Math.min(parent.width - 64, 520)

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 76
            height: 76
            radius: Colors.radiusPill
            color: Colors.withAlpha(root.accentColor, 0.12)
            border.color: Colors.withAlpha(root.accentColor, 0.28)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.accentColor
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeHuge
            }
        }

        Text {
            text: "READY FOR INPUT"
            color: Colors.withAlpha(root.accentColor, 0.92)
            font.pixelSize: Colors.fontSizeXXS
            font.weight: Font.Black
            font.letterSpacing: Colors.letterSpacingExtraWide
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: root.title
            color: Colors.text
            font.pixelSize: Colors.fontSizeXL
            font.weight: Font.Black
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

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Colors.spacingS
            Layout.topMargin: Colors.spacingS

            Rectangle {
                radius: Colors.radiusLarge
                color: root.accentColor
                implicitHeight: 40
                implicitWidth: emptyPrimaryText.implicitWidth + 34

                Text {
                    id: emptyPrimaryText
                    anchors.centerIn: parent
                    text: root.primaryCta
                    color: Colors.surface
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.Bold
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
                radius: Colors.radiusLarge
                color: Colors.withAlpha(Colors.surface, 0.74)
                border.color: Colors.withAlpha(root.accentColor, 0.18)
                border.width: 1
                implicitHeight: 40
                implicitWidth: emptySecondaryText.implicitWidth + 34

                Text {
                    id: emptySecondaryText
                    anchors.centerIn: parent
                    text: root.secondaryCta
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.Bold
                }

                MouseArea {
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
            visible: root.primaryHint !== "" || root.secondaryHint !== ""

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.withAlpha(root.accentColor, 0.12)
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.primaryHint !== ""
                spacing: Colors.spacingS

                Text {
                    text: root.primaryHintIcon
                    color: root.accentColor
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

            RowLayout {
                Layout.fillWidth: true
                visible: root.secondaryHint !== ""
                spacing: Colors.spacingS

                Text {
                    text: root.secondaryHintIcon
                    color: Colors.textDisabled
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeSmall
                    visible: text !== ""
                }

                Text {
                    text: root.secondaryHint
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
