.pragma library

function defaultSshWidgetInstance() {
    return {
        widgetType: "ssh",
        settings: {
            manualHosts: [],
            enableSshConfigImport: true,
            displayMode: "count",
            defaultAction: "connect",
            sshCommand: "ssh",
            showWhenEmpty: false,
            emptyClickAction: "menu",
            emptyLabel: "SSH",
            state: {
                lastConnectedId: "",
                lastConnectedLabel: "",
                lastConnectedAt: "",
                recentIds: []
            }
        }
    };
}

function findFirstWidgetInstance(barConfigs, barSectionWidgetsFn, widgetType, fallbackInstance) {
    var bars = Array.isArray(barConfigs) ? barConfigs : [];
    var sections = ["left", "center", "right"];
    for (var i = 0; i < bars.length; ++i) {
        for (var j = 0; j < sections.length; ++j) {
            var widgets = barSectionWidgetsFn ? barSectionWidgetsFn(bars[i], sections[j]) : [];
            widgets = Array.isArray(widgets) ? widgets : [];
            for (var k = 0; k < widgets.length; ++k) {
                if (String(widgets[k].widgetType || "") === String(widgetType || ""))
                    return widgets[k];
            }
        }
    }
    return fallbackInstance || null;
}

function toggleAccordionSection(currentSection, targetSection) {
    var current = String(currentSection || "");
    var target = String(targetSection || "");
    if (target === "")
        return "";
    return current === target ? "" : target;
}

function summarizeSshSessions(sessions) {
    var list = Array.isArray(sessions) ? sessions : [];
    var total = 0;
    var byType = {};
    var order = ["ssh", "scp", "sftp", "rsync", "sshfs"];
    for (var i = 0; i < list.length; ++i) {
        var session = list[i] || {};
        var type = String(session.type || "ssh");
        var count = Number(session.count || 1);
        if (!isFinite(count) || count < 1)
            count = 1;
        total += count;
        byType[type] = (byType[type] || 0) + count;
    }

    var parts = [];
    for (var j = 0; j < order.length; ++j) {
        var orderedType = order[j];
        if (byType[orderedType])
            parts.push(String(byType[orderedType]) + " " + orderedType.toUpperCase());
    }

    for (var extraType in byType) {
        if (order.indexOf(extraType) === -1)
            parts.push(String(byType[extraType]) + " " + extraType.toUpperCase());
    }

    return {
        total: total,
        byType: byType,
        parts: parts
    };
}

function formatSshHostSummary(hostCount) {
    var count = Math.max(0, Number(hostCount || 0));
    return String(count) + " SSH Host" + (count === 1 ? "" : "s");
}

function formatSshActivitySummary(sessions) {
    var summary = summarizeSshSessions(sessions);
    if (summary.total === 0)
        return "No active sessions";
    return summary.parts.join(" · ") || (String(summary.total) + " active sessions");
}

function formatDockerActivitySummary(containers) {
    var list = Array.isArray(containers) ? containers : [];
    if (list.length === 0)
        return "No containers detected";
    var running = 0;
    for (var i = 0; i < list.length; ++i) {
        if (String((list[i] || {}).state || "") === "running")
            running++;
    }
    var stopped = Math.max(0, list.length - running);
    if (stopped === 0)
        return String(running) + " running";
    if (running === 0)
        return String(stopped) + " stopped";
    return String(running) + " running · " + String(stopped) + " stopped";
}
