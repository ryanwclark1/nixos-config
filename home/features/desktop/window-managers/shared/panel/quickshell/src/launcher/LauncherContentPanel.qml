import QtQuick
import QtQuick.Layouts
import "../services"
import "../shared"

// LauncherContentPanel: right-side column inside the launcher HUD.
// Contains the search field, mode hints, web bars, transient notice, metrics,
// home view, orchestrator view, and the result/media stack.
// Exposes `searchInput` so Launcher.qml can manage focus externally.
//
// Implemented as Item + internal ColumnLayout so the ContextMenu can be a
// non-layout sibling (ContextMenu uses x/y positioning and must not be
// managed by a layout).
Item {
    id: root

    required property var launcher

    // Expose the inner TextInput so the parent window can call
    // forceActiveFocus(), set text, and manage focus visibility.
    readonly property alias searchInput: searchField.searchInput

    // ── Internal column ───────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: launcher.compactMode ? Colors.spacingS : Colors.spacingM

        // ── Search field ──────────────────────────────────────────────────
        LauncherSearchField {
            id: searchField
            Layout.fillWidth: true
            Layout.bottomMargin: launcher.tightMode ? 0 : Colors.spacingXXS
            text: launcher.searchText
            accentColor: Colors.primary
            placeholder: launcher.activeModeHintText
            statusText: launcher.escapeStatusText
            statusIcon: launcher.escapeStatusIcon
            onAccepted: modifiers => launcher.handleSearchAccepted(modifiers)

            onTextChanged: {
                if (text.startsWith("=") && launcher.mode !== "calc")
                    launcher.open("calc", true);
                else if (text.startsWith(">") && launcher.mode !== "run")
                    launcher.open("run", true);
                else if (launcher.matchesCharacterTrigger(text) && launcher.mode !== "emoji")
                    launcher.open("emoji", true);
                else if (text.startsWith("?") && launcher.mode !== "web")
                    launcher.open("web", true);
                else if (text.startsWith("!") && launcher.mode !== "ai")
                    launcher.open("ai", true);
                else if (text.startsWith("@") && launcher.mode !== "bookmarks")
                    launcher.open("bookmarks", true);
                else if (text.startsWith("/") && launcher.mode !== "files")
                    launcher.open("files", true);
                else if (text.startsWith(",") && launcher.mode !== "settings")
                    launcher.open("settings", true);
                else if (text.startsWith(";") && launcher.mode !== "ssh")
                    launcher.open("ssh", true);
                else if (text.startsWith("~") && launcher.mode !== "window")
                    launcher.open("window", true);
                else if (PluginService.shouldOpenPluginsModeForQuery(text) && launcher.mode !== "plugins")
                    launcher.open("plugins", true);
                if (launcher.searchText !== text) {
                    launcher.searchText = text;
                    launcher.scheduleSearchRefresh(false);
                }
            }

            Connections {
                target: searchField.searchInput
                function onVisibleChanged() {
                    if (!searchField.searchInput.visible && searchField.searchInput.activeFocus)
                        searchField.searchInput.focus = false;
                }
            }

            LauncherKeyHandler {
                id: keyHandler
                launcher: root.launcher
            }

            Keys.onPressed: event => keyHandler.handleKeyPress(event)
        }

        // ── Prefix quick-mode strip ───────────────────────────────────────
        LauncherPrefixStrip {
            Layout.fillWidth: true
            launcher: root.launcher
            visible: !launcher.tightMode && launcher.prefixQuickModes.length > 0
        }

        // ── Action legend ─────────────────────────────────────────────────
        LauncherActionLegend {
            visible: Config.launcherShowModeHints && !launcher.tightMode
            Layout.bottomMargin: visible ? Colors.spacingXXS : 0
            summaryText: launcher.modeSummaryText
            primaryAction: launcher.legendPrimaryAction
            secondaryAction: launcher.legendSecondaryAction
            tertiaryAction: launcher.legendTertiaryAction
            compact: launcher.compactMode || launcher.webHintCompact
            helpExpanded: launcher.shortcutHelpExpanded
            onHelpToggled: launcher.shortcutHelpExpanded = !launcher.shortcutHelpExpanded
        }

        // ── Web provider bar ──────────────────────────────────────────────
        LauncherWebProviderBar {
            visible: launcher.mode === "web" && launcher.filteredItems.length > 0
            providers: launcher.configuredWebProviders()
            selectedKey: launcher.selectedWebProviderKey
            onProviderSelected: key => launcher.selectWebProviderByKey(key)
        }

        // ── Web hints ─────────────────────────────────────────────────────
        LauncherWebHints {
            visible: Config.launcherShowModeHints && launcher.mode === "web" && !launcher.tightMode
            primaryEnterHint: launcher.webPrimaryEnterHint
            secondaryEnterHint: launcher.webSecondaryEnterHint
            aliasHint: launcher.webAliasHint
            hotkeyHint: launcher.webHotkeyHint
            compact: launcher.webHintCompact
        }

        // ── Transient notice ──────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            visible: launcher.transientNoticeText !== "" && !launcher.tightMode
            color: Colors.primarySubtle
            radius: Colors.radiusMedium
            border.color: Colors.withAlpha(Colors.primary, 0.5)
            border.width: 1
            implicitHeight: transientNoticeLabel.implicitHeight + (Colors.spacingS * 2)

            Text {
                id: transientNoticeLabel
                anchors.fill: parent
                anchors.margins: Colors.spacingS
                text: launcher.transientNoticeText
                color: Colors.primary
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
        }

        // ── Debug metrics ─────────────────────────────────────────────────
        LauncherMetricsBox {
            metrics: launcher.launcherMetrics
            mode: launcher.mode
            tightMode: launcher.tightMode
            filesBackendLabel: launcher.filesBackendLabel
            filesCacheStatsLabel: launcher.filesCacheStatsLabel
            modeMetricFn: launcher.modeMetric
            onResetRequested: launcher.clearLauncherMetrics()
        }

        // ── Home sections (recent / suggestions) ──────────────────────────
        LauncherHome {
            Layout.fillWidth: true
            launcher: root.launcher
            visible: launcher.showLauncherHomePanel && !launcher.isModeLoading
            showHomeSections: false
        }

        // ── Orchestrator view ─────────────────────────────────────────────
        OrchestratorView {
            visible: launcher.mode === "orchestrator" && launcher.searchText === ""
        }

        // ── Results / loading / empty / media ─────────────────────────────
        LauncherResultView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            launcher: root.launcher
            onFileContextMenuRequested: function(menuModel, menuPoint) {
                // menuPoint is in launcherRoot coords; remap into this Item's coords.
                var localPt = root.mapFromItem(root.launcher, menuPoint.x, menuPoint.y);
                fileResultContextMenu.model = menuModel;
                fileResultContextMenu.popup(localPt.x, localPt.y);
            }
        }
    } // end ColumnLayout

    // ── File result context menu ───────────────────────────────────────────
    // Must be a non-layout child (uses x/y absolute positioning with z:9999).
    ContextMenu {
        id: fileResultContextMenu
    }
}
