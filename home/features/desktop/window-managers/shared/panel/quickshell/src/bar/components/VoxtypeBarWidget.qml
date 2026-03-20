import QtQuick
import Quickshell
import "../../services"
import "../../widgets" as SharedWidgets
import "../PanelWidgetHelpers.js" as PanelHelpers

SharedWidgets.BarPill {
    id: root
    property var widgetInstance: null
    property bool vertical: false

    readonly property bool iconOnly: PanelHelpers.isSummaryWidgetIconOnly(widgetInstance, vertical)
    readonly property string iconTheme: PanelHelpers.widgetStringSetting(widgetInstance, "iconTheme", "nerd-font", ["nerd-font", "emoji", "material", "phosphor", "codicons", "omarchy", "minimal", "dots", "arrows", "text"])
    readonly property int refreshIntervalSeconds: PanelHelpers.widgetIntegerSetting(widgetInstance, "refreshInterval", 1, 1, 10)
    readonly property var statusData: {
        if (statusPoll.value && typeof statusPoll.value === "object")
            return statusPoll.value;
        return {
            text: "Mic",
            alt: "idle",
            class: "idle",
            tooltip: "Voxtype ready - hold hotkey to record"
        };
    }
    readonly property string statusText: String(statusData.text || "Mic")
    readonly property string statusAlt: String(statusData.alt || "idle")
    readonly property string statusClass: String(statusData.class || statusAlt || "idle")
    readonly property string statusTooltip: String(statusData.tooltip || "Voxtype")
    readonly property string statusLabel: {
        var key = statusAlt.toLowerCase();
        if (key === "recording")
            return "REC";
        if (key === "transcribing")
            return "Transcribing";
        if (key === "processing")
            return "Processing";
        if (key === "missing")
            return "Missing";
        if (key === "error")
            return "Error";
        if (key === "idle")
            return "Idle";
        return key.length > 0 ? key[0].toUpperCase() + key.substring(1) : "Voxtype";
    }
    readonly property color accentColor: {
        var key = statusClass.toLowerCase();
        if (key === "recording")
            return Colors.error;
        if (key === "transcribing" || key === "processing")
            return Colors.primary;
        if (key === "missing" || key === "error")
            return Colors.warning;
        return Colors.text;
    }
    readonly property string statusFontFamily: {
        if (iconTheme === "material")
            return "Material Design Icons";
        if (iconTheme === "phosphor")
            return "Phosphor";
        if (iconTheme === "codicons")
            return "codicon";
        if (iconTheme === "omarchy")
            return "Omarchy";
        if (iconTheme === "emoji" || iconTheme === "text")
            return "";
        return Appearance.fontMono;
    }

    tooltipText: statusTooltip
    activeColor: Colors.withAlpha(accentColor, statusClass.toLowerCase() === "recording" ? 0.22 : 0.16)
    normalColor: Colors.withAlpha(accentColor, 0.12)
    hoverColor: Colors.withAlpha(accentColor, 0.18)
    onClicked: {
        root.runVoxtypeCommand(["record", "toggle"]);
    }
    contextActions: [
        {
            label: root.statusAlt.toLowerCase() === "recording" ? "Stop Recording" : "Toggle Recording",
            icon: root.statusAlt.toLowerCase() === "recording" ? "stop.svg" : "play.svg",
            action: () => root.runVoxtypeCommand(["record", "toggle"])
        },
        {
            label: "Start Recording",
            icon: "mic.svg",
            action: () => root.runVoxtypeCommand(["record", "start"])
        },
        {
            label: "Stop Recording",
            icon: "stop.svg",
            action: () => root.runVoxtypeCommand(["record", "stop"])
        },
        {
            separator: true
        },
        {
            label: "Restart Voxtype Service",
            icon: "arrow-clockwise.svg",
            action: () => {
                Quickshell.execDetached(["systemctl", "--user", "restart", "voxtype.service"]);
                refreshAfterAction.restart();
            }
        }
    ]

    function runVoxtypeCommand(args) {
        var command = ["sh", "-c", "command -v voxtype >/dev/null 2>&1 && exec voxtype \"$@\"", "sh"];
        for (var i = 0; i < args.length; ++i)
            command.push(args[i]);
        Quickshell.execDetached(command);
        refreshAfterAction.restart();
    }

    Timer {
        id: refreshAfterAction
        interval: 250
        repeat: false
        onTriggered: statusPoll.poll()
    }

    CommandPoll {
        id: statusPoll
        interval: root.refreshIntervalSeconds * 1000
        running: true
        command: [
            "sh",
            "-c",
            "if command -v voxtype >/dev/null 2>&1; then exec voxtype status --format json --icon-theme \"$1\"; else printf '{\"text\":\"!\",\"alt\":\"missing\",\"class\":\"error\",\"tooltip\":\"voxtype not installed\"}\\n'; fi",
            "sh",
            root.iconTheme
        ]
        parse: function(out) {
            var raw = String(out || "").trim();
            if (raw === "") {
                return {
                    text: "!",
                    alt: "error",
                    class: "error",
                    tooltip: "Voxtype status unavailable"
                };
            }
            try {
                var parsed = JSON.parse(raw);
                if (parsed && typeof parsed === "object")
                    return parsed;
            } catch (e) {
            }
            return {
                text: "!",
                alt: "error",
                class: "error",
                tooltip: "Failed to parse voxtype status"
            };
        }
    }

    Row {
        spacing: Appearance.spacingXS

        Text {
            text: root.statusText
            color: root.accentColor
            font.pixelSize: Appearance.fontSizeXL
            font.family: root.statusFontFamily
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: !root.iconOnly
            text: root.statusLabel
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
