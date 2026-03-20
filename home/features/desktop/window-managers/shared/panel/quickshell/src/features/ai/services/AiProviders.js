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
            return ["claude-sonnet-4-20250514", "claude-3-7-sonnet-20250219", "claude-3-5-haiku-20241022"];
        case "openai":
            return ["gpt-4.1", "gpt-4o", "gpt-4.1-mini", "o3-mini"];
        case "gemini":
            return ["gemini-2.5-flash", "gemini-2.5-pro", "gemini-2.0-flash"];
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
        case "ollama": return "";
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
        case "ollama":    return "brands/ollama-symbolic.svg";
        case "anthropic": return "brands/anthropic-symbolic.svg";
        case "openai":    return "brands/openai-symbolic.svg";
        case "gemini":    return "brands/google-gemini-symbolic.svg";
        case "custom":    return "server.svg";
        default:          return "brands/anthropic-symbolic.svg";
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

function supportsVision(provider, model) {
    if (provider === "anthropic") {
        // Claude 3+, Claude 4 (sonnet-4, opus-4) support vision
        return model.indexOf("claude-3") !== -1 || model.indexOf("claude-sonnet-4") !== -1 || model.indexOf("claude-opus-4") !== -1;
    }
    if (provider === "openai") {
        // GPT-4o, GPT-4.1, O1, O3 support vision
        return model.indexOf("gpt-4o") !== -1 || model.indexOf("gpt-4.1") !== -1 || model.indexOf("o1") !== -1 || model.indexOf("o3") !== -1;
    }
    if (provider === "gemini") {
        // All recent Gemini models support vision
        return true;
    }
    if (provider === "ollama") {
        // Some common Ollama vision models
        var m = model.toLowerCase();
        return m.indexOf("llava") !== -1 || m.indexOf("moondream") !== -1 || m.indexOf("bakllava") !== -1;
    }
    return false;
}
