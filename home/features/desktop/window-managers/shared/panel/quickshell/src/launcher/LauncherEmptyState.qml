import QtQuick
import QtQuick.Layouts
import "../services"
import "../shared"
import "../widgets" as SharedWidgets

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
    radius: Appearance.radiusXL
    border.color: Colors.withAlpha(root.accentColor, 0.18)
    border.width: 1
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Appearance.spacingM
        width: Math.min(parent.width - 64, 520)

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 76
            height: 76
            radius: Appearance.radiusPill
            color: Colors.withAlpha(root.accentColor, 0.12)
            border.color: Colors.withAlpha(root.accentColor, 0.28)
            border.width: 1

            Loader {
                anchors.centerIn: parent
                sourceComponent: root.icon.endsWith(".svg") ? _heroSvg : _heroNerd
            }
            Component { id: _heroSvg; SharedWidgets.SvgIcon { source: root.icon; color: root.accentColor; size: Appearance.fontSizeHuge } }
            Component { id: _heroNerd; Text { text: root.icon; color: root.accentColor; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeHuge } }
        }

        Text {
            text: "READY FOR INPUT"
            color: Colors.withAlpha(root.accentColor, 0.92)
            font.pixelSize: Appearance.fontSizeXXS
            font.weight: Font.Black
            font.letterSpacing: Appearance.letterSpacingExtraWide
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: root.title
            color: Colors.text
            font.pixelSize: Appearance.fontSizeXL
            font.weight: Font.Black
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: root.subtitle
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeSmall
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacingS
            Layout.topMargin: Appearance.spacingS

            Rectangle {
                radius: Appearance.radiusLarge
                color: root.accentColor
                implicitHeight: 40
                implicitWidth: emptyPrimaryText.implicitWidth + 34

                Text {
                    id: emptyPrimaryText
                    anchors.centerIn: parent
                    text: root.primaryCta
                    color: Colors.surface
                    font.pixelSize: Appearance.fontSizeSmall
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
                radius: Appearance.radiusLarge
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
                    font.pixelSize: Appearance.fontSizeSmall
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
            Layout.topMargin: Appearance.spacingM
            spacing: Appearance.spacingS
            visible: root.primaryHint !== "" || root.secondaryHint !== ""

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.withAlpha(root.accentColor, 0.12)
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.primaryHint !== ""
                spacing: Appearance.spacingS

                Loader {
                    visible: root.primaryHintIcon !== ""
                    sourceComponent: root.primaryHintIcon.endsWith(".svg") ? _phSvg : _phNerd
                }
                Component { id: _phSvg; SharedWidgets.SvgIcon { source: root.primaryHintIcon; color: root.accentColor; size: Appearance.fontSizeSmall } }
                Component { id: _phNerd; Text { text: root.primaryHintIcon; color: root.accentColor; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeSmall } }

                Text {
                    text: root.primaryHint
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeXS
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.secondaryHint !== ""
                spacing: Appearance.spacingS

                Loader {
                    visible: root.secondaryHintIcon !== ""
                    sourceComponent: root.secondaryHintIcon.endsWith(".svg") ? _shSvg : _shNerd
                }
                Component { id: _shSvg; SharedWidgets.SvgIcon { source: root.secondaryHintIcon; color: Colors.textDisabled; size: Appearance.fontSizeSmall } }
                Component { id: _shNerd; Text { text: root.secondaryHintIcon; color: Colors.textDisabled; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeSmall } }

                Text {
                    text: root.secondaryHint
                    color: Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeXS
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
