import QtQuick
import QtQuick.Layouts
import "../services"
import "../shared"
import "../widgets" as SharedWidgets

Item {
    id: root

    required property var launcher

    readonly property alias searchInput: searchField.searchInput
    readonly property color accentColor: launcher.modeAccentColor ? launcher.modeAccentColor : Colors.primary
    readonly property bool showAssistBand: !launcher.tightMode && (launcher.prefixQuickModes.length > 0
        || Config.launcherShowModeHints
        || (launcher.mode === "web" && launcher.filteredItems.length > 0)
        || launcher.transientNoticeText !== "")

    ColumnLayout {
        anchors.fill: parent
        spacing: launcher.compactMode ? Colors.spacingS : Colors.spacingM

        Rectangle {
            Layout.fillWidth: true
            radius: Colors.radiusXL
            color: Colors.withAlpha(Colors.surface, 0.78)
            border.color: Colors.withAlpha(root.accentColor, 0.26)
            border.width: 1
            implicitHeight: deckColumn.implicitHeight + (launcher.tightMode ? Colors.spacingM * 2 : Colors.spacingL * 2)

            SharedWidgets.InnerHighlight {
                highlightOpacity: 0.16
            }

            SharedWidgets.SurfaceGradient {}

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 4
                radius: Colors.radiusPill
                color: Colors.withAlpha(root.accentColor, 0.9)
                opacity: 0.78
            }

            ColumnLayout {
                id: deckColumn
                anchors.fill: parent
                anchors.margins: launcher.tightMode ? Colors.spacingM : Colors.spacingL
                spacing: launcher.compactMode ? Colors.spacingS : Colors.spacingM

                RowLayout {
                    visible: !launcher.tightMode
                    Layout.fillWidth: true
                    spacing: Colors.spacingM

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: "COMMAND DECK"
                            color: Colors.withAlpha(root.accentColor, 0.92)
                            font.pixelSize: Colors.fontSizeXXS
                            font.weight: Font.Black
                            font.letterSpacing: Colors.letterSpacingExtraWide
                        }

                        Text {
                            Layout.fillWidth: true
                            text: launcher.modeHeroLabel
                            color: Colors.text
                            font.pixelSize: launcher.compactMode ? Colors.fontSizeLarge : Colors.fontSizeXL
                            font.weight: Font.Black
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: launcher.modeSummaryText
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeXS
                            wrapMode: Text.WordWrap
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        radius: Colors.radiusPill
                        color: Colors.withAlpha(root.accentColor, 0.14)
                        border.color: Colors.withAlpha(root.accentColor, 0.32)
                        border.width: 1
                        implicitHeight: 26
                        implicitWidth: deckModeLabel.implicitWidth + 18

                        Text {
                            id: deckModeLabel
                            anchors.centerIn: parent
                            text: launcher.currentModeMeta.label || "Launcher"
                            color: root.accentColor
                            font.pixelSize: Colors.fontSizeXS
                            font.weight: Font.Black
                            font.capitalization: Font.AllUppercase
                        }
                    }
                }

                LauncherSearchField {
                    id: searchField
                    Layout.fillWidth: true
                    launcher: root.launcher
                    text: launcher.searchText
                    accentColor: root.accentColor
                    embedded: true
                    modeLabel: launcher.modeShortLabel
                    modeSubtitle: launcher.activeModeHintText
                    modeIconText: launcher.modeHeroIcon
                    modePrefix: launcher.modePrefixText
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

                Rectangle {
                    Layout.fillWidth: true
                    visible: root.showAssistBand
                    implicitHeight: 1
                    color: Colors.withAlpha(root.accentColor, 0.16)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.showAssistBand
                    spacing: launcher.compactMode ? Colors.spacingS : Colors.spacingM

                    LauncherPrefixStrip {
                        Layout.fillWidth: true
                        launcher: root.launcher
                        accentColor: root.accentColor
                        visible: launcher.prefixQuickModes.length > 0
                    }

                    LauncherActionLegend {
                        visible: Config.launcherShowModeHints
                        summaryText: launcher.modeSummaryText
                        primaryAction: launcher.legendPrimaryAction
                        secondaryAction: launcher.legendSecondaryAction
                        tertiaryAction: launcher.legendTertiaryAction
                        compact: launcher.compactMode || launcher.webHintCompact
                        accentColor: root.accentColor
                        helpExpanded: launcher.shortcutHelpExpanded
                        onHelpToggled: launcher.shortcutHelpExpanded = !launcher.shortcutHelpExpanded
                    }

                    LauncherWebProviderBar {
                        visible: launcher.mode === "web" && launcher.filteredItems.length > 0
                        providers: launcher.configuredWebProviders()
                        selectedKey: launcher.selectedWebProviderKey
                        accentColor: root.accentColor
                        onProviderSelected: key => launcher.selectWebProviderByKey(key)
                    }

                    LauncherWebHints {
                        visible: Config.launcherShowModeHints && launcher.mode === "web"
                        primaryEnterHint: launcher.webPrimaryEnterHint
                        secondaryEnterHint: launcher.webSecondaryEnterHint
                        aliasHint: launcher.webAliasHint
                        hotkeyHint: launcher.webHotkeyHint
                        accentColor: root.accentColor
                        compact: launcher.webHintCompact
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        visible: launcher.transientNoticeText !== "" && !launcher.tightMode
                        color: Colors.withAlpha(root.accentColor, 0.12)
                        radius: Colors.radiusLarge
                        border.color: Colors.withAlpha(root.accentColor, 0.3)
                        border.width: 1
                        implicitHeight: transientNoticeLabel.implicitHeight + (Colors.spacingS * 2)

                        Text {
                            id: transientNoticeLabel
                            anchors.fill: parent
                            anchors.margins: Colors.spacingS
                            text: launcher.transientNoticeText
                            color: root.accentColor
                            font.pixelSize: Colors.fontSizeXS
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }

        LauncherMetricsBox {
            metrics: launcher.launcherMetrics
            mode: launcher.mode
            tightMode: launcher.tightMode
            filesBackendLabel: launcher.filesBackendLabel
            filesCacheStatsLabel: launcher.filesCacheStatsLabel
            modeMetricFn: launcher.modeMetric
            accentColor: root.accentColor
            onResetRequested: launcher.clearLauncherMetrics()
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Colors.radiusXL
            color: Colors.withAlpha(Colors.surface, 0.72)
            border.color: Colors.withAlpha(root.accentColor, 0.18)
            border.width: 1

            SharedWidgets.InnerHighlight {
                highlightOpacity: 0.14
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: launcher.tightMode ? Colors.spacingM : Colors.spacingL
                spacing: launcher.compactMode ? Colors.spacingS : Colors.spacingM

                LauncherHome {
                    Layout.fillWidth: true
                    launcher: root.launcher
                    visible: launcher.mode === "drun" && launcher.showLauncherHomePanel && !launcher.isModeLoading
                    showHomeSections: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    visible: (launcher.mode === "drun" && launcher.showLauncherHomePanel && !launcher.isModeLoading)
                        && !(launcher.mode === "orchestrator" && launcher.searchText === "")
                    implicitHeight: 1
                    color: Colors.withAlpha(root.accentColor, 0.12)
                }

                OrchestratorView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: launcher.mode === "orchestrator" && launcher.searchText === ""
                }

                LauncherResultView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    launcher: root.launcher
                    visible: !(launcher.mode === "orchestrator" && launcher.searchText === "")
                    onFileContextMenuRequested: function(menuModel, menuPoint) {
                        var localPt = root.mapFromItem(root.launcher, menuPoint.x, menuPoint.y);
                        fileResultContextMenu.model = menuModel;
                        fileResultContextMenu.popup(localPt.x, localPt.y);
                    }
                }
            }
        }
    }

    ContextMenu {
        id: fileResultContextMenu
    }
}
