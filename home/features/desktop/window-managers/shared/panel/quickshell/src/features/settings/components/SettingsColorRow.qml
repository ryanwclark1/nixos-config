import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared"
import "../../../widgets" as SharedWidgets

Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property string description: ""
    property string currentValue: ""
    property string placeholderText: "Theme default"
    property bool highlighted: false

    // These presets will store HEX values so they are compatible with QML's color property
    property var presets: [
        { value: Colors.primary.toString(), label: "Primary", color: Colors.primary },
        { value: Colors.accent.toString(), label: "Accent", color: Colors.accent },
        { value: Colors.success.toString(), label: "Success", color: Colors.success },
        { value: Colors.error.toString(), label: "Error", color: Colors.error },
        { value: Colors.warning.toString(), label: "Warning", color: Colors.warning },
        { value: Colors.info.toString(), label: "Info", color: Colors.info }
    ]

    signal colorSelected(string colorValue)
    readonly property bool narrowLayout: width < 420

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + Appearance.spacingM * 2
    radius: Appearance.radiusMedium
    color: Colors.modalFieldSurface
    border.color: Colors.border
    border.width: 1

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Appearance.spacingM
        spacing: Appearance.spacingS

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingM

            SettingsIconBox { icon: root.icon }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingXXS

                Text {
                    text: root.label
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeMedium
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Text {
                    visible: root.description !== ""
                    text: root.description
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeSmall
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle {
                width: 24
                height: 24
                radius: Appearance.radiusPill
                color: root.currentValue || "transparent"
                border.color: Colors.border
                border.width: 1
                visible: root.currentValue !== ""
                Layout.alignment: Qt.AlignTop
            }

            Rectangle {
                id: colorPill
                implicitWidth: Math.max(80, selectedText.implicitWidth + 14)
                implicitHeight: 24
                radius: Appearance.radiusCard
                color: Colors.surface
                border.color: Colors.border
                border.width: 1
                Layout.alignment: Qt.AlignTop

                Text {
                    id: selectedText
                    anchors.centerIn: parent
                    text: root.currentValue ? root.currentValue.toUpperCase() : root.placeholderText
                    color: root.currentValue ? Colors.primary : Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeXS
                    font.weight: Font.DemiBold
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width
            Layout.leftMargin: (root.icon !== "" && !root.narrowLayout) ? 38 + Appearance.spacingM : 0
            spacing: Appearance.spacingS

            SharedWidgets.FilterChip {
                label: "Default"
                icon: "arrow-clockwise.svg"
                selected: root.currentValue === ""
                onClicked: root.colorSelected("")
            }

            Repeater {
                model: root.presets
                delegate: Rectangle {
                    required property var modelData
                    width: 32
                    height: 32
                    radius: Appearance.radiusPill
                    color: modelData.color
                    border.color: root.currentValue.toLowerCase() === modelData.value.toLowerCase() ? Colors.text : Colors.border
                    border.width: root.currentValue.toLowerCase() === modelData.value.toLowerCase() ? 2 : 1
                    clip: true

                    SharedWidgets.BarTooltip {
                        text: modelData.label
                        hovered: colorMouse.containsMouse
                    }

                    MouseArea {
                        id: colorMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.colorSelected(modelData.value)
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "white"
                        opacity: colorMouse.pressed ? 0.2 : colorMouse.containsMouse ? 0.1 : 0
                    }
                }
            }

            // Custom hex input
            Rectangle {
                width: 100
                height: 32
                radius: Appearance.radiusSmall
                color: Colors.modalFieldSurface
                border.color: customInput.activeFocus ? Colors.primary : Colors.border
                border.width: 1

                TextInput {
                    id: customInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeSmall
                    font.family: Appearance.fontMono
                    selectByMouse: true
                    text: root.currentValue.startsWith("#") ? root.currentValue : ""
                    onAccepted: {
                        var t = text.trim();
                        if (t.length > 0 && !t.startsWith("#")) t = "#" + t;
                        root.colorSelected(t);
                    }

                    Text {
                        text: "#HEX"
                        color: Colors.textDisabled
                        font.pixelSize: parent.font.pixelSize
                        font.family: parent.font.family
                        visible: parent.text.length === 0 && !parent.activeFocus
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Colors.primary
        opacity: colorHighlightPulse.running ? colorHighlightPulse._opacity : 0
        visible: root.highlighted

        SequentialAnimation {
            id: colorHighlightPulse
            property real _opacity: 0
            running: root.highlighted
            loops: 2
            NumberAnimation { target: colorHighlightPulse; property: "_opacity"; from: 0; to: 0.2; duration: Appearance.durationSlow; easing.type: Easing.OutCubic }
            NumberAnimation { target: colorHighlightPulse; property: "_opacity"; from: 0.2; to: 0; duration: Appearance.durationSlow; easing.type: Easing.InCubic }
        }
    }
}
