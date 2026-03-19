import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../shared"
import "../../services"
import "../../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMinWidth: 340; popupMaxWidth: 420; compactThreshold: 380
  implicitHeight: Math.min(660, contentCol.implicitHeight + 100)
  title: "Model Usage"
  subtitle: ModelUsageService.activeProvider === "claude" ? "Claude Code"
         : ModelUsageService.activeProvider === "gemini" ? "Gemini CLI" : "Codex CLI"

  // Provider-specific surface tint (like MusicMenu album accent)
  surfaceTint: Colors.withAlpha(root.providerAccent, 0.06)

  SharedWidgets.Ref { service: ModelUsageService }

  // ── Provider state ───────────────────────────────
  readonly property bool showClaude: ModelUsageService.activeProvider === "claude"
  readonly property bool showCodex: ModelUsageService.activeProvider === "codex"
  readonly property bool showGemini: ModelUsageService.activeProvider === "gemini"
  readonly property int enabledCount: (ModelUsageService.claudeEnabled ? 1 : 0)
    + (ModelUsageService.codexEnabled ? 1 : 0)
    + (ModelUsageService.geminiEnabled ? 1 : 0)
  readonly property bool showProviderTabs: enabledCount > 1

  // Provider accent — flows through hero, charts, token values
  property color providerAccent: ModelUsageService.providerColor
  Behavior on providerAccent { ColorAnimation { duration: Colors.durationNormal } }

  // ── Provider tabs ──────────────────────────────────
  headerExtras: [
    Row {
      visible: root.showProviderTabs
      spacing: Colors.spacingXS

      Repeater {
        model: {
          var tabs = [];
          if (ModelUsageService.claudeEnabled) tabs.push({ key: "claude", label: "Claude", icon: "󱜚" });
          if (ModelUsageService.codexEnabled) tabs.push({ key: "codex", label: "Codex", icon: "" });
          if (ModelUsageService.geminiEnabled) tabs.push({ key: "gemini", label: "Gemini", icon: "󰫢" });
          return tabs;
        }
        delegate: SharedWidgets.FilterChip {
          required property var modelData
          label: modelData.label
          icon: modelData.icon
          selected: ModelUsageService.activeProvider === modelData.key
          onClicked: Config.modelUsageActiveProvider = modelData.key
        }
      }
    },
    SharedWidgets.IconButton {
      icon: "󰒓"
      size: 28
      iconSize: Colors.fontSizeLarge
      tooltipText: "Settings"
      onClicked: {
        Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "openTab", "model-usage"]);
        root.closeRequested();
      }
    }
  ]

  // ── Content cross-fade on provider switch ────
  property string _prevProvider: ModelUsageService.activeProvider
  onProviderAccentChanged: {
    if (_prevProvider !== ModelUsageService.activeProvider) {
      _prevProvider = ModelUsageService.activeProvider;
      contentFade.restart();
    }
  }

  SequentialAnimation {
    id: contentFade
    NumberAnimation { target: scrollContent; property: "opacity"; to: 0; duration: 80; easing.type: Easing.OutQuad }
    NumberAnimation { target: scrollContent; property: "opacity"; to: 1; duration: 160; easing.type: Easing.InOutQuad }
  }

  SharedWidgets.ScrollableContent {
    id: scrollContent
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Colors.spacingM
    layer.enabled: contentFade.running

    // ── Hero Summary Card ───────────────────────────
    Rectangle {
      Layout.fillWidth: true
      visible: ModelUsageService.isReady
      implicitHeight: heroRow.implicitHeight + Colors.spacingLG * 2
      radius: Colors.radiusCard
      color: Colors.withAlpha(root.providerAccent, Colors.primaryFaint)
      border.color: Colors.withAlpha(root.providerAccent, 0.18)
      border.width: 1

      Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Colors.durationNormal } }
      Behavior on border.color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Colors.durationNormal } }

      SharedWidgets.InnerHighlight { }

      RowLayout {
        id: heroRow
        anchors.fill: parent
        anchors.margins: Colors.spacingLG
        spacing: Colors.spacingL

        // Large provider icon
        Rectangle {
          Layout.preferredWidth: 52
          Layout.preferredHeight: 52
          radius: Colors.radiusCard
          color: Colors.withAlpha(root.providerAccent, Colors.primarySubtle)
          Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Colors.durationNormal } }

          Text {
            anchors.centerIn: parent
            text: ModelUsageService.providerIcon
            color: root.providerAccent
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeHuge
            Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Colors.durationNormal } }
          }
        }

        // Big metric
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2

          Text {
            text: String(ModelUsageService.todayPrompts)
            color: Colors.text
            font.pixelSize: Colors.fontSizeDisplay
            font.weight: Font.Bold
            font.letterSpacing: Colors.letterSpacingTight
          }

          Text {
            text: "prompts today"
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeSmall
          }
        }

        // Model badge
        Rectangle {
          visible: {
            if (root.showClaude) return Object.keys(ModelUsageService.claudeTodayTokensByModel).length > 0;
            if (root.showGemini) return ModelUsageService.geminiModel !== "unknown";
            return ModelUsageService.codexModel !== "unknown";
          }
          Layout.alignment: Qt.AlignTop
          implicitWidth: modelBadgeText.implicitWidth + Colors.spacingM * 2
          implicitHeight: modelBadgeText.implicitHeight + Colors.spacingSM * 2
          radius: height / 2
          color: Colors.withAlpha(root.providerAccent, Colors.primaryGhost)
          Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Colors.durationNormal } }

          Text {
            id: modelBadgeText
            anchors.centerIn: parent
            text: {
              if (root.showClaude) {
                var keys = Object.keys(ModelUsageService.claudeTodayTokensByModel);
                return keys.length > 0 ? ModelUsageService.friendlyModelName(keys[0]) : "";
              }
              if (root.showGemini) return ModelUsageService.geminiModel;
              return ModelUsageService.codexModel;
            }
            color: root.providerAccent
            font.pixelSize: Colors.fontSizeXS
            font.weight: Font.DemiBold
            Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Colors.durationNormal } }
          }
        }
      }
    }

    // ── Rate Limit Section (Claude only) ─────────────
    Rectangle {
      Layout.fillWidth: true
      visible: root.showClaude && ModelUsageService.claudeRateLimitAvailable
      implicitHeight: rateLimitCol.implicitHeight + Colors.spacingL * 2
      radius: Colors.radiusCard
      color: Colors.cardSurface
      border.color: Colors.border
      border.width: 1

      SharedWidgets.InnerHighlight { }

      ColumnLayout {
        id: rateLimitCol
        anchors.fill: parent
        anchors.margins: Colors.spacingL
        spacing: Colors.spacingS

        Text {
          text: "Rate Limit"
          color: Colors.text
          font.pixelSize: Colors.fontSizeMedium
          font.weight: Font.Bold
        }

        // Progress bar
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 8
          radius: 4
          color: Colors.withAlpha(Colors.text, Colors.primaryFaint)

          Rectangle {
            width: parent.width * Math.min(1, Math.max(0, ModelUsageService.claudeRateLimitPercent / 100))
            height: parent.height
            radius: parent.radius
            color: ModelUsageService.claudeRateLimitPercent >= 90 ? Colors.error
                 : ModelUsageService.claudeRateLimitPercent >= 70 ? Colors.warning
                 : root.providerAccent

            Behavior on width { NumberAnimation { duration: Colors.durationMedium } }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Text {
            text: ModelUsageService.claudeRateLimitLabel
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeSmall
          }
          Item { Layout.fillWidth: true }
          Text {
            text: ModelUsageService.claudeRateLimitPercent >= 0
              ? ModelUsageService.claudeRateLimitPercent.toFixed(1) + "%"
              : ""
            color: ModelUsageService.claudeRateLimitPercent >= 90 ? Colors.error
                 : ModelUsageService.claudeRateLimitPercent >= 70 ? Colors.warning
                 : Colors.textSecondary
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.DemiBold
          }
        }

        Text {
          visible: ModelUsageService.claudeRateLimitResetAt !== ""
          text: "Resets in " + ModelUsageService.formatResetTime(ModelUsageService.claudeRateLimitResetAt)
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS
        }
      }
    }

    // ── Today Details Section ────────────────────────
    Rectangle {
      Layout.fillWidth: true
      visible: ModelUsageService.isReady
      implicitHeight: todayCol.implicitHeight + Colors.spacingL * 2
      radius: Colors.radiusCard
      color: Colors.cardSurface
      border.color: Colors.border
      border.width: 1

      SharedWidgets.InnerHighlight { }

      ColumnLayout {
        id: todayCol
        anchors.fill: parent
        anchors.margins: Colors.spacingL
        spacing: Colors.spacingS

        Text {
          text: "Today"
          color: Colors.text
          font.pixelSize: Colors.fontSizeMedium
          font.weight: Font.Bold
        }

        SharedWidgets.InfoRow {
          visible: (root.showClaude || root.showGemini)
                   && (root.showClaude ? ModelUsageService.claudeTodaySessions : ModelUsageService.geminiTodaySessions) > 0
          label: "Sessions"
          value: root.showClaude ? String(ModelUsageService.claudeTodaySessions)
                                 : String(ModelUsageService.geminiTodaySessions)
        }

        SharedWidgets.InfoRow {
          visible: root.showClaude
          label: "Tool Calls"
          value: String(ModelUsageService.claudeTodayToolCalls)
        }

        // Today tokens by model (Claude)
        Repeater {
          model: {
            if (!root.showClaude) return [];
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

        // Today token breakdown (Gemini)
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
        SharedWidgets.InfoRow {
          visible: root.showGemini && (ModelUsageService.geminiTodayTokens.cached || 0) > 0
          label: "Cached Tokens"
          value: ModelUsageService.formatTokenCount(ModelUsageService.geminiTodayTokens.cached || 0)
        }
        SharedWidgets.InfoRow {
          visible: root.showGemini && (ModelUsageService.geminiTodayTokens.thoughts || 0) > 0
          label: "Thinking Tokens"
          value: ModelUsageService.formatTokenCount(ModelUsageService.geminiTodayTokens.thoughts || 0)
        }
      }
    }

    // ── Last 7 Days Chart ────────────────────────────
    Rectangle {
      Layout.fillWidth: true
      visible: (root.showClaude && ModelUsageService.claudeRecentDays.length > 0)
              || (root.showGemini && ModelUsageService.geminiRecentDays.length > 0)
              || (root.showCodex && ModelUsageService.codexRecentDays.length > 0)
      implicitHeight: chartCol.implicitHeight + Colors.spacingL * 2
      radius: Colors.radiusCard
      color: Colors.cardSurface
      border.color: Colors.border
      border.width: 1

      SharedWidgets.InnerHighlight { }

      ColumnLayout {
        id: chartCol
        anchors.fill: parent
        anchors.margins: Colors.spacingL
        spacing: Colors.spacingS

        Text {
          text: "Last 7 Days"
          color: Colors.text
          font.pixelSize: Colors.fontSizeMedium
          font.weight: Font.Bold
        }

        Repeater {
          model: root.showGemini ? ModelUsageService.geminiRecentDays
                               : root.showCodex ? ModelUsageService.codexRecentDays
                                 : ModelUsageService.claudeRecentDays

          RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS
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
              font.pixelSize: Colors.fontSizeXS
              font.weight: isToday ? Font.DemiBold : Font.Normal
              Layout.preferredWidth: 40
            }

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 14
              radius: 3
              color: Colors.withAlpha(Colors.text, Colors.primaryFaint)

              Rectangle {
                width: parent.width * Math.min(1, modelData.messageCount / maxCount)
                height: parent.height
                radius: parent.radius
                color: root.providerAccent
                opacity: isToday ? 1.0 : (0.5 + 0.5 * (modelData.messageCount / maxCount))

                Behavior on width { NumberAnimation { duration: Colors.durationMedium } }
                Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Colors.durationNormal } }
              }
            }

            Text {
              text: String(modelData.messageCount)
              color: isToday ? root.providerAccent : Colors.text
              font.pixelSize: Colors.fontSizeXS
              font.weight: Font.DemiBold
              Layout.preferredWidth: 36
              horizontalAlignment: Text.AlignRight
            }
          }
        }
      }
    }

    // ── All-Time Model Breakdown (Claude) ────────────
    Rectangle {
      Layout.fillWidth: true
      visible: root.showClaude && Object.keys(ModelUsageService.claudeModelUsage).length > 0
      implicitHeight: allTimeCol.implicitHeight + Colors.spacingL * 2
      radius: Colors.radiusCard
      color: Colors.cardSurface
      border.color: Colors.border
      border.width: 1

      SharedWidgets.InnerHighlight { }

      ColumnLayout {
        id: allTimeCol
        anchors.fill: parent
        anchors.margins: Colors.spacingL
        spacing: Colors.spacingS

        Text {
          text: "All-Time Stats"
          color: Colors.text
          font.pixelSize: Colors.fontSizeMedium
          font.weight: Font.Bold
        }

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

        // Per-model breakdown
        Item { implicitHeight: Colors.spacingXS; Layout.fillWidth: true }

        Text {
          text: "Per-Model Breakdown"
          color: Colors.textSecondary
          font.pixelSize: Colors.fontSizeSmall
          font.weight: Font.DemiBold
        }

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

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            required property var modelData

            Text {
              text: ModelUsageService.friendlyModelName(modelData.model)
              color: Colors.text
              font.pixelSize: Colors.fontSizeSmall
              font.weight: Font.DemiBold
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Colors.spacingM
              Text {
                text: "In: " + ModelUsageService.formatTokenCount(modelData.input)
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
              }
              Text {
                text: "Out: " + ModelUsageService.formatTokenCount(modelData.output)
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
              }
              Text {
                visible: modelData.cacheRead > 0
                text: "Cache: " + ModelUsageService.formatTokenCount(modelData.cacheRead)
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
              }
            }
          }
        }
      }
    }

    // ── Gemini All-Time Stats ────────────────────────
    Rectangle {
      Layout.fillWidth: true
      visible: root.showGemini && ModelUsageService.geminiReady
      implicitHeight: geminiAllTimeCol.implicitHeight + Colors.spacingL * 2
      radius: Colors.radiusCard
      color: Colors.cardSurface
      border.color: Colors.border
      border.width: 1

      SharedWidgets.InnerHighlight { }

      ColumnLayout {
        id: geminiAllTimeCol
        anchors.fill: parent
        anchors.margins: Colors.spacingL
        spacing: Colors.spacingS

        Text {
          text: "All-Time Stats"
          color: Colors.text
          font.pixelSize: Colors.fontSizeMedium
          font.weight: Font.Bold
        }

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

        // Per-model breakdown
        Item { implicitHeight: Colors.spacingXS; Layout.fillWidth: true }

        Text {
          visible: Object.keys(ModelUsageService.geminiTokensByModel).length > 1
          text: "Per-Model Breakdown"
          color: Colors.textSecondary
          font.pixelSize: Colors.fontSizeSmall
          font.weight: Font.DemiBold
        }

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

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            required property var modelData

            Text {
              text: modelData.model
              color: Colors.text
              font.pixelSize: Colors.fontSizeSmall
              font.weight: Font.DemiBold
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Colors.spacingM
              Text {
                text: "In: " + ModelUsageService.formatTokenCount(modelData.input)
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
              }
              Text {
                text: "Out: " + ModelUsageService.formatTokenCount(modelData.output)
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
              }
            }
          }
        }
      }
    }

    // ── Codex Info Section ───────────────────────────
    Rectangle {
      Layout.fillWidth: true
      visible: root.showCodex && ModelUsageService.codexReady
      implicitHeight: codexCol.implicitHeight + Colors.spacingL * 2
      radius: Colors.radiusCard
      color: Colors.cardSurface
      border.color: Colors.border
      border.width: 1

      SharedWidgets.InnerHighlight { }

      ColumnLayout {
        id: codexCol
        anchors.fill: parent
        anchors.margins: Colors.spacingL
        spacing: Colors.spacingS

        Text {
          text: "Codex CLI"
          color: Colors.text
          font.pixelSize: Colors.fontSizeMedium
          font.weight: Font.Bold
        }

        SharedWidgets.InfoRow {
          label: "Model"
          value: ModelUsageService.codexModel
        }

        SharedWidgets.InfoRow {
          visible: (ModelUsageService.codexLatestSession.inputTokens || 0) > 0
          label: "Last Session Input"
          value: ModelUsageService.formatTokenCount(ModelUsageService.codexLatestSession.inputTokens || 0)
        }

        SharedWidgets.InfoRow {
          visible: (ModelUsageService.codexLatestSession.outputTokens || 0) > 0
          label: "Last Session Output"
          value: ModelUsageService.formatTokenCount(ModelUsageService.codexLatestSession.outputTokens || 0)
        }
      }
    }

    // ── Empty state ─────────────────────────────────
    SharedWidgets.EmptyState {
      Layout.fillWidth: true
      visible: !ModelUsageService.isReady
      icon: ModelUsageService.providerIcon
      message: root.showClaude ? "No Claude Code data found"
             : root.showGemini ? "No Gemini CLI data found"
             : "No Codex CLI data found"
    }
  }
}
