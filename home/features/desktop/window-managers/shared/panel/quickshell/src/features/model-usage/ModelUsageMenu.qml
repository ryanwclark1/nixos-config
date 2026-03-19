import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../shared"
import "../../services"
import "../../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMinWidth: 340; popupMaxWidth: 420; compactThreshold: 380
  implicitHeight: Math.min(620, contentCol.implicitHeight + 100)
  title: "Model Usage"
  subtitle: ModelUsageService.activeProvider === "claude" ? "Claude Code" : "Codex CLI"

  SharedWidgets.Ref { service: ModelUsageService }

  readonly property bool showClaude: ModelUsageService.activeProvider === "claude"
  readonly property bool showBothTabs: ModelUsageService.claudeEnabled && ModelUsageService.codexEnabled

  // ── Provider tabs ──────────────────────────────────
  headerExtras: [
    Row {
      visible: root.showBothTabs
      spacing: Colors.spacingS

      Repeater {
        model: [
          { key: "claude", label: "Claude" },
          { key: "codex", label: "Codex" }
        ]
        delegate: SharedWidgets.FilterChip {
          required property var modelData
          label: modelData.label
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

  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Colors.spacingM

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
                 : Colors.accent

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

    // ── Today Section ────────────────────────────────
    Rectangle {
      Layout.fillWidth: true
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
          label: "Prompts"
          value: root.showClaude ? String(ModelUsageService.claudeTodayPrompts)
                                 : String(ModelUsageService.codexTodayPrompts)
        }

        SharedWidgets.InfoRow {
          visible: root.showClaude
          label: "Sessions"
          value: String(ModelUsageService.claudeTodaySessions)
        }

        SharedWidgets.InfoRow {
          visible: root.showClaude
          label: "Tool Calls"
          value: String(ModelUsageService.claudeTodayToolCalls)
        }

        // Today tokens by model
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
            valueColor: Colors.accent
          }
        }
      }
    }

    // ── Last 7 Days Chart ────────────────────────────
    Rectangle {
      Layout.fillWidth: true
      visible: root.showClaude && ModelUsageService.claudeRecentDays.length > 0
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

        // Simple horizontal bar chart
        Repeater {
          model: ModelUsageService.claudeRecentDays

          RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS
            required property var modelData
            required property int index

            readonly property int maxCount: {
              var days = ModelUsageService.claudeRecentDays;
              var m = 1;
              for (var i = 0; i < days.length; i++)
                if (days[i].messageCount > m) m = days[i].messageCount;
              return m;
            }

            Text {
              text: {
                var parts = modelData.date.split("-");
                return parts.length >= 3 ? parts[1] + "/" + parts[2] : modelData.date;
              }
              color: Colors.textSecondary
              font.pixelSize: Colors.fontSizeXS
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
                color: Colors.accent
                opacity: 0.7 + 0.3 * (modelData.messageCount / maxCount)

                Behavior on width { NumberAnimation { duration: Colors.durationMedium } }
              }
            }

            Text {
              text: String(modelData.messageCount)
              color: Colors.text
              font.pixelSize: Colors.fontSizeXS
              font.weight: Font.DemiBold
              Layout.preferredWidth: 36
              horizontalAlignment: Text.AlignRight
            }
          }
        }
      }
    }

    // ── All-Time Model Breakdown ─────────────────────
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
          valueColor: Colors.accent
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
            // Sort by total descending
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

    // ── Codex Info Section ────────────────────────────
    Rectangle {
      Layout.fillWidth: true
      visible: !root.showClaude && ModelUsageService.codexReady
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

    // ── Empty state ──────────────────────────────────
    SharedWidgets.EmptyState {
      Layout.fillWidth: true
      visible: (root.showClaude && !ModelUsageService.claudeReady)
              || (!root.showClaude && !ModelUsageService.codexReady)
      icon: "󰊤"
      message: root.showClaude ? "No Claude Code data found" : "No Codex CLI data found"
    }
  }
}
