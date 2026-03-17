import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../features/settings/components"
import "../../../widgets" as SharedWidgets

Rectangle {
    id: root
    required property var sshData
    required property var filteredManualHosts
    required property string editingHostId
    required property string searchQuery

    signal editHost(int index)
    signal duplicateHost(int index)
    signal removeHost(int index)
    signal moveHost(int index, int delta)
    signal searchChanged(string query)

    Layout.fillWidth: true
    implicitHeight: listColumn.implicitHeight + Colors.spacingM * 2
    radius: Colors.radiusMedium
    color: Colors.modalFieldSurface
    border.color: Colors.border
    border.width: 1

    ColumnLayout {
        id: listColumn
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        spacing: Colors.spacingS

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Text {
                text: "Manual Hosts"
                color: Colors.text
                font.pixelSize: Colors.fontSizeSmall
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }

            SharedWidgets.FilterChip {
                label: String(root.filteredManualHosts.length) + "/" + String(root.sshData.manualHosts.length)
                selected: false
                enabled: false
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 34
            radius: height / 2
            color: Colors.bgWidget
            border.color: manualSearchInput.activeFocus ? Colors.primary : Colors.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Colors.spacingM
                anchors.rightMargin: Colors.spacingM
                spacing: Colors.spacingS

                Text {
                    text: "󰍉"
                    color: Colors.textDisabled
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeMedium
                }

                TextInput {
                    id: manualSearchInput
                    Layout.fillWidth: true
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    clip: true
                    text: root.searchQuery
                    onTextChanged: root.searchChanged(text)

                    Text {
                        anchors.fill: parent
                        text: "Filter manual hosts..."
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeSmall
                        visible: !manualSearchInput.text && !manualSearchInput.activeFocus
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.filteredManualHosts.length === 0
            text: root.searchQuery.trim() !== "" ? "No manual hosts match \"" + root.searchQuery + "\"." : "No manual hosts saved yet."
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeXS
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: root.filteredManualHosts

            delegate: Rectangle {
                required property var modelData
                readonly property var host: modelData.host
                readonly property int hostIndex: modelData.index
                readonly property bool editingThisHost: String(host.id || "") === root.editingHostId

                Layout.fillWidth: true
                implicitHeight: hostColumn.implicitHeight + Colors.spacingM * 2
                radius: Colors.radiusSmall
                color: editingThisHost ? Colors.primarySubtle : Colors.cardSurface
                border.color: editingThisHost ? Colors.primary : Colors.border
                border.width: 1

                ColumnLayout {
                    id: hostColumn
                    anchors.fill: parent
                    anchors.margins: Colors.spacingM
                    spacing: Colors.spacingS

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Colors.spacingS

                        Text {
                            text: host.label
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeMedium
                            font.weight: Font.Medium
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        SharedWidgets.FilterChip {
                            visible: editingThisHost
                            label: "Editing"
                            selected: true
                            enabled: false
                        }
                    }

                    Text {
                        text: root.sshData.buildDisplayCommand(host)
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeXS
                        Layout.fillWidth: true
                        wrapMode: Text.WrapAnywhere
                    }

                    Flow {
                        Layout.fillWidth: true
                        width: parent.width
                        spacing: Colors.spacingS

                        SharedWidgets.FilterChip {
                            visible: String(host.group || "") !== ""
                            label: String(host.group || "")
                            selected: false
                            enabled: false
                        }

                        SharedWidgets.FilterChip {
                            visible: String(host.user || "") !== ""
                            label: String(host.user || "")
                            selected: false
                            enabled: false
                        }

                        Repeater {
                            model: Array.isArray(host.tags) ? host.tags : []

                            delegate: SharedWidgets.FilterChip {
                                required property var modelData
                                visible: String(modelData || "").trim() !== ""
                                label: "#" + String(modelData || "")
                                selected: false
                                enabled: false
                            }
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        width: parent.width
                        spacing: Colors.spacingS

                        SettingsActionButton {
                            compact: true
                            iconName: "󰏫"
                            label: "Up"
                            enabled: hostIndex > 0
                            onClicked: root.moveHost(hostIndex, -1)
                        }

                        SettingsActionButton {
                            compact: true
                            iconName: "󰏬"
                            label: "Down"
                            enabled: hostIndex < (root.sshData.manualHosts.length - 1)
                            onClicked: root.moveHost(hostIndex, 1)
                        }

                        SettingsActionButton {
                            compact: true
                            iconName: "󰏫"
                            label: "Edit"
                            onClicked: root.editHost(hostIndex)
                        }

                        SettingsActionButton {
                            compact: true
                            iconName: "󰑕"
                            label: "Duplicate"
                            onClicked: root.duplicateHost(hostIndex)
                        }

                        SettingsActionButton {
                            compact: true
                            iconName: "󰅖"
                            label: "Remove"
                            onClicked: root.removeHost(hostIndex)
                        }
                    }
                }
            }
        }
    }
}
