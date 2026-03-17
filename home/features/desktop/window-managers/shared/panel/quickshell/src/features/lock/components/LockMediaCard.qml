import QtQuick
import QtQuick.Layouts
import "../../../services"

Rectangle {
    implicitWidth: 320
    implicitHeight: 60
    radius: Colors.radiusCard
    color: Colors.withAlpha(Colors.background, 0.4)
    border.color: Colors.border
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: Colors.paddingSmall
        spacing: Colors.paddingSmall

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingXXS
            Text {
                text: MediaService.trackTitle || ""
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                text: MediaService.trackArtist || ""
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeSmall
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Text {
            text: MediaService.isPlaying ? "󰏤" : "󰐊"
            color: Colors.text
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeHuge
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: MediaService.playPause()
            }
        }
    }
}
