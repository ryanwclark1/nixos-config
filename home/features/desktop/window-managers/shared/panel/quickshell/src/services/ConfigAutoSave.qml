import QtQuick

QtObject {
    id: root

    required property var config

    property Connections _configConn: Connections {
        target: root.config

        function onBarHeightChanged() {
            root.config.applyLegacyBarSetting("height", root.config.barHeight);
            root.config.scheduleSave();
        }
        function onBarFloatingChanged() {
            root.config.applyLegacyBarSetting("floating", root.config.barFloating);
            root.config.scheduleSave();
        }
        function onBarMarginChanged() {
            root.config.applyLegacyBarSetting("margin", root.config.barMargin);
            root.config.scheduleSave();
        }
        function onBarOpacityChanged() {
            root.config.applyLegacyBarSetting("opacity", root.config.barOpacity);
            root.config.scheduleSave();
        }
        function onBarConfigsChanged() {
            root.config.ensureSelectedBar();
            root.config.syncLegacyBarSettingsFromPrimary();
            root.config.scheduleSave();
        }
        function onSelectedBarIdChanged() {
            root.config.scheduleSave();
        }
        function onBlurEnabledChanged() {
            root.config.scheduleSave();
        }
        function onGlassOpacityChanged() {
            root.config.scheduleSave();
        }
        function onNotifWidthChanged() {
            root.config.scheduleSave();
        }
        function onPopupTimerChanged() {
            root.config.scheduleSave();
        }
        function onTimeUse24HourChanged() {
            root.config.scheduleSave();
        }
        function onTimeShowSecondsChanged() {
            root.config.scheduleSave();
        }
        function onTimeShowBarDateChanged() {
            root.config.scheduleSave();
        }
        function onTimeBarDateStyleChanged() {
            root.config.scheduleSave();
        }
        function onWeatherUnitsChanged() {
            root.config.scheduleSave();
        }
        function onWeatherAutoLocationChanged() {
            root.config.scheduleSave();
        }
        function onWeatherCityQueryChanged() {
            root.config.scheduleSave();
        }
        function onWeatherLatitudeChanged() {
            root.config.scheduleSave();
        }
        function onWeatherLongitudeChanged() {
            root.config.scheduleSave();
        }
        function onWeatherLocationPriorityChanged() {
            root.config.scheduleSave();
        }
        function onLauncherDefaultModeChanged() {
            root.config.scheduleSave();
        }
        function onLauncherShowModeHintsChanged() {
            root.config.scheduleSave();
        }
        function onLauncherShowHomeSectionsChanged() {
            root.config.scheduleSave();
        }
        function onLauncherDrunCategoryFiltersEnabledChanged() {
            root.config.scheduleSave();
        }
        function onLauncherEnablePreloadChanged() {
            root.config.scheduleSave();
        }
        function onLauncherKeepSearchOnModeSwitchChanged() {
            root.config.scheduleSave();
        }
        function onLauncherEnableDebugTimingsChanged() {
            root.config.scheduleSave();
        }
        function onLauncherShowRuntimeMetricsChanged() {
            root.config.scheduleSave();
        }
        function onLauncherPreloadFailureThresholdChanged() {
            root.config.scheduleSave();
        }
        function onLauncherPreloadFailureBackoffSecChanged() {
            root.config.scheduleSave();
        }
        function onLauncherMaxResultsChanged() {
            root.config.scheduleSave();
        }
        function onLauncherFileMinQueryLengthChanged() {
            root.config.scheduleSave();
        }
        function onLauncherFileMaxResultsChanged() {
            root.config.scheduleSave();
        }
        function onLauncherRecentsLimitChanged() {
            root.config.scheduleSave();
        }
        function onLauncherRecentAppsLimitChanged() {
            root.config.scheduleSave();
        }
        function onLauncherSuggestionsLimitChanged() {
            root.config.scheduleSave();
        }
        function onLauncherCacheTtlSecChanged() {
            root.config.scheduleSave();
        }
        function onLauncherSearchDebounceMsChanged() {
            root.config.scheduleSave();
        }
        function onLauncherFileSearchDebounceMsChanged() {
            root.config.scheduleSave();
        }
        function onLauncherTabBehaviorChanged() {
            root.config.scheduleSave();
        }
        function onLauncherWebEnterUsesPrimaryChanged() {
            root.config.scheduleSave();
        }
        function onLauncherWebNumberHotkeysEnabledChanged() {
            root.config.scheduleSave();
        }
        function onLauncherWebAliasesChanged() {
            root.config.scheduleSave();
        }
        function onLauncherRememberWebProviderChanged() {
            root.config.scheduleSave();
        }
        function onLauncherWebLastProviderKeyChanged() {
            root.config.scheduleSave();
        }
        function onLauncherWebProviderOrderChanged() {
            root.config.scheduleSave();
        }
        function onLauncherModeOrderChanged() {
            root.config.scheduleSave();
        }
        function onLauncherEnabledModesChanged() {
            root.config.scheduleSave();
        }
        function onLauncherScoreNameWeightChanged() {
            root.config.scheduleSave();
        }
        function onLauncherScoreTitleWeightChanged() {
            root.config.scheduleSave();
        }
        function onLauncherScoreExecWeightChanged() {
            root.config.scheduleSave();
        }
        function onLauncherScoreBodyWeightChanged() {
            root.config.scheduleSave();
        }
        function onLauncherScoreCategoryWeightChanged() {
            root.config.scheduleSave();
        }
        function onControlCenterWidthChanged() {
            root.config.scheduleSave();
        }
        function onControlCenterShowQuickLinksChanged() {
            root.config.scheduleSave();
        }
        function onControlCenterShowMediaWidgetChanged() {
            root.config.scheduleSave();
        }
        function onControlCenterToggleOrderChanged() {
            root.config.scheduleSave();
        }
        function onControlCenterHiddenTogglesChanged() {
            root.config.scheduleSave();
        }
        function onControlCenterPluginOrderChanged() {
            root.config.scheduleSave();
        }
        function onControlCenterHiddenPluginsChanged() {
            root.config.scheduleSave();
        }
        function onOsdDurationChanged() {
            root.config.scheduleSave();
        }
        function onOsdSizeChanged() {
            root.config.scheduleSave();
        }
        function onOsdPositionChanged() {
            root.config.scheduleSave();
        }
        function onOsdStyleChanged() {
            root.config.scheduleSave();
        }
        function onOsdOverdriveChanged() {
            root.config.scheduleSave();
        }
        function onDockEnabledChanged() {
            root.config.scheduleSave();
        }
        function onDockAutoHideChanged() {
            root.config.scheduleSave();
        }
        function onDockPinnedAppsChanged() {
            root.config.scheduleSave();
        }
        function onDockPositionChanged() {
            root.config.scheduleSave();
        }
        function onDockGroupAppsChanged() {
            root.config.scheduleSave();
        }
        function onDockIconSizeChanged() {
            root.config.scheduleSave();
        }
        function onDesktopWidgetsEnabledChanged() {
            root.config.scheduleSave();
        }
        function onDesktopWidgetsGridSnapChanged() {
            root.config.scheduleSave();
        }
        function onDesktopWidgetsMonitorWidgetsChanged() {
            root.config.scheduleSave();
        }
        function onBackgroundVisualizerEnabledChanged() {
            root.config.scheduleSave();
        }
        function onBackgroundClockEnabledChanged() {
            root.config.scheduleSave();
        }
        function onBackgroundAutoHideChanged() {
            root.config.scheduleSave();
        }
        function onBackgroundClockPositionChanged() {
            root.config.scheduleSave();
        }
        function onShowScreenBordersChanged() {
            root.config.scheduleSave();
        }
        function onPowermenuCountdownChanged() {
            root.config.scheduleSave();
        }
        function onLockScreenCompactChanged() {
            root.config.scheduleSave();
        }
        function onLockScreenMediaControlsChanged() {
            root.config.scheduleSave();
        }
        function onLockScreenWeatherChanged() {
            root.config.scheduleSave();
        }
        function onLockScreenSessionButtonsChanged() {
            root.config.scheduleSave();
        }
        function onLockScreenCountdownChanged() {
            root.config.scheduleSave();
        }
        function onLockScreenFingerprintChanged() {
            root.config.scheduleSave();
        }
        function onPrivacyIndicatorsEnabledChanged() {
            root.config.scheduleSave();
        }
        function onPrivacyCameraMonitoringChanged() {
            root.config.scheduleSave();
        }
        function onVolumeProtectionEnabledChanged() {
            root.config.scheduleSave();
        }
        function onVolumeProtectionMaxJumpChanged() {
            root.config.scheduleSave();
        }
        function onNightLightEnabledChanged() {
            root.config.scheduleSave();
        }
        function onNightLightTemperatureChanged() {
            root.config.scheduleSave();
        }
        function onBatteryAlertsEnabledChanged() {
            root.config.scheduleSave();
        }
        function onBatteryWarningThresholdChanged() {
            root.config.scheduleSave();
        }
        function onBatteryCriticalThresholdChanged() {
            root.config.scheduleSave();
        }
        function onHooksEnabledChanged() {
            root.config.scheduleSave();
        }
        function onHookPathsChanged() {
            root.config.scheduleSave();
        }
        function onIdleInhibitEnabledChanged() {
            root.config.scheduleSave();
        }
        function onInhibitIdleWhenPlayingChanged() {
            root.config.scheduleSave();
        }
        function onRecentPickerColorsChanged() {
            root.config.scheduleSave();
        }
        function onThemeNameChanged() {
            root.config.scheduleSave();
        }
        function onFontFamilyChanged() {
            root.config.scheduleSave();
        }
        function onMonoFontFamilyChanged() {
            root.config.scheduleSave();
        }
        function onFontScaleChanged() {
            root.config.scheduleSave();
        }
        function onRadiusScaleChanged() {
            root.config.scheduleSave();
        }
        function onSpacingScaleChanged() {
            root.config.scheduleSave();
        }
        function onDisabledPluginsChanged() {
            root.config.scheduleSave();
        }
        function onPluginSettingsChanged() {
            root.config.scheduleSave();
        }
        function onPluginLauncherTriggersChanged() {
            root.config.scheduleSave();
        }
        function onPluginLauncherNoTriggerChanged() {
            root.config.scheduleSave();
        }
        function onPluginHotReloadChanged() {
            root.config.scheduleSave();
        }
        function onWallpaperRunPywalChanged() {
            root.config.scheduleSave();
        }
        function onWallpaperPathsChanged() {
            root.config.scheduleSave();
        }
        function onWallpaperCycleIntervalChanged() {
            root.config.scheduleSave();
        }
        function onWallpaperDefaultFolderChanged() {
            root.config.scheduleSave();
        }
        function onWallpaperSolidColorChanged() {
            root.config.scheduleSave();
        }
        function onWallpaperUseSolidOnStartupChanged() {
            root.config.scheduleSave();
        }
        function onWallpaperSolidColorsByMonitorChanged() {
            root.config.scheduleSave();
        }
        function onWallpaperRecentSolidColorsChanged() {
            root.config.scheduleSave();
        }
    }
}
