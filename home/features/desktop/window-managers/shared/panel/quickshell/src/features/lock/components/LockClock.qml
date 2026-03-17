import QtQuick
import QtQuick.Layouts
import "../../services"

ColumnLayout {
    id: root
    required property var lockClock
    required property bool compact
    Layout.alignment: Qt.AlignHCenter
    spacing: compact ? 2 : 5

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(root.lockClock.date, "HH:mm")
        color: Colors.text
        font.pixelSize: root.compact ? 80 : 120
        font.weight: Font.Bold
    }
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(root.lockClock.date, "dddd, MMMM d")
        color: Colors.textSecondary
        font.pixelSize: root.compact ? 18 : 24
    }
}
