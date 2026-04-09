import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../shared"
import "../../services"
import "../../services/ShellUtils.js" as SU
import "../../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMinWidth: 440; popupMaxWidth: 600; compactThreshold: 500
  implicitHeight: Math.min(780, scrollContent.implicitHeight + 120)
  title: "AI Model Usage"
  subtitle: ModelUsageService.providerLabel

  // Provider-specific surface tint (like MusicMenu album accent)
  surfaceTint: Colors.withAlpha(root.providerAccent, 0.06)

  SharedWidgets.Ref { service: ModelUsageService }

  onVisibleChanged: {
    if (visible) {
      ModelUsageService.refresh();
      if (ModelUsageService.claudeEnabled)
        ModelUsageService.refreshRateLimit();
    }
  }

  // ── Provider state ───────────────────────────────
  readonly property bool showClaude: ModelUsageService.effectiveActiveProvider === "claude"
  readonly property bool showCodex: ModelUsageService.effectiveActiveProvider === "codex"
  readonly property bool showGemini: ModelUsageService.effectiveActiveProvider === "gemini"
  readonly property bool showProviderTabs: ModelUsageService.enabledProviders.length > 1

  function sumObjectValues(map) {
    var total = 0;
    if (!map)
      return total;
    for (var key in map) {
      if (map.hasOwnProperty(key))
        total += Number(map[key] || 0);
    }
    return total;
  }

  function recentPromptTotal(days) {
    var total = 0;
    if (!days)
      return total;
    for (var i = 0; i < days.length; i++)
      total += Number(days[i].messageCount || 0);
    return total;
  }

  function activeModelLabel() {
    if (root.showClaude) {
      var keys = Object.keys(ModelUsageService.claudeTodayTokensByModel);
      return keys.length > 0 ? ModelUsageService.friendlyModelName(keys[0]) : "";
    }
    if (root.showGemini)
      return ModelUsageService.geminiModel !== "unknown" ? ModelUsageService.geminiModel : "";
    return ModelUsageService.codexModel !== "unknown" ? ModelUsageService.codexModel : "";
  }

  function providerSummaryTiles() {
    if (root.showClaude) {
      var fiveHour = ModelUsageService.claudeUsageWindows.fiveHour || {};
      return [
        { label: "Sessions", value: String(ModelUsageService.claudeTodaySessions || 0), accent: false },
        { label: "Tool Calls", value: String(ModelUsageService.claudeTodayToolCalls || 0), accent: false },
        { label: "Tokens Today", value: ModelUsageService.formatTokenCount(root.sumObjectValues(ModelUsageService.claudeTodayTokensByModel)), accent: true },
        {
          label: "5h Window",
          value: fiveHour.utilization !== undefined && fiveHour.utilization !== null
            ? Math.floor(Number(fiveHour.utilization || 0)) + "%"
            : ((ModelUsageService.claudeLiveRateLimit.status || "") !== "" ? String(ModelUsageService.claudeLiveRateLimit.status) : "Unavailable"),
          accent: true
        }
      ];
    }
    if (root.showGemini) {
      return [
        { label: "Sessions", value: String(ModelUsageService.geminiTodaySessions || 0), accent: false },
        { label: "Input", value: ModelUsageService.formatTokenCount(ModelUsageService.geminiTodayTokens.input || 0), accent: true },
        { label: "Output", value: ModelUsageService.formatTokenCount(ModelUsageService.geminiTodayTokens.output || 0), accent: true },
        { label: "24h Prompts", value: String(ModelUsageService.geminiLast24hPrompts || 0), accent: false }
      ];
    }
    return [
      { label: "Model", value: ModelUsageService.codexModel !== "unknown" ? ModelUsageService.codexModel : "Unknown", accent: true },
      { label: "Latest Input", value: ModelUsageService.formatTokenCount(ModelUsageService.codexLatestSession.inputTokens || 0), accent: false },
      { label: "Latest Output", value: ModelUsageService.formatTokenCount(ModelUsageService.codexLatestSession.outputTokens || 0), accent: false },
      { label: "7d Prompts", value: String(root.recentPromptTotal(ModelUsageService.codexRecentDays || [])), accent: true }
    ];
  }

  function providerEmptyMessage() {
    if (root.showClaude) return "No Claude Code data found yet";
    if (root.showGemini) return "No Gemini CLI data found yet";
    return "No Codex CLI data found yet";
  }

  // Provider accent — flows through hero, charts, token values
  property color providerAccent: ModelUsageService.providerColor
  Behavior on providerAccent { ColorAnimation { duration: Appearance.durationNormal } }

  // ── Header actions ────────────────────────────────
  headerExtras: [
    SharedWidgets.IconButton {
      icon: "arrow-counterclockwise.svg"
      size: 28
      iconSize: Appearance.fontSizeLarge
      tooltipText: "Refresh"
      onClicked: {
        ModelUsageService.refresh();
        if (ModelUsageService.claudeEnabled)
          ModelUsageService.refreshRateLimit();
      }
    },
    SharedWidgets.IconButton {
      icon: "settings.svg"
      size: 28
      iconSize: Appearance.fontSizeLarge
      tooltipText: "Settings"
      onClicked: {
        Quickshell.execDetached(SU.ipcCall("SettingsHub", "openTab", "model-usage"));
        root.closeRequested();
      }
    }
  ]

  // ── Content cross-fade on provider switch ────
  property string _prevProvider: ModelUsageService.effectiveActiveProvider
  onProviderAccentChanged: {
    if (_prevProvider !== ModelUsageService.effectiveActiveProvider) {
      _prevProvider = ModelUsageService.effectiveActiveProvider;
      contentFade.restart();
    }
  }

  SequentialAnimation {
    id: contentFade
    NumberAnimation { target: scrollContent; property: "opacity"; to: 0; duration: Appearance.durationFlash; easing.type: Easing.OutQuad }
    NumberAnimation { target: scrollContent; property: "opacity"; to: 1; duration: Appearance.durationFast; easing.type: Easing.InOutQuad }
  }

  SharedWidgets.ScrollableContent {
    id: scrollContent
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Appearance.spacingML
    layer.enabled: contentFade.running

    SharedWidgets.ThemedContainer {
      variant: "elevated"
      Layout.fillWidth: true
      visible: ModelUsageService.hasEnabledProviders
      implicitHeight: providerSwitcherCol.implicitHeight + Appearance.spacingL * 2

      ColumnLayout {
        id: providerSwitcherCol
        anchors.fill: parent
        anchors.margins: Appearance.spacingL
        spacing: Appearance.spacingS

        Text {
          text: "Providers"
          color: Colors.text
          font.pixelSize: Appearance.fontSizeSmall
          font.weight: Font.DemiBold
          font.letterSpacing: Appearance.letterSpacingWide
        }

        Text {
          text: "Switch between enabled assistants. The bar icon follows the active provider."
          color: Colors.textSecondary
          font.pixelSize: Appearance.fontSizeXS
          Layout.fillWidth: true
          wrapMode: Text.WordWrap
        }

        Flow {
          id: providerTabsWrap
          Layout.fillWidth: true
          spacing: Appearance.spacingS

          Repeater {
            model: {
              var tabs = [];
              if (ModelUsageService.claudeEnabled) tabs.push({ key: "claude", label: "Claude Code", icon: "brands/anthropic-symbolic.svg" });
              if (ModelUsageService.codexEnabled) tabs.push({ key: "codex", label: "Codex CLI", icon: "brands/openai-symbolic.svg" });
              if (ModelUsageService.geminiEnabled) tabs.push({ key: "gemini", label: "Gemini CLI", icon: "brands/google-gemini-symbolic.svg" });
              return tabs;
            }

            delegate: SharedWidgets.FilterChip {
              required property var modelData
              label: modelData.label
              icon: modelData.icon
              selected: ModelUsageService.effectiveActiveProvider === modelData.key
              onClicked: Config.modelUsageActiveProvider = modelData.key
            }
          }
        }
      }
    }

    SharedWidgets.ThemedContainer {
      Layout.fillWidth: true
      visible: !ModelUsageService.hasEnabledProviders
      implicitHeight: noProviderCol.implicitHeight + Appearance.spacingXL

      ColumnLayout {
        id: noProviderCol
        anchors.centerIn: parent
        width: Math.min(parent.width - Appearance.spacingXL * 2, 360)
        spacing: Appearance.spacingS

        SharedWidgets.EmptyState {
          Layout.fillWidth: true
          icon: "board.svg"
          message: "Enable at least one provider in AI Model Usage settings"
        }

        Text {
          text: "The popup becomes most useful when Claude, Codex, or Gemini is enabled here."
          color: Colors.textSecondary
          font.pixelSize: Appearance.fontSizeXS
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
          Layout.fillWidth: true
        }
      }
    }

    // ── Hero Summary Card ───────────────────────────
    Rectangle {
      Layout.fillWidth: true
      visible: ModelUsageService.hasEnabledProviders && ModelUsageService.isReady
      implicitHeight: heroGrid.implicitHeight + Appearance.spacingXL * 2
      radius: Appearance.radiusLarge
      color: Colors.withAlpha(root.providerAccent, Colors.primaryFaint)
      border.color: Colors.withAlpha(root.providerAccent, 0.18)
      border.width: 1

      Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationNormal } }
      Behavior on border.color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationNormal } }

      SharedWidgets.InnerHighlight { }

      GridLayout {
        id: heroGrid
        anchors.fill: parent
        anchors.margins: Appearance.spacingXL
        columns: root.compactMode ? 1 : 3
        spacing: Appearance.spacingL

        // Large provider icon
        Rectangle {
          Layout.alignment: root.compactMode ? Qt.AlignLeft : Qt.AlignTop
          Layout.preferredWidth: 60
          Layout.preferredHeight: 60
          radius: Appearance.radiusCard
          color: Colors.withAlpha(root.providerAccent, Colors.primarySubtle)
          Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationNormal } }

          SharedWidgets.SvgIcon {
            anchors.centerIn: parent
            source: ModelUsageService.providerIcon
            color: root.providerAccent
            size: Appearance.fontSizeHuge
            Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationNormal } }
          }
        }

        // Big metric
        ColumnLayout {
          Layout.fillWidth: true
          Layout.columnSpan: root.compactMode ? 1 : 1
          spacing: Appearance.spacingXXS

          Text {
            text: String(ModelUsageService.todayPrompts)
            color: Colors.text
            font.pixelSize: Appearance.fontSizeDisplay
            font.weight: Font.Bold
            font.letterSpacing: Appearance.letterSpacingTight
          }

          Text {
            text: "prompts today"
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeSmall
          }

          Text {
            text: "Tracked from local assistant activity and refreshed on demand"
            color: Colors.textDisabled
            font.pixelSize: Appearance.fontSizeXS
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
          }
        }

        // Model badge
        Rectangle {
          visible: {
            return root.activeModelLabel() !== "";
          }
          Layout.alignment: root.compactMode ? Qt.AlignLeft : Qt.AlignTop
          implicitWidth: modelBadgeText.implicitWidth + Appearance.spacingM * 2
          implicitHeight: modelBadgeText.implicitHeight + Appearance.spacingSM * 2
          radius: height / 2
          color: Colors.withAlpha(root.providerAccent, Colors.primaryGhost)
          Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationNormal } }

          Text {
            id: modelBadgeText
            anchors.centerIn: parent
            text: root.activeModelLabel()
            color: root.providerAccent
            font.pixelSize: Appearance.fontSizeXS
            font.weight: Font.DemiBold
            Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationNormal } }
          }
        }
      }
    }

    SharedWidgets.ThemedContainer {
      variant: "card"
      Layout.fillWidth: true
      visible: ModelUsageService.hasEnabledProviders && ModelUsageService.isReady
      implicitHeight: overviewCol.implicitHeight + Appearance.spacingL * 2

      ColumnLayout {
        id: overviewCol
        anchors.fill: parent
        anchors.margins: Appearance.spacingL
        spacing: Appearance.spacingS

        Text {
          text: "Overview"
          color: Colors.text
          font.pixelSize: Appearance.fontSizeMedium
          font.weight: Font.Bold
        }

        GridLayout {
          Layout.fillWidth: true
          columns: root.compactMode ? 2 : 4
          columnSpacing: Appearance.spacingM
          rowSpacing: Appearance.spacingM

          Repeater {
            model: root.providerSummaryTiles()

            delegate: Rectangle {
              required property var modelData
              Layout.fillWidth: true
              color: modelData.accent
                ? Colors.withAlpha(root.providerAccent, Colors.primarySubtle)
                : Colors.withAlpha(Colors.surface, Colors.opacitySurface)
              border.color: modelData.accent
                ? Colors.withAlpha(root.providerAccent, 0.2)
                : Colors.border
              border.width: 1
              radius: Appearance.radiusMedium
              implicitHeight: tileCol.implicitHeight + Appearance.spacingM * 2

              ColumnLayout {
                id: tileCol
                anchors.fill: parent
                anchors.margins: Appearance.spacingM
                spacing: Appearance.spacingXXS

                Text {
                  text: modelData.label
                  color: modelData.accent ? root.providerAccent : Colors.textDisabled
                  font.pixelSize: Appearance.fontSizeXS
                  font.weight: Font.Medium
                  font.letterSpacing: Appearance.letterSpacingWide
                  Layout.fillWidth: true
                  wrapMode: Text.WordWrap
                }

                Text {
                  text: modelData.value
                  color: modelData.accent ? root.providerAccent : Colors.text
                  font.pixelSize: Appearance.fontSizeLarge
                  font.weight: Font.Bold
                  Layout.fillWidth: true
                  wrapMode: Text.WordWrap
                }
              }
            }
          }
        }
      }
    }

    // ── Claude Limits Section ─────────────────────────
    SharedWidgets.ThemedContainer {
      variant: "card"
      Layout.fillWidth: true
      visible: root.showClaude && (
        Object.keys(ModelUsageService.claudeProfile).length > 0
        || Object.keys(ModelUsageService.claudeLiveRateLimit).length > 0
        || ModelUsageService.claudeUsageWindows.reason !== undefined
      )
      implicitHeight: rateLimitCol.implicitHeight + Appearance.spacingL * 2

      ColumnLayout {
        id: rateLimitCol
        anchors.fill: parent
        anchors.margins: Appearance.spacingL
        spacing: Appearance.spacingS

        Text {
          text: "Claude Limits"
          color: Colors.text
          font.pixelSize: Appearance.fontSizeMedium
          font.weight: Font.Bold
        }

        Text {
          text: "Subscription and rolling limit windows reported by Claude."
          color: Colors.textSecondary
          font.pixelSize: Appearance.fontSizeXS
          Layout.fillWidth: true
          wrapMode: Text.WordWrap
        }

        SharedWidgets.InfoRow {
          visible: !!(
            ModelUsageService.claudeUsageWindows.available
            && ModelUsageService.claudeUsageWindows.fiveHour
            && ModelUsageService.claudeUsageWindows.fiveHour.utilization !== undefined
            && ModelUsageService.claudeUsageWindows.fiveHour.utilization !== null
          )
          label: "5h Session"
          value: {
            var fiveHour = ModelUsageService.claudeUsageWindows.fiveHour;
            if (!fiveHour || fiveHour.utilization === undefined || fiveHour.utilization === null)
              return "";
            return Math.floor(Number(fiveHour.utilization || 0))
              + "% used · resets in "
              + ModelUsageService.formatUnixResetTime(Number(fiveHour.resets_at || 0));
          }
          valueColor: root.providerAccent
        }

        SharedWidgets.InfoRow {
          visible: !!(
            !ModelUsageService.claudeUsageWindows.available
            && (ModelUsageService.claudeLiveRateLimit.rateLimitType || "") === "five_hour"
          )
          label: "5h Session"
          value: String(ModelUsageService.claudeLiveRateLimit.status || "unknown")
            + ((ModelUsageService.claudeLiveRateLimit.resetsAt || 0) > 0
              ? " · resets in " + ModelUsageService.formatUnixResetTime(Number(ModelUsageService.claudeLiveRateLimit.resetsAt || 0))
              : "")
          valueColor: root.providerAccent
        }

        SharedWidgets.InfoRow {
          visible: !!(
            ModelUsageService.claudeUsageWindows.available
            && ModelUsageService.claudeUsageWindows.sevenDay
            && ModelUsageService.claudeUsageWindows.sevenDay.utilization !== undefined
            && ModelUsageService.claudeUsageWindows.sevenDay.utilization !== null
          )
          label: "Weekly"
          value: {
            var weekly = ModelUsageService.claudeUsageWindows.sevenDay;
            if (!weekly || weekly.utilization === undefined || weekly.utilization === null)
              return "";
            return Math.floor(Number(weekly.utilization || 0))
              + "% used · resets in "
              + ModelUsageService.formatUnixResetTime(Number(weekly.resets_at || 0));
          }
          valueColor: root.providerAccent
        }

        SharedWidgets.InfoRow {
          visible: !!(
            ModelUsageService.claudeUsageWindows.available
            && ModelUsageService.claudeUsageWindows.sevenDaySonnet
            && ModelUsageService.claudeUsageWindows.sevenDaySonnet.utilization !== undefined
            && ModelUsageService.claudeUsageWindows.sevenDaySonnet.utilization !== null
          )
          label: "Sonnet Weekly"
          value: {
            var sonnetWeekly = ModelUsageService.claudeUsageWindows.sevenDaySonnet;
            if (!sonnetWeekly || sonnetWeekly.utilization === undefined || sonnetWeekly.utilization === null)
              return "";
            return Math.floor(Number(sonnetWeekly.utilization || 0))
              + "% used · resets in "
              + ModelUsageService.formatUnixResetTime(Number(sonnetWeekly.resets_at || 0));
          }
          valueColor: root.providerAccent
        }

        Text {
          visible: !!(
            !ModelUsageService.claudeUsageWindows.available
            && (ModelUsageService.claudeUsageWindows.reason || "") !== ""
          )
          text: {
            if ((ModelUsageService.claudeUsageWindows.reason || "") === "rate_limited") {
              var retry = Number(ModelUsageService.claudeUsageWindows.retryAfterSeconds || 0);
              return "Weekly usage unavailable: Anthropic usage API is rate limited"
                + (retry > 0 ? " · retry in " + ModelUsageService.formatDurationSeconds(retry) : "");
            }
            return "Weekly usage unavailable";
          }
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          wrapMode: Text.WordWrap
          Layout.fillWidth: true
        }

        SharedWidgets.CollapsibleSection {
          Layout.fillWidth: true
          expanded: false
          visible: !!(
            (ModelUsageService.claudeProfile.subscriptionType || "") !== ""
            || (ModelUsageService.claudeProfile.rateLimitTier || "") !== ""
            || (ModelUsageService.claudeProfile.billingType || "") !== ""
            || typeof ModelUsageService.claudeProfile.hasExtraUsageEnabled !== "undefined"
          )
          title: "Account Details"
          subtitle: "Expand to inspect Claude subscription and billing metadata."

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SharedWidgets.InfoRow {
              visible: !!((ModelUsageService.claudeProfile.subscriptionType || "") !== "")
              label: "Plan"
              value: String(ModelUsageService.claudeProfile.subscriptionType || "").toUpperCase()
            }

            SharedWidgets.InfoRow {
              visible: !!((ModelUsageService.claudeProfile.rateLimitTier || "") !== "")
              label: "Tier"
              value: ModelUsageService.claudeProfile.rateLimitTier || ""
            }

            SharedWidgets.InfoRow {
              visible: !!((ModelUsageService.claudeProfile.billingType || "") !== "")
              label: "Billing"
              value: ModelUsageService.claudeProfile.billingType || ""
            }

            SharedWidgets.InfoRow {
              visible: typeof ModelUsageService.claudeProfile.hasExtraUsageEnabled !== "undefined"
              label: "Extra Usage"
              value: ModelUsageService.claudeProfile.hasExtraUsageEnabled ? "Enabled" : "Disabled"
            }
          }
        }
      }
    }

    // ── Today Details Section ────────────────────────
    SharedWidgets.ThemedContainer {
      variant: "card"
      Layout.fillWidth: true
      visible: ModelUsageService.isReady
      implicitHeight: todayCol.implicitHeight + Appearance.spacingL * 2

      ColumnLayout {
        id: todayCol
        anchors.fill: parent
        anchors.margins: Appearance.spacingL
        spacing: Appearance.spacingS

        Text {
          text: "Today"
          color: Colors.text
          font.pixelSize: Appearance.fontSizeMedium
          font.weight: Font.Bold
        }

        Text {
          text: root.showClaude
            ? "Session activity and model usage for the current day."
            : root.showGemini
              ? "Today's Gemini prompt and token breakdown."
              : "Today's Codex activity snapshot."
          color: Colors.textSecondary
          font.pixelSize: Appearance.fontSizeXS
          Layout.fillWidth: true
          wrapMode: Text.WordWrap
        }

        SharedWidgets.InfoRow {
          visible: (root.showClaude || root.showGemini)
                   && (root.showClaude ? ModelUsageService.claudeTodaySessions : ModelUsageService.geminiTodaySessions) > 0
          label: "Sessions"
          value: root.showClaude ? String(ModelUsageService.claudeTodaySessions)
                                 : String(ModelUsageService.geminiTodaySessions)
        }

        SharedWidgets.InfoRow {
          visible: root.showClaude && ModelUsageService.claudeTodayToolCalls > 0
          label: "Tool Calls"
          value: String(ModelUsageService.claudeTodayToolCalls)
        }

        SharedWidgets.InfoRow {
          visible: root.showGemini && (ModelUsageService.geminiTodayTokens.input || 0) > 0
          label: "Input Tokens"
          value: ModelUsageService.formatTokenCount(ModelUsageService.geminiTodayTokens.input || 0)
          valueColor: root.providerAccent
        }
        SharedWidgets.InfoRow {
          visible: root.showGemini && (ModelUsageService.geminiTodayTokens.output || 0) > 0
          label: "Output Tokens"
          value: ModelUsageService.formatTokenCount(ModelUsageService.geminiTodayTokens.output || 0)
          valueColor: root.providerAccent
        }

        SharedWidgets.CollapsibleSection {
          Layout.fillWidth: true
          expanded: false
          visible: root.showClaude && Object.keys(ModelUsageService.claudeTodayTokensByModel).length > 0
          title: "Claude Token Breakdown"
          subtitle: "Expand to inspect today's token usage by Claude model."

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            Repeater {
              model: {
                var tokens = ModelUsageService.claudeTodayTokensByModel;
                var items = [];
                for (var k in tokens) {
                  if (tokens.hasOwnProperty(k))
                    items.push({ model: k, count: tokens[k] });
                }
                return items;
              }

              SharedWidgets.InfoRow {
                required property var modelData
                label: ModelUsageService.friendlyModelName(modelData.model)
                value: ModelUsageService.formatTokenCount(modelData.count) + " tokens"
                valueColor: root.providerAccent
              }
            }
          }
        }

        SharedWidgets.CollapsibleSection {
          Layout.fillWidth: true
          expanded: false
          visible: root.showGemini && (
            (ModelUsageService.geminiTodayTokens.cached || 0) > 0
            || (ModelUsageService.geminiTodayTokens.thoughts || 0) > 0
          )
          title: "Gemini Token Details"
          subtitle: "Expand to inspect cached and thinking token usage."

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SharedWidgets.InfoRow {
              visible: (ModelUsageService.geminiTodayTokens.cached || 0) > 0
              label: "Cached Tokens"
              value: ModelUsageService.formatTokenCount(ModelUsageService.geminiTodayTokens.cached || 0)
            }

            SharedWidgets.InfoRow {
              visible: (ModelUsageService.geminiTodayTokens.thoughts || 0) > 0
              label: "Thinking Tokens"
              value: ModelUsageService.formatTokenCount(ModelUsageService.geminiTodayTokens.thoughts || 0)
            }
          }
        }
      }
    }

    // ── Last 7 Days Chart ────────────────────────────
    SharedWidgets.ThemedContainer {
      variant: "card"
      Layout.fillWidth: true
      visible: (root.showClaude && ModelUsageService.claudeRecentDays.length > 0)
              || (root.showGemini && ModelUsageService.geminiRecentDays.length > 0)
              || (root.showCodex && ModelUsageService.codexRecentDays.length > 0)
      implicitHeight: chartCol.implicitHeight + Appearance.spacingL * 2

      ColumnLayout {
        id: chartCol
        anchors.fill: parent
        anchors.margins: Appearance.spacingL
        spacing: Appearance.spacingS

        Text {
          text: "Last 7 Days"
          color: Colors.text
          font.pixelSize: Appearance.fontSizeMedium
          font.weight: Font.Bold
        }

        Text {
          text: String(root.recentPromptTotal(
            root.showGemini ? ModelUsageService.geminiRecentDays
            : root.showCodex ? ModelUsageService.codexRecentDays
            : ModelUsageService.claudeRecentDays
          )) + " prompts in the current 7-day window"
          color: Colors.textSecondary
          font.pixelSize: Appearance.fontSizeXS
          Layout.fillWidth: true
          wrapMode: Text.WordWrap
        }

        Repeater {
          model: root.showGemini ? ModelUsageService.geminiRecentDays
                                 : root.showCodex ? ModelUsageService.codexRecentDays
                                 : ModelUsageService.claudeRecentDays

          RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS
            required property var modelData
            required property int index

            readonly property int maxCount: {
              var days = root.showGemini ? ModelUsageService.geminiRecentDays
                                         : root.showCodex ? ModelUsageService.codexRecentDays
                                         : ModelUsageService.claudeRecentDays;
              var m = 1;
              for (var i = 0; i < days.length; i++)
                if (days[i].messageCount > m) m = days[i].messageCount;
              return m;
            }

            readonly property bool isToday: {
              var now = new Date();
              var todayStr = now.getFullYear() + "-"
                + String(now.getMonth() + 1).padStart(2, "0") + "-"
                + String(now.getDate()).padStart(2, "0");
              return modelData.date === todayStr;
            }

            Text {
              text: {
                if (isToday) return "Today";
                var parts = modelData.date.split("-");
                return parts.length >= 3 ? parts[1] + "/" + parts[2] : modelData.date;
              }
              color: isToday ? root.providerAccent : Colors.textSecondary
              font.pixelSize: Appearance.fontSizeXS
              font.weight: isToday ? Font.DemiBold : Font.Normal
              Layout.preferredWidth: 40
            }

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 16
              radius: Appearance.radiusXS3
              color: Colors.withAlpha(Colors.text, Colors.primaryFaint)

              Rectangle {
                width: parent.width * Math.min(1, modelData.messageCount / maxCount)
                height: parent.height
                radius: parent.radius
                color: root.providerAccent
                opacity: isToday ? 1.0 : (0.5 + 0.5 * (modelData.messageCount / maxCount))

                Behavior on width { NumberAnimation { duration: Appearance.durationMedium } }
                Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationNormal } }
              }
            }

            Text {
              text: String(modelData.messageCount)
              color: isToday ? root.providerAccent : Colors.text
              font.pixelSize: Appearance.fontSizeXS
              font.weight: Font.DemiBold
              Layout.preferredWidth: 36
              horizontalAlignment: Text.AlignRight
            }
          }
        }
      }
    }

    SharedWidgets.ThemedContainer {
      variant: "card"
      Layout.fillWidth: true
      visible: root.showGemini && ModelUsageService.geminiReady
      implicitHeight: gemini24hCol.implicitHeight + Appearance.spacingL * 2

      ColumnLayout {
        id: gemini24hCol
        anchors.fill: parent
        anchors.margins: Appearance.spacingL
        spacing: Appearance.spacingS

        Text {
          text: "Last 24 Hours"
          color: Colors.text
          font.pixelSize: Appearance.fontSizeMedium
          font.weight: Font.Bold
        }

        Text {
          text: "Recent Gemini model activity across the rolling 24-hour window."
          color: Colors.textSecondary
          font.pixelSize: Appearance.fontSizeXS
          Layout.fillWidth: true
          wrapMode: Text.WordWrap
        }

        SharedWidgets.InfoRow {
          label: "Prompts"
          value: String(ModelUsageService.geminiLast24hPrompts)
        }

        SharedWidgets.InfoRow {
          label: "Sessions"
          value: String(ModelUsageService.geminiLast24hSessions)
        }

        SharedWidgets.CollapsibleSection {
          Layout.fillWidth: true
          expanded: false
          title: "By Model"
          subtitle: "Expand to inspect 24-hour token distribution by Gemini model."

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            Repeater {
              model: {
                var usage = ModelUsageService.geminiLast24hTokensByModel;
                var items = [];
                for (var k in usage) {
                  if (usage.hasOwnProperty(k))
                    items.push({
                      model: k,
                      input: usage[k].input || 0,
                      output: usage[k].output || 0,
                      cached: usage[k].cached || 0,
                      thoughts: usage[k].thoughts || 0,
                      total: usage[k].total || 0
                    });
                }
                items.sort(function(a, b) { return b.total - a.total; });
                return items;
              }

              Rectangle {
                Layout.fillWidth: true
                radius: Appearance.radiusMedium
                color: Colors.withAlpha(Colors.surface, Colors.opacitySurface)
                border.color: Colors.border
                border.width: 1
                implicitHeight: gemini24hModelCol.implicitHeight + Appearance.spacingM * 2
                required property var modelData

                ColumnLayout {
                  id: gemini24hModelCol
                  anchors.fill: parent
                  anchors.margins: Appearance.spacingM
                  spacing: Appearance.spacingXXS

                  Text {
                    text: modelData.model
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: Font.DemiBold
                  }

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingM

                    Text {
                      text: "In: " + ModelUsageService.formatTokenCount(modelData.input)
                      color: Colors.textSecondary
                      font.pixelSize: Appearance.fontSizeXS
                    }
                    Text {
                      text: "Out: " + ModelUsageService.formatTokenCount(modelData.output)
                      color: Colors.textSecondary
                      font.pixelSize: Appearance.fontSizeXS
                    }
                    Text {
                      visible: modelData.cached > 0
                      text: "Cache: " + ModelUsageService.formatTokenCount(modelData.cached)
                      color: Colors.textDisabled
                      font.pixelSize: Appearance.fontSizeXS
                    }
                    Text {
                      visible: modelData.thoughts > 0
                      text: "Think: " + ModelUsageService.formatTokenCount(modelData.thoughts)
                      color: Colors.textDisabled
                      font.pixelSize: Appearance.fontSizeXS
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    // ── All-Time Model Breakdown (Claude) ────────────
    SharedWidgets.ThemedContainer {
      variant: "card"
      Layout.fillWidth: true
      visible: root.showClaude && Object.keys(ModelUsageService.claudeModelUsage).length > 0
      implicitHeight: allTimeCol.implicitHeight + Appearance.spacingL * 2

      ColumnLayout {
        id: allTimeCol
        anchors.fill: parent
        anchors.margins: Appearance.spacingL
        spacing: Appearance.spacingS

        SharedWidgets.CollapsibleSection {
          Layout.fillWidth: true
          expanded: false
          title: "All-Time Stats"
          subtitle: "Longer-running Claude usage totals with per-model distribution."

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SharedWidgets.InfoRow {
              label: "Total Prompts"
              value: ModelUsageService.formatTokenCount(ModelUsageService.claudeTotalPrompts)
            }

            SharedWidgets.InfoRow {
              label: "Total Sessions"
              value: String(ModelUsageService.claudeTotalSessions)
            }

            SharedWidgets.InfoRow {
              label: "Total Tokens"
              value: ModelUsageService.formatTokenCount(ModelUsageService.claudeTotalTokens)
              valueColor: root.providerAccent
            }

            SharedWidgets.InfoRow {
              visible: ModelUsageService.claudeFirstSessionDate !== ""
              label: "First Session"
              value: ModelUsageService.claudeFirstSessionDate
            }

            SharedWidgets.CollapsibleSection {
              Layout.fillWidth: true
              expanded: false
              title: "Per-Model Breakdown"
              subtitle: "Expand to compare cumulative Claude model totals."

              ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingS

                Repeater {
                  model: {
                    var usage = ModelUsageService.claudeModelUsage;
                    var items = [];
                    for (var k in usage) {
                      if (usage.hasOwnProperty(k)) {
                        var u = usage[k];
                        items.push({
                          model: k,
                          input: u.inputTokens || 0,
                          output: u.outputTokens || 0,
                          cacheRead: u.cacheReadInputTokens || 0,
                          cacheCreation: u.cacheCreationInputTokens || 0
                        });
                      }
                    }
                    items.sort(function(a, b) {
                      return (b.input + b.output + b.cacheRead) - (a.input + a.output + a.cacheRead);
                    });
                    return items;
                  }

                  Rectangle {
                    Layout.fillWidth: true
                    radius: Appearance.radiusMedium
                    color: Colors.withAlpha(Colors.surface, Colors.opacitySurface)
                    border.color: Colors.border
                    border.width: 1
                    implicitHeight: claudeModelCol.implicitHeight + Appearance.spacingM * 2
                    required property var modelData

                    ColumnLayout {
                      id: claudeModelCol
                      anchors.fill: parent
                      anchors.margins: Appearance.spacingM
                      spacing: Appearance.spacingXXS

                      Text {
                        text: ModelUsageService.friendlyModelName(modelData.model)
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeSmall
                        font.weight: Font.DemiBold
                      }

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacingM
                        Text {
                          text: "In: " + ModelUsageService.formatTokenCount(modelData.input)
                          color: Colors.textSecondary
                          font.pixelSize: Appearance.fontSizeXS
                        }
                        Text {
                          text: "Out: " + ModelUsageService.formatTokenCount(modelData.output)
                          color: Colors.textSecondary
                          font.pixelSize: Appearance.fontSizeXS
                        }
                        Text {
                          visible: modelData.cacheRead > 0
                          text: "Cache: " + ModelUsageService.formatTokenCount(modelData.cacheRead)
                          color: Colors.textDisabled
                          font.pixelSize: Appearance.fontSizeXS
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

    // ── Gemini All-Time Stats ────────────────────────
    SharedWidgets.ThemedContainer {
      variant: "card"
      Layout.fillWidth: true
      visible: root.showGemini && ModelUsageService.geminiReady
      implicitHeight: geminiAllTimeCol.implicitHeight + Appearance.spacingL * 2

      ColumnLayout {
        id: geminiAllTimeCol
        anchors.fill: parent
        anchors.margins: Appearance.spacingL
        spacing: Appearance.spacingS

        SharedWidgets.CollapsibleSection {
          Layout.fillWidth: true
          expanded: false
          title: "All-Time Stats"
          subtitle: "Gemini totals and primary-model distribution across stored sessions."

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SharedWidgets.InfoRow {
              label: "Total Sessions"
              value: String(ModelUsageService.geminiTotalSessions)
            }

            SharedWidgets.InfoRow {
              label: "Total Tokens"
              value: ModelUsageService.formatTokenCount(ModelUsageService.geminiTotalTokens)
              valueColor: root.providerAccent
            }

            SharedWidgets.InfoRow {
              label: "Primary Model"
              value: ModelUsageService.geminiModel
            }

            SharedWidgets.CollapsibleSection {
              Layout.fillWidth: true
              expanded: false
              visible: Object.keys(ModelUsageService.geminiTokensByModel).length > 1
              title: "Per-Model Breakdown"
              subtitle: "Expand to compare cumulative Gemini model totals."

              ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingS

                Repeater {
                  model: {
                    var usage = ModelUsageService.geminiTokensByModel;
                    var items = [];
                    for (var k in usage) {
                      if (usage.hasOwnProperty(k))
                        items.push({ model: k, input: usage[k].input || 0, output: usage[k].output || 0 });
                    }
                    items.sort(function(a, b) { return (b.input + b.output) - (a.input + a.output); });
                    return items;
                  }

                  Rectangle {
                    Layout.fillWidth: true
                    radius: Appearance.radiusMedium
                    color: Colors.withAlpha(Colors.surface, Colors.opacitySurface)
                    border.color: Colors.border
                    border.width: 1
                    implicitHeight: geminiModelCol.implicitHeight + Appearance.spacingM * 2
                    required property var modelData

                    ColumnLayout {
                      id: geminiModelCol
                      anchors.fill: parent
                      anchors.margins: Appearance.spacingM
                      spacing: Appearance.spacingXXS

                      Text {
                        text: modelData.model
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeSmall
                        font.weight: Font.DemiBold
                      }

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacingM
                        Text {
                          text: "In: " + ModelUsageService.formatTokenCount(modelData.input)
                          color: Colors.textSecondary
                          font.pixelSize: Appearance.fontSizeXS
                        }
                        Text {
                          text: "Out: " + ModelUsageService.formatTokenCount(modelData.output)
                          color: Colors.textSecondary
                          font.pixelSize: Appearance.fontSizeXS
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

    // ── Codex Info Section ───────────────────────────
    SharedWidgets.ThemedContainer {
      variant: "card"
      Layout.fillWidth: true
      visible: root.showCodex && ModelUsageService.codexReady
      implicitHeight: codexCol.implicitHeight + Appearance.spacingL * 2

      ColumnLayout {
        id: codexCol
        anchors.fill: parent
        anchors.margins: Appearance.spacingL
        spacing: Appearance.spacingS

        Text {
          text: "Codex CLI"
          color: Colors.text
          font.pixelSize: Appearance.fontSizeMedium
          font.weight: Font.Bold
        }

        Text {
          text: "Latest Codex session, current session totals, and any reported rate windows."
          color: Colors.textSecondary
          font.pixelSize: Appearance.fontSizeXS
          Layout.fillWidth: true
          wrapMode: Text.WordWrap
        }

        SharedWidgets.InfoRow {
          visible: !!((ModelUsageService.codexRateLimits.planType || "") !== "")
          label: "Plan"
          value: ModelUsageService.codexRateLimits.planType || ""
        }

        SharedWidgets.InfoRow {
          label: "Model"
          value: ModelUsageService.codexModel
        }

        SharedWidgets.InfoRow {
          visible: (ModelUsageService.codexLatestSession.totalTokens || 0) > 0
          label: "Last Session Total"
          value: ModelUsageService.formatTokenCount(ModelUsageService.codexLatestSession.totalTokens || 0)
          valueColor: root.providerAccent
        }

        SharedWidgets.CollapsibleSection {
          Layout.fillWidth: true
          expanded: false
          visible: !!(
            (ModelUsageService.codexLatestSession.inputTokens || 0) > 0
            || (ModelUsageService.codexLatestSession.outputTokens || 0) > 0
            || (ModelUsageService.codexLatestSession.cachedInputTokens || 0) > 0
            || (ModelUsageService.codexLatestSession.reasoningTokens || 0) > 0
          )
          title: "Latest Session Breakdown"
          subtitle: "Expand to inspect the latest Codex session token mix."

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SharedWidgets.InfoRow {
              visible: (ModelUsageService.codexLatestSession.inputTokens || 0) > 0
              label: "Input Tokens"
              value: ModelUsageService.formatTokenCount(ModelUsageService.codexLatestSession.inputTokens || 0)
            }

            SharedWidgets.InfoRow {
              visible: (ModelUsageService.codexLatestSession.outputTokens || 0) > 0
              label: "Output Tokens"
              value: ModelUsageService.formatTokenCount(ModelUsageService.codexLatestSession.outputTokens || 0)
            }

            SharedWidgets.InfoRow {
              visible: (ModelUsageService.codexLatestSession.cachedInputTokens || 0) > 0
              label: "Cached Tokens"
              value: ModelUsageService.formatTokenCount(ModelUsageService.codexLatestSession.cachedInputTokens || 0)
            }

            SharedWidgets.InfoRow {
              visible: (ModelUsageService.codexLatestSession.reasoningTokens || 0) > 0
              label: "Reasoning Tokens"
              value: ModelUsageService.formatTokenCount(ModelUsageService.codexLatestSession.reasoningTokens || 0)
            }
          }
        }

        SharedWidgets.CollapsibleSection {
          Layout.fillWidth: true
          expanded: false
          visible: (ModelUsageService.codexTotalUsage.totalTokens || 0) > 0
          title: "Current Session Usage"
          subtitle: "Expand to inspect the running Codex session totals."

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SharedWidgets.InfoRow {
              visible: (ModelUsageService.codexTotalUsage.inputTokens || 0) > 0
              label: "Input Tokens"
              value: ModelUsageService.formatTokenCount(ModelUsageService.codexTotalUsage.inputTokens || 0)
            }

            SharedWidgets.InfoRow {
              visible: (ModelUsageService.codexTotalUsage.cachedInputTokens || 0) > 0
              label: "Cached Tokens"
              value: ModelUsageService.formatTokenCount(ModelUsageService.codexTotalUsage.cachedInputTokens || 0)
            }

            SharedWidgets.InfoRow {
              visible: (ModelUsageService.codexTotalUsage.outputTokens || 0) > 0
              label: "Output Tokens"
              value: ModelUsageService.formatTokenCount(ModelUsageService.codexTotalUsage.outputTokens || 0)
            }

            SharedWidgets.InfoRow {
              visible: (ModelUsageService.codexTotalUsage.reasoningTokens || 0) > 0
              label: "Reasoning Tokens"
              value: ModelUsageService.formatTokenCount(ModelUsageService.codexTotalUsage.reasoningTokens || 0)
            }

            SharedWidgets.InfoRow {
              visible: (ModelUsageService.codexTotalUsage.totalTokens || 0) > 0
              label: "Total Tokens"
              value: ModelUsageService.formatTokenCount(ModelUsageService.codexTotalUsage.totalTokens || 0)
              valueColor: root.providerAccent
            }
          }
        }

        SharedWidgets.CollapsibleSection {
          Layout.fillWidth: true
          expanded: false
          visible: !!(
            (ModelUsageService.codexRateLimits.primary && ModelUsageService.codexRateLimits.primary.available)
            || (ModelUsageService.codexRateLimits.secondary && ModelUsageService.codexRateLimits.secondary.available)
          )
          title: "Usage Limits"
          subtitle: "Expand to inspect current Codex rate windows."

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SharedWidgets.InfoRow {
              visible: !!(ModelUsageService.codexRateLimits.primary && ModelUsageService.codexRateLimits.primary.available)
              label: {
                var primary = ModelUsageService.codexRateLimits.primary;
                return primary ? ModelUsageService.usageWindowLabel(primary.windowMinutes || 0) : "";
              }
              value: {
                var primary = ModelUsageService.codexRateLimits.primary;
                if (!primary || primary.usedPercent === undefined || primary.usedPercent < 0)
                  return "";
                return primary.usedPercent.toFixed(1) + "% · resets in "
                  + ModelUsageService.formatUnixResetTime(primary.resetsAt || 0);
              }
              valueColor: root.providerAccent
            }

            SharedWidgets.InfoRow {
              visible: !!(ModelUsageService.codexRateLimits.secondary && ModelUsageService.codexRateLimits.secondary.available)
              label: {
                var secondary = ModelUsageService.codexRateLimits.secondary;
                return secondary ? ModelUsageService.usageWindowLabel(secondary.windowMinutes || 0) : "";
              }
              value: {
                var secondary = ModelUsageService.codexRateLimits.secondary;
                if (!secondary || secondary.usedPercent === undefined || secondary.usedPercent < 0)
                  return "";
                return secondary.usedPercent.toFixed(1) + "% · resets in "
                  + ModelUsageService.formatUnixResetTime(secondary.resetsAt || 0);
              }
              valueColor: root.providerAccent
            }
          }
        }
      }
    }

    // ── Empty state ─────────────────────────────────
    SharedWidgets.EmptyState {
      Layout.fillWidth: true
      visible: ModelUsageService.hasEnabledProviders && !ModelUsageService.isReady
      icon: ModelUsageService.providerIcon
      message: root.providerEmptyMessage()
    }
  }
}
