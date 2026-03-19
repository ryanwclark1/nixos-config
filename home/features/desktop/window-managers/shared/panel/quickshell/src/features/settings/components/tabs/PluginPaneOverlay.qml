import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../../widgets" as SharedWidgets
import ".."

Rectangle {
    id: root

    required property bool open
    required property bool compactMode
    required property var selectedPlugin
    required property bool selectedPluginHasSettings
    required property bool selectedPluginCanWriteSettings
    required property string pluginPaneMode
    required property string pluginPaneError
    required property string pluginPaneTitle
    required property string pluginTypeIcon
    required property string pluginTypeLabel

    readonly property alias pluginPaneLoader: pluginPaneLoader

    signal closeRequested
    signal pluginPaneErrorUpdated(string value)

    color: Qt.rgba(0, 0, 0, 0.45)
    z: 20

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    Rectangle {
        width: Math.min(520, parent.width - 24)
        height: Math.min(pluginPaneFlick.contentHeight + (Colors.paddingLarge * 2), parent.height - 24)
        anchors.centerIn: parent
        radius: Colors.radiusLarge
        color: Colors.withAlpha(Colors.surface, 0.98)
        border.color: Colors.border
        border.width: 1

        gradient: SharedWidgets.SurfaceGradient {}

        SharedWidgets.InnerHighlight { highlightOpacity: 0.15 }

        Flickable {
            id: pluginPaneFlick
            anchors.fill: parent
            anchors.margins: Colors.paddingLarge
            clip: true
            contentHeight: pluginPaneColumn.implicitHeight

            ColumnLayout {
                id: pluginPaneColumn
                width: parent.width
                spacing: Colors.spacingM

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingS

                    Text {
                        Layout.fillWidth: true
                        text: root.pluginPaneTitle
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeXL
                        font.weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                    }

                    SettingsActionButton {
                        compact: true
                        iconName: "󰅖"
                        label: "Close"
                        onClicked: root.closeRequested()
                    }
                }

                SettingsInfoCallout {
                    visible: !!root.selectedPlugin
                    iconName: root.pluginTypeIcon
                    title: root.selectedPlugin ? String(root.selectedPlugin.name || root.selectedPlugin.id) : "Plugin"
                    body: root.selectedPlugin ? String(root.selectedPlugin.description || "") : ""

                    Text {
                        visible: !!root.selectedPlugin
                        text: root.selectedPlugin ? ("Type: " + root.pluginTypeLabel + " • Author: " + String(root.selectedPlugin.author || "Unknown") + " • Version: " + String(root.selectedPlugin.version || "")) : ""
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeSmall
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                SettingsInfoCallout {
                    visible: root.pluginPaneMode === "settings" && root.selectedPluginHasSettings && !root.selectedPluginCanWriteSettings
                    title: "Permission required"
                    body: "This plugin is missing settings_write permission in its manifest."
                }

                SettingsInfoCallout {
                    visible: root.pluginPaneError !== ""
                    title: "Plugin pane failed to load"
                    body: root.pluginPaneError
                }

                Loader {
                    id: pluginPaneLoader
                    Layout.fillWidth: true
                    visible: root.open && root.pluginPaneError === "" && status !== Loader.Error
                    onStatusChanged: {
                        if (status === Loader.Error)
                            root.pluginPaneErrorUpdated(errorString());
                        else if (status === Loader.Ready)
                            root.pluginPaneErrorUpdated("");
                    }
                }
            }
        }
    }
}
