import QtQuick
import QtQuick.Layouts
import "../../services"

ColumnLayout {
    id: root

    property string label
    property real min
    property real max
    property real value
    property real step: 1
    property string unit: step < 1 ? "%" : "px"
    signal moved(real v)

    readonly property real _range: max - min
    readonly property real _ratio: _range > 0 ? (value - min) / _range : 0
    readonly property bool narrowLayout: width < 420

    function _displayValue() {
        if (root.unit === "ms")
            return String(Math.round(root.value));
        if (root.step < 1 && root.unit === "%")
            return String(Math.round(root.value * 100));
        if (root.step < 1)
            return Number(root.value).toFixed(2);
        return String(Math.round(root.value));
    }

    function _displayBound(v) {
        if (root.unit === "ms")
            return String(Math.round(v));
        if (root.step < 1 && root.unit === "%")
            return String(Math.round(v * 100));
        if (root.step < 1)
            return Number(v).toFixed(2);
        return String(Math.round(v));
    }

    function _updateFromMouse(mouseX, width) {
        if (width <= 0)
            return;
        var ratio = Math.max(0, Math.min(1, mouseX / width));
        var raw = root.min + ratio * root._range;
        var stepped = Math.round(raw / root.step) * root.step;
        root.moved(Math.max(root.min, Math.min(root.max, stepped)));
    }

    spacing: Colors.spacingS
    Layout.fillWidth: true

    Flow {
        Layout.fillWidth: true
        width: parent.width

        Text {
            width: root.narrowLayout ? parent.width : Math.max(0, parent.width - sliderValuePill.implicitWidth - Colors.spacingM)
            text: root.label
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
        }

        Rectangle {
            id: sliderValuePill
            implicitHeight: 24
            implicitWidth: valueText.implicitWidth + 14
            radius: 12
            color: Colors.bgWidget
            border.color: Colors.border
            border.width: 1

            Text {
                id: valueText
                anchors.centerIn: parent
                text: root._displayValue() + root.unit
                color: Colors.fgSecondary
                font.pixelSize: Colors.fontSizeSmall
                font.family: Colors.fontMono
            }
        }
    }

    Item {
        Layout.fillWidth: true
        height: 28

        Rectangle {
            id: track
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            height: 8
            radius: 4
            color: Colors.surface

            Rectangle {
                width: track.width * Math.max(0, Math.min(1, root._ratio))
                height: parent.height
                radius: parent.radius
                color: Colors.primary

                Behavior on width {
                    NumberAnimation {
                        duration: 90
                    }
                }
            }
        }

        Rectangle {
            id: thumb
            width: sliderMouse.pressed ? 16 : 14
            height: width
            radius: width / 2
            color: Colors.primary
            border.color: Colors.bgWidget
            border.width: 2
            x: Math.max(0, Math.min(parent.width - width, parent.width * Math.max(0, Math.min(1, root._ratio)) - width / 2))
            anchors.verticalCenter: parent.verticalCenter

            Behavior on x {
                NumberAnimation {
                    duration: 90
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: 100
                }
            }
        }

        MouseArea {
            id: sliderMouse
            anchors.fill: parent
            anchors.topMargin: -4
            anchors.bottomMargin: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => root._updateFromMouse(mouse.x, width)
            onPositionChanged: mouse => {
                if (pressed)
                    root._updateFromMouse(mouse.x, width);
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        width: parent.width
        spacing: Colors.spacingS

        Text {
            width: root.narrowLayout ? parent.width : undefined
            text: root._displayBound(root.min) + root.unit
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
            font.family: Colors.fontMono
        }

        Text {
            text: root._displayBound(root.max) + root.unit
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
            font.family: Colors.fontMono
        }
    }
}
