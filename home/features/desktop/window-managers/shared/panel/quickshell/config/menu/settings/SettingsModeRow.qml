import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../widgets" as SharedWidgets

ColumnLayout {
    id: root

    property string label
    property string description: ""
    property string currentValue
    property var options: []
    signal modeSelected(string modeValue)
    readonly property bool narrowLayout: width < 420

    function _currentLabel() {
        for (var i = 0; i < root.options.length; i++) {
            var opt = root.options[i];
            if (opt.value === root.currentValue)
                return opt.label;
        }
        return root.currentValue || "-";
    }

    spacing: Colors.spacingS
    Layout.fillWidth: true

    Flow {
        Layout.fillWidth: true
        Layout.preferredWidth: parent.width
        spacing: Colors.spacingM

        Text {
            width: root.narrowLayout ? parent.width : Math.max(0, parent.width - modePill.implicitWidth - Colors.spacingM)
            text: root.label
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
        }

        Rectangle {
            id: modePill
            implicitWidth: selectedText.implicitWidth + 14
            implicitHeight: 24
            radius: 12
            color: Colors.modalFieldSurface
            border.color: Colors.border
            border.width: 1

            Text {
                id: selectedText
                anchors.centerIn: parent
                text: root._currentLabel()
                color: Colors.fgSecondary
                font.pixelSize: Colors.fontSizeXS
            }
        }
    }

    Text {
        visible: root.description !== ""
        text: root.description
        color: Colors.fgSecondary
        font.pixelSize: Colors.fontSizeSmall
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }

    Flow {
        Layout.fillWidth: true
        Layout.preferredWidth: parent.width
        spacing: Colors.spacingS

        Repeater {
            model: root.options
            delegate: SharedWidgets.FilterChip {
                required property var modelData
                label: modelData.label
                selected: root.currentValue === modelData.value
                onClicked: root.modeSelected(modelData.value)
            }
        }
    }
}
