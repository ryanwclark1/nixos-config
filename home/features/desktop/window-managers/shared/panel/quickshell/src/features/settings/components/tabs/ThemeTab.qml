import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../../shared"
import "../../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    property var settingsRoot: null

    SharedWidgets.Ref {
        service: ThemeService
    }

    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    property var _themeResults: []
    property string _themeVariantFilter: ""
    property var _previewTheme: null
    readonly property var _effectivePreviewTheme: root._previewTheme || ThemeService.activeTheme
    readonly property int _themeColumns: (compactMode || themeFlow.width < 700) ? 1 : 2
    readonly property int _browserViewportHeight: compactMode ? Math.min(560, Math.max(360, themeListColumn.implicitHeight + Appearance.spacingL * 2)) : 520

    function _refreshThemeResults() {
        _themeResults = ThemeService.searchThemes(themeSearchField ? themeSearchField.text : "", _themeVariantFilter);
    }

    Timer {
        id: _themeRefreshTimer
        interval: 150
        onTriggered: root._refreshThemeResults()
    }

    Component.onCompleted: {
        _refreshThemeResults();
        root._previewTheme = ThemeService.activeTheme;
    }

    Connections {
        target: ThemeService
        function onActiveThemeChanged() {
            root._previewTheme = ThemeService.activeTheme;
        }
    }

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Color Theme"

        SettingsCard {
            title: "Theme Browser"
            description: "The preview stays pinned while the theme catalog scrolls, so you can compare themes without losing context."

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingM

                SettingsTextInputRow {
                    id: themeSearchField
                    Layout.fillWidth: true
                    placeholderText: "Search themes..."
                    leadingIcon: "search-visual.svg"
                    onTextEdited: _themeRefreshTimer.restart()
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Appearance.spacingS

                    SharedWidgets.FilterChip {
                        label: "Dark"
                        icon: "weather-moon.svg"
                        selected: root._themeVariantFilter === "dark"
                        onClicked: {
                            root._themeVariantFilter = root._themeVariantFilter === "dark" ? "" : "dark";
                            root._refreshThemeResults();
                        }
                    }

                    SharedWidgets.FilterChip {
                        label: "Light"
                        icon: "weather-sunny.svg"
                        selected: root._themeVariantFilter === "light"
                        onClicked: {
                            root._themeVariantFilter = root._themeVariantFilter === "light" ? "" : "light";
                            root._refreshThemeResults();
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Appearance.spacingM
                    visible: Config.themeName !== ""

                    Text {
                        width: root.compactMode ? parent.width : undefined
                        text: "Active: " + (ThemeService.activeTheme ? ThemeService.activeTheme.name : Config.themeName)
                        color: Colors.primary
                        font.pixelSize: Appearance.fontSizeSmall
                        font.weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                    }

                    SettingsActionButton {
                        label: "Clear Theme"
                        iconName: "dismiss.svg"
                        compact: true
                        onClicked: ThemeService.clearTheme()
                    }
                }

                Text {
                    text: root._themeResults.length + " themes"
                    color: Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeXS
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root._browserViewportHeight
                    spacing: Appearance.spacingL

                    Rectangle {
                        Layout.preferredWidth: root.compactMode ? 0 : 360
                        Layout.fillHeight: true
                        visible: !root.compactMode && root._effectivePreviewTheme !== null
                        radius: Appearance.radiusMedium
                        color: Colors.modalFieldSurface
                        border.color: Colors.border
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingL
                            spacing: Appearance.spacingM

                            Text {
                                text: "Locked Preview"
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeLarge
                                font.weight: Font.DemiBold
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 176
                                radius: Appearance.radiusMedium
                                color: root._effectivePreviewTheme ? root._effectivePreviewTheme.palette.base00 : Colors.background
                                border.color: root._effectivePreviewTheme ? root._effectivePreviewTheme.palette.base03 : Colors.border
                                border.width: 1
                                clip: true

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: Appearance.spacingM
                                    spacing: Appearance.spacingS

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 24
                                        radius: Appearance.radiusMedium
                                        color: root._effectivePreviewTheme ? Colors.withAlpha(root._effectivePreviewTheme.palette.base01, 0.8) : Colors.surface

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: Appearance.paddingSmall
                                            anchors.rightMargin: Appearance.paddingSmall

                                            Rectangle {
                                                width: 12
                                                height: 12
                                                radius: Appearance.radiusPill
                                                color: root._effectivePreviewTheme ? root._effectivePreviewTheme.palette.base0D : Colors.primary
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: "12:00"
                                                color: root._effectivePreviewTheme ? root._effectivePreviewTheme.palette.base05 : Colors.text
                                                font.pixelSize: Appearance.fontSizeXS
                                                font.bold: true
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: Appearance.radiusSmall
                                        color: root._effectivePreviewTheme ? root._effectivePreviewTheme.palette.base01 : Colors.surface
                                        border.color: root._effectivePreviewTheme ? root._effectivePreviewTheme.palette.base0D : Colors.primary
                                        border.width: 1

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: Appearance.paddingSmall
                                            spacing: Appearance.spacingXS

                                            Rectangle {
                                                width: 60
                                                height: 4
                                                radius: Appearance.radiusXXS
                                                color: root._effectivePreviewTheme ? root._effectivePreviewTheme.palette.base05 : Colors.text
                                                opacity: 0.6
                                            }

                                            Rectangle {
                                                width: 100
                                                height: 4
                                                radius: Appearance.radiusXXS
                                                color: root._effectivePreviewTheme ? root._effectivePreviewTheme.palette.base05 : Colors.text
                                                opacity: 0.3
                                            }

                                            Item {
                                                Layout.fillHeight: true
                                            }

                                            Rectangle {
                                                Layout.alignment: Qt.AlignRight
                                                width: 30
                                                height: 12
                                                radius: Appearance.radiusXS
                                                color: root._effectivePreviewTheme ? root._effectivePreviewTheme.palette.base0B : Colors.success
                                            }
                                        }
                                    }
                                }
                            }

                            GridLayout {
                                columns: 4
                                columnSpacing: Appearance.spacingS
                                rowSpacing: Appearance.spacingS

                                Repeater {
                                    model: root._effectivePreviewTheme ? [
                                        {
                                            c: root._effectivePreviewTheme.palette.base00,
                                            l: "BG"
                                        },
                                        {
                                            c: root._effectivePreviewTheme.palette.base01,
                                            l: "SRF"
                                        },
                                        {
                                            c: root._effectivePreviewTheme.palette.base05,
                                            l: "TXT"
                                        },
                                        {
                                            c: root._effectivePreviewTheme.palette.base0D,
                                            l: "PRI"
                                        },
                                        {
                                            c: root._effectivePreviewTheme.palette.base08,
                                            l: "ERR"
                                        },
                                        {
                                            c: root._effectivePreviewTheme.palette.base0A,
                                            l: "WRN"
                                        },
                                        {
                                            c: root._effectivePreviewTheme.palette.base0B,
                                            l: "SUC"
                                        },
                                        {
                                            c: root._effectivePreviewTheme.palette.base0E,
                                            l: "ACC"
                                        }
                                    ] : []

                                    delegate: Column {
                                        spacing: Appearance.spacingXXS

                                        Rectangle {
                                            width: 36
                                            height: 36
                                            radius: Appearance.radiusPill
                                            color: modelData.c
                                            border.color: Colors.textThin
                                            border.width: 1
                                        }

                                        Text {
                                            width: 36
                                            text: modelData.l
                                            color: Colors.textDisabled
                                            font.pixelSize: Appearance.fontSizeXXS
                                            font.weight: Font.Bold
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }
                                }
                            }

                            Text {
                                text: root._effectivePreviewTheme ? root._effectivePreviewTheme.name : ""
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeLarge
                                font.weight: Font.Bold
                            }

                            Text {
                                text: root._effectivePreviewTheme ? root._effectivePreviewTheme.author : ""
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeSmall
                            }

                            Text {
                                text: root._effectivePreviewTheme && root._effectivePreviewTheme.id === Config.themeName ? "Currently applied theme" : "Hover any theme card and the preview will stay pinned here."
                                color: root._effectivePreviewTheme && root._effectivePreviewTheme.id === Config.themeName ? Colors.primary : Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeXS
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            SettingsActionButton {
                                label: "Apply Theme"
                                iconName: "checkmark.svg"
                                enabled: root._effectivePreviewTheme !== null
                                onClicked: ThemeService.applyTheme(root._effectivePreviewTheme.id)
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Appearance.radiusMedium
                        color: Colors.modalFieldSurface
                        border.color: Colors.border
                        border.width: 1

                        Flickable {
                            id: themeListFlick
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingM
                            clip: true
                            boundsBehavior: Flickable.DragOverBounds
                            contentHeight: themeListColumn.implicitHeight

                            Column {
                                id: themeListColumn
                                width: themeListFlick.width
                                spacing: Appearance.spacingS

                                Flow {
                                    id: themeFlow
                                    width: parent.width
                                    spacing: Appearance.spacingXS

                                    Repeater {
                                        model: root._themeResults

                                        Item {
                                            id: themeCardWrapper
                                            width: Math.max(Math.min(180, themeFlow.width), Math.floor((themeFlow.width - Appearance.spacingXS * (root._themeColumns - 1)) / root._themeColumns))
                                            height: themeCardLayout.implicitHeight + Appearance.spacingS * 2

                                            property var _theme: modelData
                                            property bool _themeIsActive: _theme.id === Config.themeName

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: Appearance.radiusSmall
                                                color: Colors.modalFieldSurface
                                                border.color: themeCardWrapper._themeIsActive ? Colors.primary : Colors.border
                                                border.width: themeCardWrapper._themeIsActive ? 2 : 1

                                                Behavior on border.color {
                                                    enabled: !Colors.isTransitioning
                                                    CAnim {}
                                                }

                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: parent.radius
                                                    color: Colors.text
                                                    opacity: themeMouseArea.pressed ? 0.12 : themeMouseArea.containsMouse ? 0.06 : 0

                                                    Behavior on opacity {
                                                        NumberAnimation {
                                                            duration: Appearance.durationSnap
                                                        }
                                                    }
                                                }

                                                ColumnLayout {
                                                    id: themeCardLayout
                                                    anchors {
                                                        fill: parent
                                                        leftMargin: Appearance.spacingM
                                                        rightMargin: Appearance.spacingM
                                                        topMargin: Appearance.spacingS
                                                        bottomMargin: Appearance.spacingS
                                                    }
                                                    spacing: Appearance.spacingXS

                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        spacing: Appearance.spacingS

                                                        SharedWidgets.SvgIcon {
                                                            source: "checkmark.svg"
                                                            color: Colors.primary
                                                            size: Appearance.fontSizeLarge
                                                            visible: themeCardWrapper._themeIsActive
                                                        }

                                                        Text {
                                                            text: themeCardWrapper._theme.name
                                                            color: themeCardWrapper._themeIsActive ? Colors.primary : Colors.text
                                                            font.pixelSize: Appearance.fontSizeMedium
                                                            font.weight: themeCardWrapper._themeIsActive ? Font.DemiBold : Font.Normal
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                        }
                                                    }

                                                    Flow {
                                                        Layout.fillWidth: true
                                                        width: parent.width
                                                        spacing: Appearance.spacingXS

                                                        Repeater {
                                                            model: [themeCardWrapper._theme.palette.base00, themeCardWrapper._theme.palette.base08, themeCardWrapper._theme.palette.base0B, themeCardWrapper._theme.palette.base0D, themeCardWrapper._theme.palette.base0E, themeCardWrapper._theme.palette.base05]

                                                            delegate: Rectangle {
                                                                width: 14
                                                                height: 14
                                                                radius: width / 2
                                                                color: modelData
                                                                border.color: Colors.border
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
                                                    onEntered: root._previewTheme = themeCardWrapper._theme
                                                    onExited: root._previewTheme = ThemeService.activeTheme
                                                    onClicked: ThemeService.applyTheme(themeCardWrapper._theme.id)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        SettingsCard {
            title: "Auto Schedule"
            iconName: "clock.svg"
            description: "Automatically switch between dark and light themes on a schedule."

            SettingsToggleRow {
                label: "Enable Auto Schedule"
                icon: "clock.svg"
                checked: Config.themeAutoScheduleEnabled
                onToggled: Config.themeAutoScheduleEnabled = !Config.themeAutoScheduleEnabled
            }

            SettingsModeRow {
                visible: Config.themeAutoScheduleEnabled
                label: "Schedule Mode"
                currentValue: Config.themeAutoScheduleMode
                options: [
                    {
                        value: "time",
                        label: "Fixed Time"
                    },
                    {
                        value: "sunrise_sunset",
                        label: "Sunrise/Sunset"
                    }
                ]
                onModeSelected: v => Config.themeAutoScheduleMode = v
            }

            SettingsTextInputRow {
                visible: Config.themeAutoScheduleEnabled
                label: "Dark Theme"
                leadingIcon: "weather-moon.svg"
                text: Config.themeDarkName
                placeholderText: "Theme ID for dark mode"
                onSubmitted: v => Config.themeDarkName = v.trim()
            }

            SettingsTextInputRow {
                visible: Config.themeAutoScheduleEnabled
                label: "Light Theme"
                leadingIcon: "weather-sunny.svg"
                text: Config.themeLightName
                placeholderText: "Theme ID for light mode"
                onSubmitted: v => Config.themeLightName = v.trim()
            }
        }

        SettingsCard {
            title: "Schedule Times"
            iconName: "clock-filled.svg"
            description: "Set when to switch to dark and light themes."
            visible: Config.themeAutoScheduleEnabled && Config.themeAutoScheduleMode === "time"

            SettingsSliderRow {
                label: "Dark Mode Hour"
                min: 0
                max: 23
                value: Config.themeDarkHour
                onMoved: v => Config.themeDarkHour = v
            }

            SettingsSliderRow {
                label: "Dark Mode Minute"
                min: 0
                max: 55
                step: 5
                value: Config.themeDarkMinute
                onMoved: v => Config.themeDarkMinute = v
            }

            SettingsSliderRow {
                label: "Light Mode Hour"
                min: 0
                max: 23
                value: Config.themeLightHour
                onMoved: v => Config.themeLightHour = v
            }

            SettingsSliderRow {
                label: "Light Mode Minute"
                min: 0
                max: 55
                step: 5
                value: Config.themeLightMinute
                onMoved: v => Config.themeLightMinute = v
            }
        }

        SettingsCard {
            title: "Location"
            iconName: "compass.svg"
            description: "Coordinates for sunrise/sunset theme switching."
            visible: Config.themeAutoScheduleEnabled && Config.themeAutoScheduleMode === "sunrise_sunset"

            SettingsTextInputRow {
                label: "Latitude"
                leadingIcon: "compass.svg"
                text: Config.themeAutoLatitude
                placeholderText: "e.g. 40.7128"
                onSubmitted: v => Config.themeAutoLatitude = v.trim()
            }

            SettingsTextInputRow {
                label: "Longitude"
                leadingIcon: "compass.svg"
                text: Config.themeAutoLongitude
                placeholderText: "e.g. -74.0060"
                onSubmitted: v => Config.themeAutoLongitude = v.trim()
            }
        }
    }
}
