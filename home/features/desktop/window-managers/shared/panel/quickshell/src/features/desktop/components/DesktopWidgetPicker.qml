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
        radius: Appearance.radiusLarge
        color: Colors.popupSurface
        border.color: Colors.border
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.paddingLarge
            spacing: Appearance.spacingM

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingS

                Text {
                    Layout.fillWidth: true
                    text: "Add Desktop Widget"
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeXL
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    implicitWidth: closePickerLabel.implicitWidth + Appearance.spacingM * 2
                    implicitHeight: 32
                    radius: Appearance.radiusMedium
                    color: Colors.cardSurface
                    border.color: Colors.border
                    border.width: 1

                    Text {
                        id: closePickerLabel
                        anchors.centerIn: parent
                        text: "Close"
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeSmall
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
                    spacing: Appearance.spacingS

                    Repeater {
                        model: availableWidgets

                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width
                            height: desktopWidgetInfo.implicitHeight + Appearance.spacingM * 2
                            radius: Appearance.radiusSmall
                            color: desktopWidgetAddArea.containsMouse ? Colors.highlight : Colors.cardSurface
                            border.color: desktopWidgetAddArea.containsMouse ? Colors.primary : Colors.border
                            border.width: 1

                            RowLayout {
                                id: desktopWidgetInfo
                                anchors.fill: parent
                                anchors.margins: Appearance.spacingM
                                spacing: Appearance.spacingM

                                Loader {
                                    property string _ic: modelData.icon || "󰖲"
                                    sourceComponent: String(_ic).endsWith(".svg") ? _dwpSvg : _dwpNerd
                                }
                                Component { id: _dwpSvg; SvgIcon { source: parent._ic; color: Colors.primary; size: Appearance.fontSizeLarge } }
                                Component { id: _dwpNerd; Text { text: parent._ic; color: Colors.primary; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeLarge } }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.spacingXXS

                                    Text {
                                        text: modelData.name
                                        color: Colors.text
                                        font.pixelSize: Appearance.fontSizeMedium
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }

                                    Text {
                                        text: String(modelData.source || "") === "plugin" ? "Plugin widget" : "Built-in widget"
                                        color: Colors.textSecondary
                                        font.pixelSize: Appearance.fontSizeXS
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
                        font.pixelSize: Appearance.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
