import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared"
import ".."

Rectangle {
    required property bool pickerOpen
    required property var availableWidgets
    required property string searchQuery
    required property string screenName
    required property real spawnX
    required property real spawnY

    signal closed()
    signal widgetAdded(string widgetType)
    signal searchChanged(string query)

    visible: pickerOpen
    color: Colors.overlayScrim

    MouseArea {
        anchors.fill: parent
        onClicked: closed()
    }

    Rectangle {
        width: Math.min(640, parent.width - 80)
        height: Math.min(560, parent.height - 80)
        anchors.centerIn: parent
        radius: Colors.radiusLarge
        color: Colors.popupSurface
        border.color: Colors.border
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.paddingLarge
            spacing: Colors.spacingM

            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Text {
                    Layout.fillWidth: true
                    text: "Add Desktop Widget"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeXL
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    implicitWidth: closePickerLabel.implicitWidth + Colors.spacingM * 2
                    implicitHeight: 32
                    radius: Colors.radiusMedium
                    color: Colors.cardSurface
                    border.color: Colors.border
                    border.width: 1

                    Text {
                        id: closePickerLabel
                        anchors.centerIn: parent
                        text: "Close"
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: closed()
                    }
                }
            }

            SearchBar {
                Layout.fillWidth: true
                placeholder: "Search desktop widgets"
                text: searchQuery
                onTextChanged: searchChanged(text)
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: widgetPickerColumn.implicitHeight

                Column {
                    id: widgetPickerColumn
                    width: parent.width
                    spacing: Colors.spacingS

                    Repeater {
                        model: availableWidgets

                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width
                            height: desktopWidgetInfo.implicitHeight + Colors.spacingM * 2
                            radius: Colors.radiusSmall
                            color: desktopWidgetAddArea.containsMouse ? Colors.highlight : Colors.cardSurface
                            border.color: desktopWidgetAddArea.containsMouse ? Colors.primary : Colors.border
                            border.width: 1

                            RowLayout {
                                id: desktopWidgetInfo
                                anchors.fill: parent
                                anchors.margins: Colors.spacingM
                                spacing: Colors.spacingM

                                Text {
                                    text: modelData.icon || "󰖲"
                                    color: Colors.primary
                                    font.family: Colors.fontMono
                                    font.pixelSize: Colors.fontSizeLarge
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Colors.spacingXXS

                                    Text {
                                        text: modelData.name
                                        color: Colors.text
                                        font.pixelSize: Colors.fontSizeMedium
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }

                                    Text {
                                        text: String(modelData.source || "") === "plugin" ? "Plugin widget" : "Built-in widget"
                                        color: Colors.textSecondary
                                        font.pixelSize: Colors.fontSizeXS
                                    }
                                }
                            }

                            MouseArea {
                                id: desktopWidgetAddArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    DesktopWidgetRegistry.addWidgetAt(screenName, modelData.id, spawnX, spawnY);
                                    closed();
                                }
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        visible: availableWidgets.length === 0
                        text: "No desktop widgets match \"" + searchQuery + "\"."
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
