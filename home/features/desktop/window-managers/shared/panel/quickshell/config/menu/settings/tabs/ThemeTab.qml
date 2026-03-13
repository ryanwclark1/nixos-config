import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    property var _themeResults: []
    property string _themeVariantFilter: ""
    readonly property int _themeColumns: (compactMode || themeFlow.width < 700) ? 1 : 2

    function _refreshThemeResults() {
        _themeResults = ThemeService.searchThemes(themeSearchField ? themeSearchField.text : "", _themeVariantFilter);
    }

    Timer {
        id: _themeRefreshTimer
        interval: 150
        onTriggered: root._refreshThemeResults()
    }

    Component.onCompleted: _refreshThemeResults()

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Color Theme"

        SettingsCard {
            title: "Theme Browser"
            description: "Search and apply a base24 theme, or fall back to pywal colors."

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingM

                SettingsTextInputRow {
                    id: themeSearchField
                    Layout.fillWidth: true
                    placeholderText: "Search themes..."
                    leadingIcon: "󰍉"
                    onTextEdited: _themeRefreshTimer.restart()
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Colors.spacingS

                    SharedWidgets.FilterChip {
                        label: "Dark"
                        icon: "󰖔"
                        selected: root._themeVariantFilter === "dark"
                        onClicked: {
                            root._themeVariantFilter = root._themeVariantFilter === "dark" ? "" : "dark";
                            root._refreshThemeResults();
                        }
                    }

                    SharedWidgets.FilterChip {
                        label: "Light"
                        icon: "󰖙"
                        selected: root._themeVariantFilter === "light"
                        onClicked: {
                            root._themeVariantFilter = root._themeVariantFilter === "light" ? "" : "light";
                            root._refreshThemeResults();
                        }
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingM
                visible: Config.themeName !== ""

                Text {
                    width: root.compactMode ? parent.width : undefined
                    text: "Active: " + (ThemeService.activeTheme ? ThemeService.activeTheme.name : Config.themeName)
                    color: Colors.primary
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }

                SettingsActionButton {
                    label: "Use pywal"
                    iconName: "󰅖"
                    compact: true
                    onClicked: ThemeService.clearTheme()
                }
            }

            Text {
                text: root._themeResults.length + " themes"
                color: Colors.fgDim
                font.pixelSize: Colors.fontSizeXS
            }

            Flow {
                id: themeFlow
                Layout.fillWidth: true
                spacing: Colors.spacingXS

                Repeater {
                    model: root._themeResults

                    Item {
                        id: themeCardWrapper
                        width: Math.max(220, Math.floor((themeFlow.width - Colors.spacingXS * (root._themeColumns - 1)) / root._themeColumns))
                        height: themeCardLayout.implicitHeight + Colors.spacingS * 2

                        property var _theme: modelData
                        property bool _themeIsActive: _theme.id === Config.themeName

                        Rectangle {
                            anchors.fill: parent
                            radius: Colors.radiusSmall
                            color: Colors.bgWidget
                            border.color: themeCardWrapper._themeIsActive ? Colors.primary : Colors.border
                            border.width: themeCardWrapper._themeIsActive ? 2 : 1
                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: Colors.text
                                opacity: themeMouseArea.pressed ? 0.12 : themeMouseArea.containsMouse ? 0.06 : 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 120
                                    }
                                }
                            }

                            ColumnLayout {
                                id: themeCardLayout
                                anchors {
                                    fill: parent
                                    leftMargin: Colors.spacingM
                                    rightMargin: Colors.spacingM
                                    topMargin: Colors.spacingS
                                    bottomMargin: Colors.spacingS
                                }
                                spacing: Colors.spacingXS

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Colors.spacingS

                                    Text {
                                        text: "󰄬"
                                        color: Colors.primary
                                        font.family: Colors.fontMono
                                        font.pixelSize: Colors.fontSizeLarge
                                        visible: themeCardWrapper._themeIsActive
                                    }

                                    Text {
                                        text: themeCardWrapper._theme.name
                                        color: themeCardWrapper._themeIsActive ? Colors.primary : Colors.text
                                        font.pixelSize: Colors.fontSizeMedium
                                        font.weight: themeCardWrapper._themeIsActive ? Font.DemiBold : Font.Normal
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    width: parent.width
                                    spacing: Colors.spacingXS

                                    Repeater {
                                        model: [themeCardWrapper._theme.palette.base00, themeCardWrapper._theme.palette.base08, themeCardWrapper._theme.palette.base0B, themeCardWrapper._theme.palette.base0D, themeCardWrapper._theme.palette.base0E, themeCardWrapper._theme.palette.base05]

                                        delegate: Rectangle {
                                            width: 14
                                            height: 14
                                            radius: 7
                                            color: modelData
                                            border.color: Colors.withAlpha(Colors.text, 0.15)
                                            border.width: 1
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: themeMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ThemeService.applyTheme(themeCardWrapper._theme.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
