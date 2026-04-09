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

    function occupancySectionsLabel(sections) {
        var items = Array.isArray(sections) ? sections : [];
        if (items.length === 0)
            return "";
        var labels = [];
        for (var i = 0; i < items.length; ++i)
            labels.push(root.sectionLabelFn(String(items[i] || "")));
        return "In " + labels.join(" + ");
    }

    function occupancyCountLabel(modelData) {
        var count = Number(modelData && modelData.instanceCount !== undefined ? modelData.instanceCount : 0);
        if (!isFinite(count) || count <= 0)
            return "";
        if (count === 1)
            return "1 on bar";
        return String(Math.round(count)) + " on bar";
    }

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
        radius: Appearance.radiusLarge
        color: Colors.popupSurface
        border.color: Colors.border
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.paddingLarge
            spacing: Appearance.spacingM

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Appearance.spacingS

                Text {
                    width: root.compactMode ? parent.width : Math.max(0, parent.width - closePickerButton.implicitWidth - Appearance.spacingS)
                    text: "Add Widget to " + root.sectionLabelFn(root.addSection)
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeXL
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
                    spacing: Appearance.spacingS

                    Repeater {
                        model: root.availableWidgets
                        delegate: SettingsListRow {
                            required property var modelData
                            width: pickerColumn.width
                            minimumHeight: root.compactMode ? 88 : 64

                            SettingsMetricIcon { icon: modelData.icon }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacingXXS

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.spacingS

                                    Text {
                                        text: modelData.label
                                        color: Colors.text
                                        font.pixelSize: Appearance.fontSizeMedium
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }

                                    Rectangle {
                                        radius: Appearance.radiusSmall
                                        color: String(modelData.section || "") === root.addSection ? Colors.primaryStrong : Colors.cardSurface
                                        border.color: String(modelData.section || "") === root.addSection ? Colors.primary : Colors.border
                                        border.width: 1
                                        implicitWidth: sectionBadgeLabel.implicitWidth + Appearance.spacingM
                                        implicitHeight: sectionBadgeLabel.implicitHeight + Appearance.spacingXS

                                        Text {
                                            id: sectionBadgeLabel
                                            anchors.centerIn: parent
                                            text: "Best in " + root.sectionLabelFn(String(modelData.section || "right"))
                                            color: String(modelData.section || "") === root.addSection ? Colors.primary : Colors.textSecondary
                                            font.pixelSize: Appearance.fontSizeXS
                                            font.weight: Font.Medium
                                        }
                                    }

                                    Rectangle {
                                        visible: Number(modelData.instanceCount || 0) > 0
                                        radius: Appearance.radiusSmall
                                        color: modelData.canAdd === false ? Colors.withAlpha(Colors.warning, 0.14) : Colors.cardSurface
                                        border.color: modelData.canAdd === false ? Colors.warning : Colors.border
                                        border.width: 1
                                        implicitWidth: occupancyCountLabelText.implicitWidth + Appearance.spacingM
                                        implicitHeight: occupancyCountLabelText.implicitHeight + Appearance.spacingXS

                                        Text {
                                            id: occupancyCountLabelText
                                            anchors.centerIn: parent
                                            text: root.occupancyCountLabel(modelData)
                                            color: modelData.canAdd === false ? Colors.warning : Colors.textSecondary
                                            font.pixelSize: Appearance.fontSizeXS
                                            font.weight: Font.Medium
                                        }
                                    }

                                    Rectangle {
                                        visible: Number(modelData.instanceCount || 0) > 0
                                        radius: Appearance.radiusSmall
                                        color: Colors.cardSurface
                                        border.color: Colors.border
                                        border.width: 1
                                        implicitWidth: occupancySectionsLabelText.implicitWidth + Appearance.spacingM
                                        implicitHeight: occupancySectionsLabelText.implicitHeight + Appearance.spacingXS

                                        Text {
                                            id: occupancySectionsLabelText
                                            anchors.centerIn: parent
                                            text: root.occupancySectionsLabel(modelData.existingSections)
                                            color: Colors.textSecondary
                                            font.pixelSize: Appearance.fontSizeXS
                                            font.weight: Font.Medium
                                        }
                                    }

                                    Rectangle {
                                        visible: root.verticalBar
                                        radius: Appearance.radiusSmall
                                        color: Colors.cardSurface
                                        border.color: Colors.border
                                        border.width: 1
                                        implicitWidth: verticalHintLabel.implicitWidth + Appearance.spacingM
                                        implicitHeight: verticalHintLabel.implicitHeight + Appearance.spacingXS

                                        Text {
                                            id: verticalHintLabel
                                            anchors.centerIn: parent
                                            text: BarWidgetRegistry.verticalHintLabel(modelData.widgetType)
                                            color: Colors.textSecondary
                                            font.pixelSize: Appearance.fontSizeXS
                                            font.weight: Font.Medium
                                        }
                                    }
                                }

                                Text {
                                    text: modelData.description || ""
                                    color: Colors.textSecondary
                                    font.pixelSize: Appearance.fontSizeXS
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }
                            }

                            SettingsActionButton {
                                compact: true
                                emphasized: modelData.canAdd !== false
                                enabled: modelData.canAdd !== false
                                iconName: modelData.canAdd === false ? "dismiss.svg" : "add.svg"
                                label: modelData.canAdd === false ? "Added" : "Add"
                                onClicked: root.widgetAdded(modelData.widgetType)
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        visible: !Array.isArray(root.availableWidgets) || root.availableWidgets.length === 0
                        text: "No widgets match \"" + root.searchQuery + "\"."
                        color: Colors.textSecondary
                        font.pixelSize: Appearance.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
