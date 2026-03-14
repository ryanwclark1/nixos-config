.pragma library

// Provider-specific configuration: endpoints, model lists, defaults.
// Pure functions — no state, no QML dependencies.

function defaultEndpoint(provider) {
    switch (provider) {
        case "ollama":    return "http://localhost:11434";
        case "anthropic": return "https://api.anthropic.com";
        case "openai":    return "https://api.openai.com";
        case "gemini":    return "https://generativelanguage.googleapis.com";
        case "custom":    return "";
        default:          return "";
    }
}

function defaultModels(provider) {
    switch (provider) {
        case "ollama":
            return []; // dynamic — populated by refreshModels()
        case "anthropic":
            return ["claude-sonnet-4-5-20250929", "claude-haiku-4-5-20251001", "claude-opus-4-0-20250514"];
        case "openai":
            return ["gpt-4o", "gpt-4o-mini", "o3-mini"];
        case "gemini":
            return ["gemini-2.5-flash", "gemini-2.5-pro"];
        case "custom":
            return []; // user enters manually
        default:
            return [];
    }
}

function defaultModel(provider) {
    var models = defaultModels(provider);
    if (models.length > 0) return models[0];
    switch (provider) {
        case "ollama": return "devstral-small-2";
        case "custom": return "";
        default:       return "";
    }
}

function providerLabel(provider) {
    switch (provider) {
        case "ollama":    return "Ollama";
        case "anthropic": return "Anthropic";
        case "openai":    return "OpenAI";
        case "gemini":    return "Gemini";
        case "custom":    return "Custom";
        default:          return provider;
    }
}

function providerIcon(provider) {
    switch (provider) {
        case "ollama":    return "󱗻";
        case "anthropic": return "󰚩";
        case "openai":    return "󰧑";
        case "gemini":    return "󰊤";
        case "custom":    return "󰒍";
        default:          return "󰚩";
    }
}

function allProviders() {
    return ["ollama", "anthropic", "openai", "gemini", "custom"];
}

function needsApiKey(provider) {
    return provider === "anthropic" || provider === "openai" || provider === "gemini" || provider === "custom";
}

function envKeyName(provider) {
    switch (provider) {
        case "anthropic": return "ANTHROPIC_API_KEY";
        case "openai":    return "OPENAI_API_KEY";
        case "gemini":    return "GEMINI_API_KEY";
        default:          return "";
    }
}
