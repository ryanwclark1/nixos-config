import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../../shared"

Item {
    id: root

    anchors.fill: parent

    readonly property string position: Config.backgroundClockPosition

    // Map position string to anchor values
    readonly property bool _top: position.indexOf("top") !== -1
    readonly property bool _bottom: position.indexOf("bottom") !== -1
    readonly property bool _left: position.indexOf("left") !== -1
    readonly property bool _right: position.indexOf("right") !== -1
    readonly property bool _center: position === "center"

    ColumnLayout {
        id: clockLayout
        spacing: Colors.spacingXS

        anchors.horizontalCenter: root._center || (!root._left && !root._right) ? parent.horizontalCenter : undefined
        anchors.verticalCenter: root._center || (!root._top && !root._bottom) ? parent.verticalCenter : undefined
        anchors.top: root._top ? parent.top : undefined
        anchors.bottom: root._bottom ? parent.bottom : undefined
        anchors.left: root._left ? parent.left : undefined
        anchors.right: root._right ? parent.right : undefined
        anchors.margins: Colors.spacingXL * 2

        Text {
            id: timeText
            Layout.alignment: Qt.AlignHCenter
            text: {
                var d = SystemClock.now;
                if (!d) return "";
                var h = d.getHours();
                var m = d.getMinutes();
                if (!Config.timeUse24Hour) {
                    h = h % 12 || 12;
                }
                return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m;
            }
            color: Colors.withAlpha(Colors.text, 0.85)
            font.pixelSize: 96
            font.weight: Font.Light
            font.family: Colors.font
            font.letterSpacing: Colors.letterSpacingTight
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: {
                var d = SystemClock.now;
                if (!d) return "";
                return Qt.formatDate(d, "dddd, MMMM d");
            }
            color: Colors.withAlpha(Colors.text, 0.6)
            font.pixelSize: Colors.fontSizeXL
            font.family: Colors.font
        }
    }
}
