.pragma library

// Per-provider profile storage — pure functions, no QML dependencies.
// Each provider retains its own model/temperature/maxTokens/endpoint settings.

function defaultProfile(provider) {
    switch (provider) {
        case "ollama":
            return { model: "", temperature: 0.7, maxTokens: 4096, endpoint: "" };
        case "anthropic":
            return { model: "claude-sonnet-4-20250514", temperature: 0.7, maxTokens: 4096, endpoint: "" };
        case "openai":
            return { model: "gpt-4.1", temperature: 0.7, maxTokens: 4096, endpoint: "" };
        case "gemini":
            return { model: "gemini-2.5-flash", temperature: 0.7, maxTokens: 4096, endpoint: "" };
        case "custom":
            return { model: "", temperature: 0.7, maxTokens: 4096, endpoint: "" };
        default:
            return { model: "", temperature: 0.7, maxTokens: 4096, endpoint: "" };
    }
}

function loadProfile(profilesJson, provider) {
    var profiles = {};
    if (profilesJson && typeof profilesJson === "string" && profilesJson.length > 2) {
        try { profiles = JSON.parse(profilesJson); } catch (e) { profiles = {}; }
    } else if (profilesJson && typeof profilesJson === "object") {
        profiles = profilesJson;
    }
    var defaults = defaultProfile(provider);
    var stored = profiles[provider] || {};
    return {
        model: stored.model !== undefined ? stored.model : defaults.model,
        temperature: stored.temperature !== undefined ? stored.temperature : defaults.temperature,
        maxTokens: stored.maxTokens !== undefined ? stored.maxTokens : defaults.maxTokens,
        endpoint: stored.endpoint !== undefined ? stored.endpoint : defaults.endpoint
    };
}

function saveProfile(profilesJson, provider, settings) {
    var profiles = {};
    if (profilesJson && typeof profilesJson === "string" && profilesJson.length > 2) {
        try { profiles = JSON.parse(profilesJson); } catch (e) { profiles = {}; }
    } else if (profilesJson && typeof profilesJson === "object") {
        profiles = profilesJson;
    }
    // Deep copy to avoid mutations
    var next = {};
    for (var key in profiles) {
        next[key] = {
            model: profiles[key].model,
            temperature: profiles[key].temperature,
            maxTokens: profiles[key].maxTokens,
            endpoint: profiles[key].endpoint
        };
    }
    next[provider] = {
        model: settings.model !== undefined ? settings.model : "",
        temperature: settings.temperature !== undefined ? settings.temperature : 0.7,
        maxTokens: settings.maxTokens !== undefined ? settings.maxTokens : 4096,
        endpoint: settings.endpoint !== undefined ? settings.endpoint : ""
    };
    return JSON.stringify(next);
}

function isLocalProvider(provider, endpoint) {
    if (provider === "ollama") return true;
    if (!endpoint) return false;
    var ep = endpoint.toLowerCase();
    return ep.indexOf("localhost") !== -1 || ep.indexOf("127.0.0.1") !== -1 || ep.indexOf("[::1]") !== -1;
}
