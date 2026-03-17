import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets

Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property string description: ""
    property string currentValue: ""
    property string placeholderText: "Select"
    property var options: []
    property bool expanded: false
    property int maxMenuHeight: 240
    signal optionSelected(string value)

    function currentOption() {
        for (var i = 0; i < root.options.length; ++i) {
            var option = root.options[i];
            if (String(option.value) === String(root.currentValue))
                return option;
        }
        return null;
    }

    function currentLabel() {
        var option = currentOption();
        if (option && option.label !== undefined && option.label !== null && option.label !== "")
            return String(option.label);
        return root.currentValue !== "" ? root.currentValue : root.placeholderText;
    }

    function currentIcon() {
        var option = currentOption();
        if (option && option.icon !== undefined && option.icon !== null)
            return String(option.icon);
        return "";
    }

    function closeMenu() {
        root.expanded = false;
    }

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + Colors.spacingM * 2
    radius: Colors.radiusMedium
    color: Colors.modalFieldSurface
    border.color: root.expanded ? Colors.primary : Colors.border
    border.width: 1

    Behavior on border.color {
        ColorAnimation {
            duration: Colors.durationFast
        }
    }

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

            SettingsIconBox {
                visible: root.icon !== ""
                icon: root.icon
            }

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
        }

        Rectangle {
            id: triggerButton
            Layout.fillWidth: true
            implicitHeight: 40
            radius: Colors.radiusSmall
            color: Colors.surface
            border.color: root.expanded ? Colors.primary : Colors.border
            border.width: 1

            SharedWidgets.StateLayer {
                id: triggerState
                hovered: triggerMouse.containsMouse
                pressed: triggerMouse.pressed
                stateColor: Colors.primary
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Colors.spacingM
                anchors.rightMargin: Colors.spacingM
                spacing: Colors.spacingS

                Text {
                    visible: root.currentIcon() !== ""
                    text: root.currentIcon()
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeMedium
                }

                Text {
                    Layout.fillWidth: true
                    text: root.currentLabel()
                    color: root.currentValue !== "" ? Colors.text : Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: root.currentValue !== "" ? Font.Medium : Font.Normal
                    elide: Text.ElideRight
                }

                Rectangle {
                    implicitWidth: countText.implicitWidth + Colors.spacingM
                    implicitHeight: 22
                    radius: Colors.radiusPill
                    color: Colors.withAlpha(Colors.primary, 0.08)
                    visible: root.options.length > 0

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: root.options.length + " options"
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeXXS
                        font.weight: Font.DemiBold
                    }
                }

                Text {
                    text: root.expanded ? "󰅀" : "󰅂"
                    color: Colors.textSecondary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeMedium
                }
            }

            MouseArea {
                id: triggerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    triggerState.burst(mouseX, mouseY);
                    root.expanded = !root.expanded;
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: root.expanded
            radius: Colors.radiusSmall
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1
            implicitHeight: Math.min(optionsList.contentHeight, root.maxMenuHeight) + Colors.spacingXS * 2

            ListView {
                id: optionsList
                anchors.fill: parent
                anchors.margins: Colors.spacingXS
                clip: true
                spacing: Colors.spacingXXS
                boundsBehavior: Flickable.StopAtBounds
                implicitHeight: contentHeight
                model: root.options

                delegate: Rectangle {
                    id: optionDelegate
                    required property var modelData
                    required property int index
                    readonly property bool selected: String(modelData.value) === String(root.currentValue)
                    width: optionsList.width
                    height: 34
                    radius: Colors.radiusXS
                    color: selected
                        ? Colors.withAlpha(Colors.primary, 0.14)
                        : optionMouse.containsMouse
                            ? Colors.highlightLight
                            : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Colors.spacingS
                        anchors.rightMargin: Colors.spacingS
                        spacing: Colors.spacingS

                        Text {
                            visible: !!modelData.icon
                            text: modelData.icon || ""
                            color: optionDelegate.selected ? Colors.primary : Colors.textSecondary
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeMedium
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.label || String(modelData.value || "")
                            color: optionDelegate.selected ? Colors.primary : Colors.text
                            font.pixelSize: Colors.fontSizeSmall
                            font.weight: optionDelegate.selected ? Font.DemiBold : Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: optionDelegate.selected
                            text: "󰄬"
                            color: Colors.primary
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeSmall
                        }
                    }

                    MouseArea {
                        id: optionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.optionSelected(String(modelData.value));
                            root.closeMenu();
                        }
                    }
                }
            }
        }
    }
}
