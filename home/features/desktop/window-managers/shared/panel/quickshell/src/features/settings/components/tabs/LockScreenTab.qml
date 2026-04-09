import QtQuick
import QtQuick.Layouts
import "../../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    readonly property int _moduleCount: (Config.lockScreenMediaControls ? 1 : 0)
        + (Config.lockScreenWeather ? 1 : 0)
        + (Config.lockScreenSessionButtons ? 1 : 0)
    readonly property string _presentationSummary: Config.lockScreenCompact ? "Compact" : "Standard"
    readonly property string _unlockSummary: Config.lockScreenFingerprint ? "Password + fingerprint" : "Password only"
    readonly property string _sessionActionSummary: Config.lockScreenSessionButtons
        ? ("Hold-to-confirm after " + Math.round(Config.lockScreenCountdown / 1000) + "s")
        : "Buttons hidden"
    readonly property string _densityDescription: Config.lockScreenCompact
        ? "Tighter spacing keeps the lock surface smaller and more focused."
        : "Standard spacing keeps secondary details easier to scan."
    readonly property string _moduleSummary: {
        if (root._moduleCount === 0)
            return "No extra bottom-bar modules are visible.";
        return root._moduleCount + " module" + (root._moduleCount === 1 ? "" : "s") + " appear along the lower edge.";
    }

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "Lock Screen"
        iconName: "lock-closed.svg"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Lock Screen Overview"
            description: "Presentation density, visible bottom-bar modules, and unlock behavior for the shell lock surface."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Appearance.spacingM

                Repeater {
                    model: [
                        {
                            icon: "lock-closed.svg",
                            label: "Presentation",
                            value: root._presentationSummary,
                            note: Config.lockScreenCompact ? "Compressed spacing" : "Roomier layout"
                        },
                        {
                            icon: "people.svg",
                            label: "Bottom Modules",
                            value: root._moduleCount + " active",
                            note: root._moduleSummary
                        },
                        {
                            icon: "fingerprint.svg",
                            label: "Unlock",
                            value: root._unlockSummary,
                            note: Config.lockScreenFingerprint ? "Biometric prompt appears when hardware is available." : "Password field is the only unlock path."
                        },
                        {
                            icon: "timer.svg",
                            label: "Session Timer",
                            value: Config.lockScreenCountdown + " ms",
                            note: "Used when reboot or shutdown actions are triggered from the lock screen."
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: root.compactMode ? parent.width : Math.max(168, Math.floor((parent.width - Appearance.spacingM * 3) / 4))
                        implicitHeight: tileContent.implicitHeight + Appearance.spacingL * 2
                        radius: Appearance.radiusLarge
                        color: Colors.surfaceContainerHighest
                        border.color: Colors.withAlpha(Colors.primary, 0.28)
                        border.width: 1

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Colors.withAlpha(Colors.primary, 0.16) }
                                GradientStop { position: 0.22; color: Colors.withAlpha(Colors.surface, 0.92) }
                                GradientStop { position: 1.0; color: Colors.withAlpha(Colors.surface, 0.78) }
                            }
                        }

                        ColumnLayout {
                            id: tileContent
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingL
                            spacing: Appearance.spacingS

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacingS

                                SettingsMetricIcon { icon: modelData.icon }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    color: Colors.textSecondary
                                    font.pixelSize: Appearance.fontSizeXS
                                    font.weight: Font.Black
                                    font.letterSpacing: Appearance.letterSpacingExtraWide
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.value
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeLarge
                                font.weight: Font.Black
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.note
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeSmall
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Layout & Modules"
            description: "Separate the structural lock-screen choices from the optional bottom-row modules."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2

                SettingsCard {
                    title: "Presentation Density"
                    iconName: "layout-row.svg"
                    description: "Choose how much whitespace and supporting information the lock screen should expose."

                    Rectangle {
                        Layout.fillWidth: true
                        radius: Appearance.radiusMedium
                        color: Colors.primarySubtle
                        border.color: Colors.primaryRing
                        border.width: 1
                        implicitHeight: densitySummary.implicitHeight + Appearance.spacingM * 2

                        ColumnLayout {
                            id: densitySummary
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingM
                            spacing: Appearance.spacingXS

                            Text {
                                Layout.fillWidth: true
                                text: root._presentationSummary + " layout"
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeMedium
                                font.weight: Font.Black
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root._densityDescription
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeSmall
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    SettingsToggleRow {
                        label: "Compact Mode"
                        description: "Reduces lock-surface spacing and hides the optional media and weather rows."
                        icon: "layout-row.svg"
                        configKey: "lockScreenCompact"
                        enabledText: "Compact density is active."
                        disabledText: "Standard density is active."
                    }
                }

                SettingsCard {
                    title: "Bottom Bar Modules"
                    iconName: "dashboard.svg"
                    description: "Control which supporting modules appear beside the battery indicator near the bottom edge."

                    Rectangle {
                        Layout.fillWidth: true
                        radius: Appearance.radiusMedium
                        color: Colors.withAlpha(Colors.surface, 0.76)
                        border.color: Colors.withAlpha(Colors.text, 0.12)
                        border.width: 1
                        implicitHeight: moduleSummary.implicitHeight + Appearance.spacingM * 2

                        Text {
                            id: moduleSummary
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingM
                            text: root._moduleSummary
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeSmall
                            wrapMode: Text.WordWrap
                        }
                    }

                    SettingsFieldGrid {
                        maximumColumns: 1

                        SettingsToggleRow {
                            label: "Media Controls"
                            description: "Shows the active player card when music is playing and compact mode is off."
                            icon: "music-note-2.svg"
                            configKey: "lockScreenMediaControls"
                        }

                        SettingsToggleRow {
                            label: "Weather"
                            description: "Displays the current temperature and condition when weather data is available and compact mode is off."
                            icon: "weather-sunny.svg"
                            configKey: "lockScreenWeather"
                        }

                        SettingsToggleRow {
                            label: "Session Buttons"
                            description: "Adds reboot and shutdown actions to the lower-right edge of the lock screen."
                            icon: "power.svg"
                            configKey: "lockScreenSessionButtons"
                        }
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Authentication & Session Actions"
            description: "Keep unlock controls and destructive-action safeguards separate so each choice is easier to understand."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2

                SettingsCard {
                    title: "Unlock Method"
                    iconName: "fingerprint.svg"
                    description: "Password unlock is always available. Fingerprint unlock only appears when supported by the host."

                    Rectangle {
                        Layout.fillWidth: true
                        radius: Appearance.radiusMedium
                        color: Colors.primarySubtle
                        border.color: Colors.primaryRing
                        border.width: 1
                        implicitHeight: unlockSummary.implicitHeight + Appearance.spacingM * 2

                        ColumnLayout {
                            id: unlockSummary
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingM
                            spacing: Appearance.spacingXS

                            Text {
                                Layout.fillWidth: true
                                text: root._unlockSummary
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeMedium
                                font.weight: Font.Black
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: Config.lockScreenFingerprint
                                    ? "If no sensor is detected, the lock screen quietly falls back to password-only unlock."
                                    : "The fingerprint prompt stays hidden even when the machine has a reader."
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeSmall
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    SettingsToggleRow {
                        label: "Fingerprint Unlock"
                        description: "Enable biometric authentication when `fprintd` hardware and PAM support are available."
                        icon: "fingerprint.svg"
                        configKey: "lockScreenFingerprint"
                        enabledText: "Fingerprint unlock is allowed when hardware is detected."
                        disabledText: "Only password authentication will be shown."
                    }
                }

                SettingsCard {
                    title: "Session Action Countdown"
                    iconName: "timer.svg"
                    description: "Delay reboot and shutdown actions from the lock screen so they remain reversible for a few seconds."

                    Rectangle {
                        Layout.fillWidth: true
                        radius: Appearance.radiusMedium
                        color: Colors.withAlpha(Colors.surface, 0.76)
                        border.color: Colors.withAlpha(Colors.text, 0.12)
                        border.width: 1
                        implicitHeight: countdownSummary.implicitHeight + Appearance.spacingM * 2

                        ColumnLayout {
                            id: countdownSummary
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingM
                            spacing: Appearance.spacingXS

                            Text {
                                Layout.fillWidth: true
                                text: root._sessionActionSummary
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeMedium
                                font.weight: Font.Black
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: Config.lockScreenSessionButtons
                                    ? "Pressing the same action again confirms it immediately. Escape cancels while the timer is running."
                                    : "This timer is only used when session buttons are enabled."
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeSmall
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    SettingsSliderRow {
                        label: "Countdown Duration"
                        description: "Applies to reboot and shutdown actions launched from the lock screen session buttons."
                        icon: "timer.svg"
                        min: 1000
                        max: 10000
                        step: 500
                        value: Config.lockScreenCountdown
                        unit: "ms"
                        onMoved: v => Config.lockScreenCountdown = v
                    }
                }
            }
        }
    }
}
