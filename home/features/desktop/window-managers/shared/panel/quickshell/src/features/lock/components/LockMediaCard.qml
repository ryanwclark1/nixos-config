import QtQuick
import QtQuick.Layouts
import "../../../services"

Rectangle {
    implicitWidth: 320
    implicitHeight: 60
    radius: Appearance.radiusCard
    color: Colors.withAlpha(Colors.background, 0.4)
    border.color: Colors.border
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: Appearance.paddingSmall
        spacing: Appearance.paddingSmall

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingXXS
            Text {
                text: MediaService.trackTitle || ""
                color: Colors.text
                font.pixelSize: Appearance.fontSizeMedium
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                text: MediaService.trackArtist || ""
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeSmall
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Text {
            text: MediaService.isPlaying ? "󰏤" : "󰐊"
            color: Colors.text
            font.family: Appearance.fontMono
            font.pixelSize: Appearance.fontSizeHuge
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: MediaService.playPause()
            }
        }
    }
}
