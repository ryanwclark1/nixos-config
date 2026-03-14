import QtQuick

QtObject {
    id: root

    property var pluginApi: null
    property var pluginManifest: null
    property var pluginService: null

    function _setting(key, defaultValue) {
        if (!pluginApi)
            return defaultValue;
        return pluginApi.loadSetting(key, defaultValue);
    }

    function _failureMode() {
        return String(_setting("failureMode", "none"));
    }

    function _label() {
        return String(_setting("label", "Ref"));
    }

    function _state() {
        var raw = pluginApi ? pluginApi.loadState() : ({});
        if (!raw || typeof raw !== "object")
            raw = ({});
        return {
            count: Math.max(0, Number(raw.count || raw.clicks || 0)),
            lastUpdated: String(raw.lastUpdated || "")
        };
    }

    function _writeState(nextState) {
        if (!pluginApi)
            return false;
        pluginApi.saveStateEnvelope({
            stateVersion: 2,
            updatedAt: new Date().toISOString(),
            payload: {
                count: Math.max(0, Number(nextState.count || 0)),
                lastUpdated: String(nextState.lastUpdated || "")
            }
        });
        if (pluginService && pluginService.pluginRuntimeUpdated)
            pluginService.pluginRuntimeUpdated();
        return true;
    }

    function _filtered(items, query) {
        var q = String(query || "").trim().toLowerCase();
        if (q === "")
            return items;
        var result = [];
        for (var i = 0; i < items.length; ++i) {
            var entry = items[i];
            var haystack = (String(entry.name || "") + " " + String(entry.description || "")).toLowerCase();
            if (haystack.indexOf(q) !== -1)
                result.push(entry);
        }
        return result;
    }

    function items(query, context) {
        if (_failureMode() === "query")
            throw new Error("Reference plugin query failure requested.");

        var label = _label();
        var state = _state();
        var baseItems = [
            {
                name: label + " Increment",
                description: "Increase the shared reference counter.",
                icon: "󰐕",
                score: 100,
                data: { action: "increment" }
            },
            {
                name: label + " Reset",
                description: "Reset the shared reference counter to zero.",
                icon: "󰑐",
                score: 90,
                data: { action: "reset" }
            },
            {
                name: label + " Summary",
                description: "Counter is " + state.count + (state.lastUpdated !== "" ? (" • updated " + state.lastUpdated) : ""),
                icon: "󰨚",
                score: 80,
                data: { action: "summary" }
            }
        ];
        return _filtered(baseItems, query);
    }

    function execute(item, context) {
        if (_failureMode() === "execute")
            throw new Error("Reference plugin execute failure requested.");

        var action = item && item.data ? String(item.data.action || "") : "";
        var state = _state();

        if (action === "increment") {
            state.count += 1;
            state.lastUpdated = new Date().toISOString();
            return _writeState(state);
        }

        if (action === "reset")
            return _writeState({ count: 0, lastUpdated: "" });

        if (action === "summary") {
            if (pluginApi)
                pluginApi.saveSetting("lastSummaryQuery", String(context && context.query || ""));
            if (pluginService && pluginService.pluginRuntimeUpdated)
                pluginService.pluginRuntimeUpdated();
            return true;
        }

        return false;
    }

    function shutdown() {}
}
