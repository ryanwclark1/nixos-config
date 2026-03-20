import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../services/IconHelpers.js" as IconHelpers
import "../../../shared"
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
    property bool highlighted: false
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
    implicitHeight: mainLayout.implicitHeight + Appearance.spacingM * 2
    radius: Appearance.radiusMedium
    color: Colors.modalFieldSurface
    border.color: root.expanded ? Colors.primary : Colors.border
    border.width: 1

    Behavior on border.color {
        enabled: !Colors.isTransitioning
        CAnim {}
    }

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

            SettingsIconBox {
                visible: root.icon !== ""
                icon: root.icon
            }

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
        }

        Rectangle {
            id: triggerButton
            Layout.fillWidth: true
            implicitHeight: 40
            radius: Appearance.radiusSmall
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
                anchors.leftMargin: Appearance.spacingM
                anchors.rightMargin: Appearance.spacingM
                spacing: Appearance.spacingS

                Text {
                    visible: root.currentIcon() !== ""
                    text: root.currentIcon()
                    color: Colors.primary
                    font.family: Appearance.fontMono
                    font.pixelSize: Appearance.fontSizeMedium
                }

                Text {
                    Layout.fillWidth: true
                    text: root.currentLabel()
                    color: root.currentValue !== "" ? Colors.text : Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: root.currentValue !== "" ? Font.Medium : Font.Normal
                    elide: Text.ElideRight
                }

                Rectangle {
                    implicitWidth: countText.implicitWidth + Appearance.spacingM
                    implicitHeight: 22
                    radius: Appearance.radiusPill
                    color: Colors.primaryFaint
                    visible: root.options.length > 0

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: root.options.length + " options"
                        color: Colors.textSecondary
                        font.pixelSize: Appearance.fontSizeXXS
                        font.weight: Font.DemiBold
                    }
                }

                SharedWidgets.SvgIcon {
                    source: IconHelpers.disclosureIcon(root.expanded)
                    color: Colors.textSecondary
                    size: Appearance.fontSizeMedium
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
            radius: Appearance.radiusSmall
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1
            implicitHeight: Math.min(optionsList.contentHeight, root.maxMenuHeight) + Appearance.spacingXS * 2

            ListView {
                id: optionsList
                anchors.fill: parent
                anchors.margins: Appearance.spacingXS
                clip: true
                spacing: Appearance.spacingXXS
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
                    radius: Appearance.radiusXS
                    color: selected
                        ? Colors.primaryAccent
                        : optionMouse.containsMouse
                            ? Colors.highlightLight
                            : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.spacingS
                        anchors.rightMargin: Appearance.spacingS
                        spacing: Appearance.spacingS

                        Loader {
                            visible: !!modelData.icon
                            property string _ic: modelData.icon || ""
                            property color _co: optionDelegate.selected ? Colors.primary : Colors.textSecondary
                            sourceComponent: String(_ic).endsWith(".svg") ? _srSvg : _srNerd
                        }
                        Component { id: _srSvg; SvgIcon { source: parent._ic; color: parent._co; size: Appearance.fontSizeMedium } }
                        Component { id: _srNerd; Text { text: parent._ic; color: parent._co; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeMedium } }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.label || String(modelData.value || "")
                            color: optionDelegate.selected ? Colors.primary : Colors.text
                            font.pixelSize: Appearance.fontSizeSmall
                            font.weight: optionDelegate.selected ? Font.DemiBold : Font.Medium
                            elide: Text.ElideRight
                        }

                        SharedWidgets.SvgIcon {
                            visible: optionDelegate.selected
                            source: "checkmark.svg"
                            color: Colors.primary
                            size: Appearance.fontSizeSmall
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

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Colors.primary
        opacity: selectHighlightPulse.running ? selectHighlightPulse._opacity : 0
        visible: root.highlighted

        SequentialAnimation {
            id: selectHighlightPulse
            property real _opacity: 0
            running: root.highlighted
            loops: 2
            NumberAnimation { target: selectHighlightPulse; property: "_opacity"; from: 0; to: 0.2; duration: Appearance.durationSlow; easing.type: Easing.OutCubic }
            NumberAnimation { target: selectHighlightPulse; property: "_opacity"; from: 0.2; to: 0; duration: Appearance.durationSlow; easing.type: Easing.InCubic }
        }
    }
}
