import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false
    property bool latValid: {
        var v = parseFloat(Config.weatherLatitude);
        return !isNaN(v) && v >= -90 && v <= 90;
    }
    property bool lonValid: {
        var v = parseFloat(Config.weatherLongitude);
        return !isNaN(v) && v >= -180 && v <= 180;
    }

    function barDatePreview(now) {
        if (!Config.timeShowBarDate)
            return "";
        if (Config.timeBarDateStyle === "month_day")
            return Qt.formatDateTime(now, "MMM d");
        if (Config.timeBarDateStyle === "weekday_month_day")
            return Qt.formatDateTime(now, "ddd MMM d");
        return Qt.formatDateTime(now, "ddd");
    }

    function activeLocationSummary() {
        var location = WeatherService.location || "";
        if (location !== "")
            return location;
        if (Config.weatherCityQuery)
            return Config.weatherCityQuery;
        if (Config.weatherLatitude && Config.weatherLongitude)
            return Config.weatherLatitude + ", " + Config.weatherLongitude;
        return Config.weatherAutoLocation ? "Auto-detected" : "Not configured";
    }

    SystemClock {
        id: previewClock
        precision: Config.timeShowSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Time & Weather"
        iconName: "󰔛"

        SettingsCard {
            title: "Preview"
            iconName: "󰇙"
            description: "Live preview for your top bar clock and the Date & Time menu weather strip."

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: root.compactMode ? compactPreview.implicitHeight + Colors.spacingM * 2 : 84
                radius: Colors.radiusMedium
                color: Colors.withAlpha(Colors.surface, 0.78)
                border.color: Colors.border
                border.width: 1

                RowLayout {
                    id: widePreview
                    anchors.fill: parent
                    anchors.margins: Colors.spacingM
                    spacing: Colors.spacingM
                    visible: !root.compactMode

                    Rectangle {
                        implicitHeight: 34
                        implicitWidth: timePreview.implicitWidth + datePreview.implicitWidth + Colors.spacingM * 3
                        radius: Colors.radiusPill
                        color: Colors.withAlpha(Colors.primary, 0.2)
                        border.color: Colors.withAlpha(Colors.primary, 0.45)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Colors.spacingM
                            anchors.rightMargin: Colors.spacingM
                            spacing: Colors.spacingS

                            Text {
                                id: timePreview
                                text: Qt.formatDateTime(previewClock.date, Config.timeUse24Hour ? (Config.timeShowSeconds ? "HH:mm:ss" : "HH:mm") : (Config.timeShowSeconds ? "hh:mm:ss AP" : "hh:mm AP"))
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeLarge
                                font.weight: Font.Bold
                            }

                            Text {
                                id: datePreview
                                text: root.barDatePreview(previewClock.date)
                                visible: text !== ""
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeMedium
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: (WeatherService.condition || "Weather") + "  " + (WeatherService.temp || "--")
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeMedium
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.activeLocationSummary()
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeSmall
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                ColumnLayout {
                    id: compactPreview
                    anchors.fill: parent
                    anchors.margins: Colors.spacingM
                    spacing: Colors.spacingS
                    visible: root.compactMode

                    Rectangle {
                        Layout.alignment: Qt.AlignLeft
                        implicitHeight: 34
                        implicitWidth: timePreviewCompact.implicitWidth + datePreviewCompact.implicitWidth + Colors.spacingM * 3
                        radius: Colors.radiusPill
                        color: Colors.withAlpha(Colors.primary, 0.2)
                        border.color: Colors.withAlpha(Colors.primary, 0.45)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Colors.spacingM
                            anchors.rightMargin: Colors.spacingM
                            spacing: Colors.spacingS

                            Text {
                                id: timePreviewCompact
                                text: Qt.formatDateTime(previewClock.date, Config.timeUse24Hour ? (Config.timeShowSeconds ? "HH:mm:ss" : "HH:mm") : (Config.timeShowSeconds ? "hh:mm:ss AP" : "hh:mm AP"))
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeLarge
                                font.weight: Font.Bold
                            }

                            Text {
                                id: datePreviewCompact
                                text: root.barDatePreview(previewClock.date)
                                visible: text !== ""
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeMedium
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: (WeatherService.condition || "Weather") + "  " + (WeatherService.temp || "--")
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeMedium
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            text: root.activeLocationSummary()
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeSmall
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }

        SettingsCard {
            title: "Time Format"
            iconName: "󰔛"
            description: "Clock format and bar date display options."

            SettingsFieldGrid {
                SettingsToggleRow {
                    label: "24-Hour Clock"
                    icon: "󰅐"
                    configKey: "timeUse24Hour"
                }
                SettingsToggleRow {
                    label: "Show Seconds"
                    icon: "󰔟"
                    configKey: "timeShowSeconds"
                }
                SettingsToggleRow {
                    label: "Show Date In Bar"
                    icon: "󰃭"
                    configKey: "timeShowBarDate"
                }
            }

            SettingsModeRow {
                label: "Bar Date Style"
                currentValue: Config.timeBarDateStyle
                options: [
                    {
                        value: "weekday_short",
                        label: "Weekday"
                    },
                    {
                        value: "month_day",
                        label: "Month + Day"
                    },
                    {
                        value: "weekday_month_day",
                        label: "Weekday + Date"
                    }
                ]
                onModeSelected: modeValue => Config.timeBarDateStyle = modeValue
            }
        }

        SettingsCard {
            title: "Weather & Location"
            iconName: "󰖔"
            description: "Weather units, source priority, and location inputs."

            SettingsModeRow {
                label: "Units"
                currentValue: Config.weatherUnits
                options: [
                    {
                        value: "metric",
                        label: "Metric (C)"
                    },
                    {
                        value: "imperial",
                        label: "Imperial (F)"
                    }
                ]
                onModeSelected: modeValue => Config.weatherUnits = modeValue
            }

            SettingsModeRow {
                label: "Location Priority"
                currentValue: Config.weatherLocationPriority
                options: [
                    {
                        value: "latlon_city_auto",
                        label: "LatLon > City > Auto"
                    },
                    {
                        value: "city_auto_latlon",
                        label: "City > Auto > LatLon"
                    },
                    {
                        value: "auto_city_latlon",
                        label: "Auto > City > LatLon"
                    }
                ]
                onModeSelected: modeValue => Config.weatherLocationPriority = modeValue
            }

            SettingsToggleRow {
                label: "Auto Location"
                icon: "󰍹"
                configKey: "weatherAutoLocation"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingM

                SettingsTextInputRow {
                    label: "City"
                    placeholderText: "New York, NY"
                    leadingIcon: "󰍎"
                    text: Config.weatherCityQuery
                    onSubmitted: value => Config.weatherCityQuery = value.trim()
                    onTextEdited: value => {
                        if (Config.weatherCityQuery !== value)
                            Config.weatherCityQuery = value;
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingM

                    SettingsTextInputRow {
                        id: weatherLatInput
                        Layout.fillWidth: true
                        label: "Latitude"
                        placeholderText: "40.7128"
                        leadingIcon: "󰍐"
                        text: Config.weatherLatitude
                        errorText: weatherLatInput.text.length > 0 && !root.latValid ? "Expected value between -90 and 90" : ""
                        onSubmitted: value => Config.weatherLatitude = value.trim()
                        onTextEdited: value => {
                            if (Config.weatherLatitude !== value)
                                Config.weatherLatitude = value;
                        }
                    }

                    SettingsTextInputRow {
                        id: weatherLonInput
                        Layout.fillWidth: true
                        label: "Longitude"
                        placeholderText: "-74.0060"
                        leadingIcon: "󰍐"
                        text: Config.weatherLongitude
                        errorText: weatherLonInput.text.length > 0 && !root.lonValid ? "Expected value between -180 and 180" : ""
                        onSubmitted: value => Config.weatherLongitude = value.trim()
                        onTextEdited: value => {
                            if (Config.weatherLongitude !== value)
                                Config.weatherLongitude = value;
                        }
                    }
                }

                SettingsInfoCallout {
                    iconName: "󰋗"
                    title: "Active location"
                    body: root.activeLocationSummary() + ". Source priority applies to both the standalone Weather menu and the Date & Time dropdown."
                }
            }
        }
    }
}
