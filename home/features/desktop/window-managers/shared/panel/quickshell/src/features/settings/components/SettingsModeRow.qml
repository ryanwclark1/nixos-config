import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets

Rectangle {
    id: root

    property string label
    property string icon: ""
    property string description: ""
    property string currentValue
    property var options: []
    property bool highlighted: false
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

            SettingsIconBox { icon: root.icon }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingXXS

                Text {
                    text: root.label
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Text {
                    visible: root.description !== ""
                    text: root.description
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle {
                id: modePill
                implicitWidth: selectedText.implicitWidth + 14
                implicitHeight: 24
                radius: Colors.radiusCard
                color: Colors.surface
                border.color: Colors.border
                border.width: 1
                Layout.alignment: Qt.AlignTop

                Text {
                    id: selectedText
                    anchors.centerIn: parent
                    text: root._currentLabel()
                    color: Colors.primary
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.DemiBold
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width
            Layout.leftMargin: (root.icon !== "" && !root.narrowLayout) ? 38 + Colors.spacingM : 0
            spacing: Colors.spacingS

            Repeater {
                model: root.options
                delegate: SharedWidgets.FilterChip {
                    required property var modelData
                    label: modelData.label
                    icon: modelData.icon || ""
                    selected: root.currentValue === modelData.value
                    onClicked: root.modeSelected(modelData.value)
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Colors.primary
        opacity: modeHighlightPulse.running ? modeHighlightPulse._opacity : 0
        visible: root.highlighted

        SequentialAnimation {
            id: modeHighlightPulse
            property real _opacity: 0
            running: root.highlighted
            loops: 2
            NumberAnimation { target: modeHighlightPulse; property: "_opacity"; from: 0; to: 0.2; duration: Colors.durationSlow; easing.type: Easing.OutCubic }
            NumberAnimation { target: modeHighlightPulse; property: "_opacity"; from: 0.2; to: 0; duration: Colors.durationSlow; easing.type: Easing.InCubic }
        }
    }
}
