import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../../widgets" as SharedWidgets
import ".."

Rectangle {
    id: root

    required property bool open
    required property bool compactMode
    required property int overlayInset
    required property string addSection
    required property bool verticalBar
    required property var sectionLabelFn
    required property string searchQuery
    required property var availableWidgets

    signal closeRequested
    signal searchQueryEdited(string value)
    signal widgetAdded(string widgetType)

    anchors.fill: parent
    visible: root.open
    color: Qt.rgba(0, 0, 0, 0.45)
    z: 20

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    Rectangle {
        width: Math.min(root.compactMode ? 560 : 760, parent.width - root.overlayInset * 2)
        height: Math.min(680, parent.height - root.overlayInset * 2)
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: Math.max(root.overlayInset, (parent.height - height) / 2)
        anchors.leftMargin: Math.max(root.overlayInset, (parent.width - width) / 2)
        radius: Colors.radiusLarge
        color: Colors.popupSurface
        border.color: Colors.border
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.paddingLarge
            spacing: Colors.spacingM

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingS

                Text {
                    width: root.compactMode ? parent.width : Math.max(0, parent.width - closePickerButton.implicitWidth - Colors.spacingS)
                    text: "Add Widget to " + root.sectionLabelFn(root.addSection)
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeXL
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }

                SettingsActionButton {
                    id: closePickerButton
                    compact: true
                    iconName: "dismiss.svg"
                    label: "Close"
                    onClicked: root.closeRequested()
                }
            }

            SettingsTextInputRow {
                label: "Search"
                leadingIcon: "search-visual.svg"
                placeholderText: "Filter widgets by name"
                text: root.searchQuery
                onTextEdited: value => root.searchQueryEdited(value)
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: pickerColumn.implicitHeight

                Column {
                    id: pickerColumn
                    width: parent.width
                    spacing: Colors.spacingS

                    Repeater {
                        model: root.availableWidgets
                        delegate: SettingsListRow {
                            required property var modelData
                            width: pickerColumn.width
                            minimumHeight: root.compactMode ? 88 : 64

                            Text {
                                text: modelData.icon
                                color: Colors.primary
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeLarge
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Colors.spacingXXS

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Colors.spacingS

                                    Text {
                                        text: modelData.label
                                        color: Colors.text
                                        font.pixelSize: Colors.fontSizeMedium
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }

                                    Rectangle {
                                        radius: Colors.radiusSmall
                                        color: String(modelData.section || "") === root.addSection ? Colors.primaryStrong : Colors.cardSurface
                                        border.color: String(modelData.section || "") === root.addSection ? Colors.primary : Colors.border
                                        border.width: 1
                                        implicitWidth: sectionBadgeLabel.implicitWidth + Colors.spacingM
                                        implicitHeight: sectionBadgeLabel.implicitHeight + Colors.spacingXS

                                        Text {
                                            id: sectionBadgeLabel
                                            anchors.centerIn: parent
                                            text: "Best in " + root.sectionLabelFn(String(modelData.section || "right"))
                                            color: String(modelData.section || "") === root.addSection ? Colors.primary : Colors.textSecondary
                                            font.pixelSize: Colors.fontSizeXS
                                            font.weight: Font.Medium
                                        }
                                    }

                                    Rectangle {
                                        visible: root.verticalBar
                                        radius: Colors.radiusSmall
                                        color: Colors.cardSurface
                                        border.color: Colors.border
                                        border.width: 1
                                        implicitWidth: verticalHintLabel.implicitWidth + Colors.spacingM
                                        implicitHeight: verticalHintLabel.implicitHeight + Colors.spacingXS

                                        Text {
                                            id: verticalHintLabel
                                            anchors.centerIn: parent
                                            text: BarWidgetRegistry.verticalHintLabel(modelData.widgetType)
                                            color: Colors.textSecondary
                                            font.pixelSize: Colors.fontSizeXS
                                            font.weight: Font.Medium
                                        }
                                    }
                                }

                                Text {
                                    text: modelData.description || ""
                                    color: Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }
                            }

                            SettingsActionButton {
                                compact: true
                                emphasized: true
                                iconName: "󰐕"
                                label: "Add"
                                onClicked: root.widgetAdded(modelData.widgetType)
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        visible: root.availableWidgets.length === 0
                        text: "No widgets match \"" + root.searchQuery + "\"."
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
