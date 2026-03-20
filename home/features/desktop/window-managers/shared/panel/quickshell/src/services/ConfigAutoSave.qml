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
        function onWeatherOverlayEnabledChanged() {
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
        function onAutoTransparencyChanged() {
            root.config.scheduleSave();
        }
        function onHotCornersEnabledChanged() {
            root.config.scheduleSave();
        }
        function onShowScreenBordersChanged() {
            root.config.scheduleSave();
        }
        function onShowScreenCornersChanged() {
            root.config.scheduleSave();
        }
        function onScreenCornerRadiusChanged() {
            root.config.scheduleSave();
        }
        function onOledModeChanged() {
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
        function onRecordingCaptureSourceChanged() {
            root.config.scheduleSave();
        }
        function onRecordingFpsChanged() {
            root.config.scheduleSave();
        }
        function onRecordingQualityChanged() {
            root.config.scheduleSave();
        }
        function onRecordingRecordCursorChanged() {
            root.config.scheduleSave();
        }
        function onRecordingOutputDirChanged() {
            root.config.scheduleSave();
        }
        function onRecordingIncludeDesktopAudioChanged() {
            root.config.scheduleSave();
        }
        function onRecordingIncludeMicrophoneAudioChanged() {
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
        function onEnabledPanelsChanged() {
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
        function onDebugChanged() {
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
        function onAiProviderChanged() {
            root.config.scheduleSave();
        }
        function onAiModelChanged() {
            root.config.scheduleSave();
        }
        function onAiCustomEndpointChanged() {
            root.config.scheduleSave();
        }
        function onAiSystemContextChanged() {
            root.config.scheduleSave();
        }
        function onAiMaxTokensChanged() {
            root.config.scheduleSave();
        }
        function onAiTemperatureChanged() {
            root.config.scheduleSave();
        }
        function onAiSystemPromptChanged() {
            root.config.scheduleSave();
        }
        function onAiAnthropicKeyChanged() {
            root.config.scheduleSave();
        }
        function onAiOpenaiKeyChanged() {
            root.config.scheduleSave();
        }
        function onAiGeminiKeyChanged() {
            root.config.scheduleSave();
        }
        function onAiMaxConversationsChanged() {
            root.config.scheduleSave();
        }
        function onAiMaxMessagesChanged() {
            root.config.scheduleSave();
        }
        function onAiProviderProfilesChanged() {
            root.config.scheduleSave();
        }
        function onAiTimeoutChanged() {
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
        function onWallpaperDynamicEnabledChanged() {
            root.config.scheduleSave();
        }
        function onWallpaperDynamicManifestChanged() {
            root.config.scheduleSave();
        }
        function onWallpaperVideoEnabledChanged() {
            root.config.scheduleSave();
        }
        function onWallpaperVideoPathChanged() {
            root.config.scheduleSave();
        }
        function onWallhavenApiKeyChanged() {
            root.config.scheduleSave();
        }
        function onWallhavenLastQueryChanged() {
            root.config.scheduleSave();
        }
        function onWallhavenDownloadDirChanged() {
            root.config.scheduleSave();
        }
        function onGlassOpacityBaseChanged() {
            root.config.scheduleSave();
        }
        function onGlassOpacitySurfaceChanged() {
            root.config.scheduleSave();
        }
        function onGlassOpacityOverlayChanged() {
            root.config.scheduleSave();
        }
        function onUseDynamicThemingChanged() {
            root.config.scheduleSave();
        }
        function onColorBackendChanged() {
            root.config.scheduleSave();
        }
        function onAutoEcoModeChanged() {
            root.config.scheduleSave();
        }
        function onUiDensityScaleChanged() {
            root.config.scheduleSave();
        }
        function onAnimationSpeedScaleChanged() {
            root.config.scheduleSave();
        }
        function onBackgroundUseShaderVisualizerChanged() {
            root.config.scheduleSave();
        }
        function onPersonalityGifEnabledChanged() {
            root.config.scheduleSave();
        }
        function onPersonalityGifPathChanged() {
            root.config.scheduleSave();
        }
        function onPersonalityGifReactionModeChanged() {
            root.config.scheduleSave();
        }
        function onBarUseModularEntriesChanged() {
            root.config.scheduleSave();
        }
        function onModelUsageClaudeEnabledChanged() {
            root.config.scheduleSave();
        }
        function onModelUsageCodexEnabledChanged() {
            root.config.scheduleSave();
        }
        function onModelUsageGeminiEnabledChanged() {
            root.config.scheduleSave();
        }
        function onModelUsageActiveProviderChanged() {
            root.config.scheduleSave();
        }
        function onModelUsageBarMetricChanged() {
            root.config.scheduleSave();
        }
        function onModelUsageRefreshSecChanged() {
            root.config.scheduleSave();
        }
        function onWorkspaceShowEmptyChanged() {
            root.config.scheduleSave();
        }
        function onWorkspaceShowNamesChanged() {
            root.config.scheduleSave();
        }
        function onWorkspaceStyleChanged() {
            root.config.scheduleSave();
        }
        function onWorkspacePillSizeChanged() {
            root.config.scheduleSave();
        }
        function onWorkspaceShowAppIconsChanged() {
            root.config.scheduleSave();
        }
        function onWorkspaceMaxIconsChanged() {
            root.config.scheduleSave();
        }
        function onWorkspaceScrollEnabledChanged() {
            root.config.scheduleSave();
        }
        function onWorkspaceReverseScrollChanged() {
            root.config.scheduleSave();
        }
        function onWorkspaceShowWindowCountChanged() {
            root.config.scheduleSave();
        }
        function onWorkspaceLayoutChanged() {
            root.config.scheduleSave();
        }
        function onWorkspaceClickBehaviorChanged() {
            root.config.scheduleSave();
        }
        function onNotepadProjectSyncChanged() {
            root.config.scheduleSave();
        }
        function onWorkspaceActiveColorChanged() {
            root.config.scheduleSave();
        }
        function onWorkspaceUrgentColorChanged() {
            root.config.scheduleSave();
        }
        function onNotifPositionChanged() {
            root.config.scheduleSave();
        }
        function onNotifTimeoutLowChanged() {
            root.config.scheduleSave();
        }
        function onNotifTimeoutNormalChanged() {
            root.config.scheduleSave();
        }
        function onNotifTimeoutCriticalChanged() {
            root.config.scheduleSave();
        }
        function onNotifCompactChanged() {
            root.config.scheduleSave();
        }
        function onNotifPrivacyModeChanged() {
            root.config.scheduleSave();
        }
        function onNotifHistoryEnabledChanged() {
            root.config.scheduleSave();
        }
        function onNotifHistoryMaxCountChanged() {
            root.config.scheduleSave();
        }
        function onNotifHistoryMaxAgeDaysChanged() {
            root.config.scheduleSave();
        }
        function onNotifRulesChanged() {
            root.config.scheduleSave();
        }
        function onNotifTtsEnabledChanged() {
            root.config.scheduleSave();
        }
        function onNotifTtsEngineChanged() {
            root.config.scheduleSave();
        }
        function onNotifTtsRateChanged() {
            root.config.scheduleSave();
        }
        function onNotifTtsVolumeChanged() {
            root.config.scheduleSave();
        }
        function onNotifTtsExcludedAppsChanged() {
            root.config.scheduleSave();
        }
        function onPowerAcMonitorTimeoutChanged() {
            root.config.scheduleSave();
        }
        function onPowerAcLockTimeoutChanged() {
            root.config.scheduleSave();
        }
        function onPowerAcSuspendTimeoutChanged() {
            root.config.scheduleSave();
        }
        function onPowerAcSuspendActionChanged() {
            root.config.scheduleSave();
        }
        function onPowerBatMonitorTimeoutChanged() {
            root.config.scheduleSave();
        }
        function onPowerBatLockTimeoutChanged() {
            root.config.scheduleSave();
        }
        function onPowerBatSuspendTimeoutChanged() {
            root.config.scheduleSave();
        }
        function onPowerBatSuspendActionChanged() {
            root.config.scheduleSave();
        }
        function onLauncherCharacterPasteOnSelectChanged() {
            root.config.scheduleSave();
        }
        function onLauncherCharacterTriggerChanged() {
            root.config.scheduleSave();
        }
        function onLauncherFileSearchRootChanged() {
            root.config.scheduleSave();
        }
        function onLauncherFileShowHiddenChanged() {
            root.config.scheduleSave();
        }
        function onLauncherFilePreviewEnabledChanged() {
            root.config.scheduleSave();
        }
        function onLauncherFileOpenerChanged() {
            root.config.scheduleSave();
        }
        function onLauncherWebCustomEnginesChanged() {
            root.config.scheduleSave();
        }
        function onLauncherWebBangsEnabledChanged() {
            root.config.scheduleSave();
        }
        function onLauncherWebBangsLastSyncChanged() {
            root.config.scheduleSave();
        }
        function onNightLightAutoScheduleChanged() {
            root.config.scheduleSave();
        }
        function onNightLightScheduleModeChanged() {
            root.config.scheduleSave();
        }
        function onNightLightStartHourChanged() {
            root.config.scheduleSave();
        }
        function onNightLightStartMinuteChanged() {
            root.config.scheduleSave();
        }
        function onNightLightEndHourChanged() {
            root.config.scheduleSave();
        }
        function onNightLightEndMinuteChanged() {
            root.config.scheduleSave();
        }
        function onNightLightLatitudeChanged() {
            root.config.scheduleSave();
        }
        function onNightLightLongitudeChanged() {
            root.config.scheduleSave();
        }
        function onThemeAutoScheduleEnabledChanged() {
            root.config.scheduleSave();
        }
        function onThemeAutoScheduleModeChanged() {
            root.config.scheduleSave();
        }
        function onThemeDarkNameChanged() {
            root.config.scheduleSave();
        }
        function onThemeLightNameChanged() {
            root.config.scheduleSave();
        }
        function onThemeDarkHourChanged() {
            root.config.scheduleSave();
        }
        function onThemeDarkMinuteChanged() {
            root.config.scheduleSave();
        }
        function onThemeLightHourChanged() {
            root.config.scheduleSave();
        }
        function onThemeLightMinuteChanged() {
            root.config.scheduleSave();
        }
        function onThemeAutoLatitudeChanged() {
            root.config.scheduleSave();
        }
        function onThemeAutoLongitudeChanged() {
            root.config.scheduleSave();
        }
        function onMarketTickersChanged() {
            root.config.scheduleSave();
        }
        function onAudioPinnedOutputsChanged() {
            root.config.scheduleSave();
        }
        function onAudioPinnedInputsChanged() {
            root.config.scheduleSave();
        }
        function onAudioHiddenOutputsChanged() {
            root.config.scheduleSave();
        }
        function onAudioHiddenInputsChanged() {
            root.config.scheduleSave();
        }
        function onDisplayProfilesChanged() {
            root.config.scheduleSave();
        }
        function onDisplayAutoProfileChanged() {
            root.config.scheduleSave();
        }
        function onWallpaperTransitionTypeChanged() {
            root.config.scheduleSave();
        }
        function onWallpaperTransitionDurationChanged() {
            root.config.scheduleSave();
        }
        function onWallpaperUseShellRendererChanged() {
            root.config.scheduleSave();
        }
        function onScreenshotEditAfterCaptureChanged() {
            root.config.scheduleSave();
        }
        function onScreenshotEditorChanged() {
            root.config.scheduleSave();
        }
        function onScreenshotDelayChanged() {
            root.config.scheduleSave();
        }
        function onOcrLanguageChanged() {
            root.config.scheduleSave();
        }
        function onScreenshotHistoryMaxChanged() {
            root.config.scheduleSave();
        }
    }
}
