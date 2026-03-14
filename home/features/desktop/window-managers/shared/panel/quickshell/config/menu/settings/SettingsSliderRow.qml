import QtQuick
import QtQuick.Layouts
import "../../services"

Rectangle {
    id: root

    property string label
    property string icon: ""
    property real min
    property real max
    property real value
    property real step: 1
    property string unit: ""
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

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + Colors.spacingM * 2
    radius: Colors.radiusMedium
    color: Colors.modalFieldSurface
    border.color: Colors.border
    border.width: 1

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Colors.spacingM
        spacing: Colors.spacingS

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingM

            Rectangle {
                visible: root.icon !== ""
                width: 38
                height: 38
                radius: Colors.radiusSmall
                color: Colors.withAlpha(Colors.text, 0.06)
                border.color: Colors.border
                border.width: 1
                Layout.alignment: Qt.AlignTop

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    color: Colors.textSecondary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXL
                }
            }

            Text {
                text: root.label
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Rectangle {
                id: sliderValuePill
                implicitHeight: 24
                implicitWidth: valueText.implicitWidth + 14
                radius: 12
                color: Colors.surface
                border.color: Colors.border
                border.width: 1
                Layout.alignment: Qt.AlignTop

                Text {
                    id: valueText
                    anchors.centerIn: parent
                    text: root._displayValue() + root.unit
                    color: Colors.primary
                    font.pixelSize: Colors.fontSizeSmall
                    font.family: Colors.fontMono
                    font.weight: Font.DemiBold
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.leftMargin: (root.icon !== "" && !root.narrowLayout) ? 38 + Colors.spacingM : 0
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
                border.color: Colors.modalFieldSurface
                border.width: 2
                x: Math.max(0, Math.min(parent.width - width, parent.width * Math.max(0, Math.min(1, root._ratio)) - width / 2))
                anchors.verticalCenter: parent.verticalCenter

                Behavior on x {
                    NumberAnimation {
                        duration: 90
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

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: (root.icon !== "" && !root.narrowLayout) ? 38 + Colors.spacingM : 0

            Text {
                text: root._displayBound(root.min) + root.unit
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                font.family: Colors.fontMono
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root._displayBound(root.max) + root.unit
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                font.family: Colors.fontMono
            }
        }
    }
}
