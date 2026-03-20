import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../services"
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

    readonly property string _timeFormatSummary: Config.timeUse24Hour ? "24-hour" : "12-hour"
    readonly property string _dateSummary: {
        if (!Config.timeShowBarDate)
            return "Hidden in bar";
        if (Config.timeBarDateStyle === "month_day")
            return "Month + Day";
        if (Config.timeBarDateStyle === "weekday_month_day")
            return "Weekday + Date";
        return "Weekday";
    }
    readonly property string _weatherUnitsSummary: Config.weatherUnits === "imperial" ? "Imperial (F)" : "Metric (C)"
    readonly property int _marketTickerCount: {
        var raw = String(Config.marketTickers || "").trim();
        if (raw === "")
            return 0;
        var parts = raw.split(/[\s,]+/);
        var count = 0;
        for (var i = 0; i < parts.length; i++) {
            if (parts[i])
                count += 1;
        }
        return count;
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
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "Time & Weather"
        iconName: "clock.svg"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Time & Weather Overview"
            description: "Clock format, weather source, active location, and market coverage visible before editing individual controls."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingM

                Repeater {
                    model: [
                        {
                            icon: "clock.svg",
                            label: "Clock",
                            value: root._timeFormatSummary + (Config.timeShowSeconds ? " / seconds" : "")
                        },
                        {
                            icon: "calendar-add.svg",
                            label: "Bar Date",
                            value: root._dateSummary
                        },
                        {
                            icon: "󰖐",
                            label: "Weather",
                            value: (Config.weatherProvider === "wttr" ? "wttr.in" : "Open-Meteo") + " / " + root._weatherUnitsSummary
                        },
                        {
                            icon: "compass.svg",
                            label: "Location",
                            value: root.activeLocationSummary()
                        },
                        {
                            icon: "󱓗",
                            label: "Markets",
                            value: root._marketTickerCount + " ticker" + (root._marketTickerCount === 1 ? "" : "s")
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: root.compactMode ? parent.width : Math.max(180, Math.floor((parent.width - Colors.spacingM * 2) / 3))
                        implicitHeight: metricColumn.implicitHeight + Colors.spacingM * 2
                        radius: Colors.radiusLarge
                        color: Colors.withAlpha(Colors.surface, 0.38)
                        border.color: Colors.withAlpha(Colors.primary, 0.14)
                        border.width: 1

                        ColumnLayout {
                            id: metricColumn
                            anchors.fill: parent
                            anchors.margins: Colors.spacingM
                            spacing: Colors.spacingXS

                            SettingsMetricIcon { icon: modelData.icon }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.Black
                                font.letterSpacing: Colors.letterSpacingExtraWide
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.value
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                font.weight: Font.Bold
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Live Preview"
            description: "Preview the clock chip and weather strip as you tune the bar display."

            SettingsCard {
                title: "Preview"
                iconName: "󰇙"
                description: "Live preview for your top bar clock and the Date & Time menu weather strip."

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: root.compactMode ? compactPreview.implicitHeight + Colors.spacingM * 2 : 84
                    radius: Colors.radiusMedium
                    color: Colors.cardSurface
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
                            color: Colors.primaryTint
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
                            spacing: Colors.spacingXXS

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
                            color: Colors.primaryTint
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
                            spacing: Colors.spacingXXS

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
        }

        SettingsSectionGroup {
            title: "Clock Format"
            description: "Control how time and date appear in the bar."

            SettingsCard {
                title: "Time Format"
                iconName: "clock.svg"
                description: "Clock format and bar date display options."

                SettingsFieldGrid {
                    maximumColumns: root.compactMode ? 1 : 2

                    SettingsToggleRow {
                        label: "24-Hour Clock"
                        icon: "clock.svg"
                        configKey: "timeUse24Hour"
                    }
                    SettingsToggleRow {
                        label: "Show Seconds"
                        icon: "timer.svg"
                        configKey: "timeShowSeconds"
                    }
                    SettingsToggleRow {
                        label: "Show Date In Bar"
                        icon: "calendar-add.svg"
                        configKey: "timeShowBarDate"
                    }
                }

                SettingsModeRow {
                    label: "Bar Date Style"
                    icon: "calendar-add.svg"
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
        }

        SettingsSectionGroup {
            title: "Weather & Location"
            description: "Units, priority order, and location inputs used by the weather surfaces."

            SettingsCard {
                title: "Weather & Location"
                iconName: "weather-moon.svg"
                description: "Weather units, source priority, and location inputs."

                SettingsModeRow {
                    label: "Weather Provider"
                    icon: "󰖐"
                    currentValue: Config.weatherProvider
                    options: [
                        {
                            value: "open-meteo",
                            label: "Open-Meteo (Recommended)"
                        },
                        {
                            value: "wttr",
                            label: "wttr.in"
                        }
                    ]
                    onModeSelected: modeValue => Config.weatherProvider = modeValue
                }

                SettingsModeRow {
                    label: "Units"
                    icon: "temperature.svg"
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
                    icon: "compass.svg"
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
                    icon: "desktop.svg"
                    configKey: "weatherAutoLocation"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingM

                    SettingsTextInputRow {
                        label: "City"
                        placeholderText: "New York, NY"
                        leadingIcon: "compass.svg"
                        text: Config.weatherCityQuery
                        onSubmitted: value => Config.weatherCityQuery = value.trim()
                        onTextEdited: value => {
                            if (Config.weatherCityQuery !== value)
                                Config.weatherCityQuery = value;
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        width: parent.width
                        spacing: Colors.spacingM

                        SettingsTextInputRow {
                            id: weatherLatInput
                            width: root.compactMode
                                ? parent.width
                                : Math.min(parent.width, Math.max(180, (parent.width - Colors.spacingM) / 2))
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
                            width: root.compactMode
                                ? parent.width
                                : Math.min(parent.width, Math.max(180, (parent.width - Colors.spacingM) / 2))
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
                        iconName: "info.svg"
                        title: "Active location"
                        body: root.activeLocationSummary() + ". Source priority applies to both the standalone Weather menu and the Date & Time dropdown."
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Markets"
            description: "Ticker configuration for the market widget surfaced in the shell."

            SettingsCard {
                title: "Markets"
                iconName: "󱓗"
                description: "Configure the tickers for your market widget."

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingM

                    SettingsTextInputRow {
                        label: "Tickers"
                        placeholderText: "^SPX ^DJI ^NDQ AAPL.US"
                        leadingIcon: "󱓗"
                        text: Config.marketTickers
                        onSubmitted: value => Config.marketTickers = value.trim()
                        onTextEdited: value => {
                            if (Config.marketTickers !== value)
                                Config.marketTickers = value;
                        }
                    }

                    SettingsInfoCallout {
                        iconName: "info.svg"
                        title: "Data Provider"
                        body: "Market data is fetched from Stooq. Use space or comma to separate multiple tickers. Use .US suffix for US stocks (e.g. AAPL.US) and ^ for indices."
                    }
                }
            }
        }
    }
}
