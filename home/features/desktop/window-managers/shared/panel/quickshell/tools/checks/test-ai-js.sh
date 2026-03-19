#!/usr/bin/env bash
# Unit tests for AI-related .pragma library JS modules.
# Runs with Node.js — strips QML pragma before importing.
set -euo pipefail

script_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
repo_root="$(realpath "${script_dir}/../..")"
src="$repo_root/src"

# Build a temp directory with importable copies of the JS files
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for f in \
    "$src/features/ai/services/AiProviderProfiles.js" \
    "$src/features/ai/services/AiProviders.js" \
    "$src/features/ai/services/AiMarkdown.js"; do
    base=$(basename "$f")
    # Strip .pragma library and export all functions
    sed '1s/^\.pragma library$//' "$f" > "$tmp/$base"
    # Append module.exports that collects all top-level functions
    grep -oP '^function \K\w+' "$tmp/$base" | while read -r fn; do
        echo "module.exports.$fn = $fn;"
    done >> "$tmp/$base"
done

node --no-warnings - "$tmp" <<'TESTS'
const path = require("path");
const dir = process.argv[2];

const Profiles = require(path.join(dir, "AiProviderProfiles.js"));
const Providers = require(path.join(dir, "AiProviders.js"));
const Markdown = require(path.join(dir, "AiMarkdown.js"));

let passed = 0;
let failed = 0;

function assert(cond, msg) {
    if (cond) { passed++; }
    else { failed++; console.error("  FAIL: " + msg); }
}

function eq(a, b, msg) {
    const sa = JSON.stringify(a), sb = JSON.stringify(b);
    if (sa === sb) { passed++; }
    else { failed++; console.error("  FAIL: " + msg + "\n    expected: " + sb + "\n    got:      " + sa); }
}

function section(name) { console.log("\n" + name); }

// ═══════════════════════════════════════════════
//  AiProviderProfiles
// ═══════════════════════════════════════════════
section("AiProviderProfiles.defaultProfile");
{
    const p = Profiles.defaultProfile("anthropic");
    eq(p.model, "claude-sonnet-4-20250514", "anthropic default model");
    eq(p.temperature, 0.7, "anthropic default temperature");
    eq(p.maxTokens, 4096, "anthropic default maxTokens");
    eq(p.endpoint, "", "anthropic default endpoint");
}
{
    const p = Profiles.defaultProfile("ollama");
    eq(p.model, "", "ollama default model is empty");
}
{
    const p = Profiles.defaultProfile("openai");
    eq(p.model, "gpt-4.1", "openai default model");
}
{
    const p = Profiles.defaultProfile("gemini");
    eq(p.model, "gemini-2.5-flash", "gemini default model");
}

section("AiProviderProfiles.loadProfile — empty profiles returns defaults");
{
    const p = Profiles.loadProfile("{}", "anthropic");
    eq(p.model, "claude-sonnet-4-20250514", "empty profile -> default model");
    eq(p.temperature, 0.7, "empty profile -> default temp");
}

section("AiProviderProfiles.loadProfile — stored profile merges over defaults");
{
    const stored = JSON.stringify({ anthropic: { model: "claude-3-opus", temperature: 1.2 } });
    const p = Profiles.loadProfile(stored, "anthropic");
    eq(p.model, "claude-3-opus", "stored model returned");
    eq(p.temperature, 1.2, "stored temperature returned");
    eq(p.maxTokens, 4096, "missing field falls back to default");
}

section("AiProviderProfiles.saveProfile — creates new entry");
{
    const result = Profiles.saveProfile("{}", "openai", { model: "gpt-4o", temperature: 0.5, maxTokens: 2048, endpoint: "" });
    const parsed = JSON.parse(result);
    eq(parsed.openai.model, "gpt-4o", "saved model");
    eq(parsed.openai.temperature, 0.5, "saved temperature");
    eq(parsed.openai.maxTokens, 2048, "saved maxTokens");
}

section("AiProviderProfiles.saveProfile — preserves other providers");
{
    const existing = JSON.stringify({ ollama: { model: "llama3", temperature: 0.8, maxTokens: 4096, endpoint: "" } });
    const result = Profiles.saveProfile(existing, "anthropic", { model: "claude-3", temperature: 0.9, maxTokens: 8192, endpoint: "" });
    const parsed = JSON.parse(result);
    eq(parsed.ollama.model, "llama3", "ollama preserved");
    eq(parsed.anthropic.model, "claude-3", "anthropic saved");
}

section("AiProviderProfiles.saveProfile — round-trip");
{
    let profiles = "{}";
    profiles = Profiles.saveProfile(profiles, "openai", { model: "gpt-4o", temperature: 0.5, maxTokens: 2048, endpoint: "https://custom.api" });
    profiles = Profiles.saveProfile(profiles, "anthropic", { model: "claude-3", temperature: 1.0, maxTokens: 8192, endpoint: "" });
    const openai = Profiles.loadProfile(profiles, "openai");
    eq(openai.model, "gpt-4o", "openai model after round-trip");
    eq(openai.endpoint, "https://custom.api", "openai endpoint after round-trip");
    const anthropic = Profiles.loadProfile(profiles, "anthropic");
    eq(anthropic.model, "claude-3", "anthropic model after round-trip");
}

section("AiProviderProfiles.isLocalProvider");
{
    assert(Profiles.isLocalProvider("ollama", ""), "ollama is always local");
    assert(Profiles.isLocalProvider("ollama", "https://remote.example.com"), "ollama is local even with remote endpoint");
    assert(!Profiles.isLocalProvider("anthropic", ""), "anthropic with no endpoint is remote");
    assert(!Profiles.isLocalProvider("anthropic", "https://api.anthropic.com"), "anthropic default is remote");
    assert(Profiles.isLocalProvider("anthropic", "http://localhost:8080"), "anthropic with localhost is local");
    assert(Profiles.isLocalProvider("custom", "http://127.0.0.1:5000"), "custom with 127.0.0.1 is local");
    assert(Profiles.isLocalProvider("openai", "http://[::1]:8080"), "openai with [::1] is local");
    assert(!Profiles.isLocalProvider("openai", "https://api.openai.com"), "openai default is remote");
}

// ═══════════════════════════════════════════════
//  AiProviders
// ═══════════════════════════════════════════════
section("AiProviders.defaultModels — updated model lists");
{
    const anthro = Providers.defaultModels("anthropic");
    assert(anthro.includes("claude-sonnet-4-20250514"), "anthropic has claude-sonnet-4");
    assert(anthro.includes("claude-3-7-sonnet-20250219"), "anthropic has claude-3.7-sonnet");
    assert(!anthro.includes("claude-3-opus-20240229"), "anthropic dropped old opus");
}
{
    const openai = Providers.defaultModels("openai");
    assert(openai.includes("gpt-4.1"), "openai has gpt-4.1");
    assert(openai.includes("gpt-4.1-mini"), "openai has gpt-4.1-mini");
    assert(openai.includes("o3-mini"), "openai has o3-mini");
}
{
    const gemini = Providers.defaultModels("gemini");
    assert(gemini.includes("gemini-2.5-flash"), "gemini has 2.5-flash");
    assert(gemini.includes("gemini-2.5-pro"), "gemini has 2.5-pro");
}

section("AiProviders.supportsVision — updated detection");
{
    assert(Providers.supportsVision("anthropic", "claude-sonnet-4-20250514"), "claude-sonnet-4 supports vision");
    assert(Providers.supportsVision("anthropic", "claude-opus-4-20250514"), "claude-opus-4 supports vision");
    assert(Providers.supportsVision("anthropic", "claude-3-7-sonnet-20250219"), "claude-3.7 supports vision");
    assert(Providers.supportsVision("openai", "gpt-4.1"), "gpt-4.1 supports vision");
    assert(Providers.supportsVision("openai", "gpt-4.1-mini"), "gpt-4.1-mini supports vision");
    assert(Providers.supportsVision("openai", "o3-mini"), "o3-mini supports vision");
    assert(!Providers.supportsVision("openai", "gpt-3.5-turbo"), "gpt-3.5-turbo no vision");
    assert(Providers.supportsVision("gemini", "gemini-2.5-flash"), "gemini supports vision");
}

section("AiProviders.providerLabel");
{
    eq(Providers.providerLabel("ollama"), "Ollama", "ollama label");
    eq(Providers.providerLabel("anthropic"), "Anthropic", "anthropic label");
    eq(Providers.providerLabel("openai"), "OpenAI", "openai label");
    eq(Providers.providerLabel("custom"), "Custom", "custom label");
}

section("AiProviders.needsApiKey");
{
    assert(!Providers.needsApiKey("ollama"), "ollama doesn't need key");
    assert(Providers.needsApiKey("anthropic"), "anthropic needs key");
    assert(Providers.needsApiKey("openai"), "openai needs key");
    assert(Providers.needsApiKey("gemini"), "gemini needs key");
}

// ═══════════════════════════════════════════════
//  AiMarkdown
// ═══════════════════════════════════════════════
const colors = {
    text: "#ffffff",
    textSecondary: "#888888",
    primary: "#7aa2f7",
    secondary: "#bb9af7",
    accent: "#e0af68",
    success: "#9ece6a",
    textDisabled: "#565f89",
    fontMono: "monospace",
    codeBg: "rgba(255,255,255,0.06)"
};

section("AiMarkdown.toBlocks — basic text");
{
    const blocks = Markdown.toBlocks("Hello world", colors);
    eq(blocks.length, 1, "single text block");
    eq(blocks[0].type, "text", "type is text");
    assert(blocks[0].html.includes("Hello world"), "contains text");
}

section("AiMarkdown.toBlocks — code block");
{
    const blocks = Markdown.toBlocks("```js\nconsole.log('hi')\n```", colors);
    eq(blocks.length, 1, "single code block");
    eq(blocks[0].type, "code", "type is code");
    eq(blocks[0].lang, "js", "language is js");
    assert(blocks[0].content.includes("console.log"), "code content");
}

section("AiMarkdown.toBlocks — thinking block");
{
    const blocks = Markdown.toBlocks("<think>Internal reasoning</think>\nResponse", colors);
    eq(blocks.length, 2, "thinking + text blocks");
    eq(blocks[0].type, "thinking", "first is thinking");
    eq(blocks[1].type, "text", "second is text");
}

section("AiMarkdown — strikethrough");
{
    const html = Markdown.toHtml("~~deleted~~", colors);
    assert(html.includes("<s>deleted</s>"), "strikethrough renders as <s>");
}

section("AiMarkdown — blockquote");
{
    const html = Markdown.toHtml("> This is a quote", colors);
    assert(html.includes("border-left"), "blockquote has left border");
    assert(html.includes("This is a quote"), "blockquote contains text");
    assert(html.includes("font-style: italic"), "blockquote is italic");
}

section("AiMarkdown — horizontal rule");
{
    const html = Markdown.toHtml("text\n\n---\n\nmore", colors);
    assert(html.includes("<hr"), "horizontal rule renders as <hr>");
}
{
    const html2 = Markdown.toHtml("***", colors);
    assert(html2.includes("<hr"), "*** also renders as <hr>");
}
{
    const html3 = Markdown.toHtml("___", colors);
    assert(html3.includes("<hr"), "___ also renders as <hr>");
}

section("AiMarkdown — GFM table");
{
    const md = "| Name | Value |\n|------|-------|\n| foo | 42 |\n| bar | 99 |";
    const html = Markdown.toHtml(md, colors);
    assert(html.includes("<table"), "table tag present");
    assert(html.includes("<th"), "header cells present");
    assert(html.includes("<td"), "data cells present");
    assert(html.includes("Name"), "header text");
    assert(html.includes("42"), "data text");
    assert(html.includes("99"), "second row data");
}

section("AiMarkdown — table with inline formatting");
{
    const md = "| Feature | Status |\n|---------|--------|\n| **bold** | `done` |";
    const html = Markdown.toHtml(md, colors);
    assert(html.includes("<b>bold</b>"), "bold inside table cell");
    assert(html.includes("done"), "inline code inside table cell");
}

section("AiMarkdown — headings");
{
    const html = Markdown.toHtml("## Heading Two", colors);
    assert(html.includes("font-size: 16px"), "h2 is 16px");
    assert(html.includes("Heading Two"), "heading text");
}

section("AiMarkdown — bold and italic");
{
    const html = Markdown.toHtml("**bold** and *italic*", colors);
    assert(html.includes("<b>bold</b>"), "bold renders");
    assert(html.includes("<i>italic</i>"), "italic renders");
}

section("AiMarkdown — bullet list");
{
    const html = Markdown.toHtml("- item one\n- item two", colors);
    assert(html.includes("<ul"), "unordered list");
    assert(html.includes("<li"), "list items");
    assert(html.includes("item one"), "first item");
}

section("AiMarkdown — not a horizontal rule");
{
    // A line like "- item" should not be treated as HR
    const html = Markdown.toHtml("- item", colors);
    assert(!html.includes("<hr"), "dash list item is not an HR");
}

// ═══════════════════════════════════════════════
//  Summary
// ═══════════════════════════════════════════════
console.log("\n" + "═".repeat(50));
console.log("Results: " + passed + " passed, " + failed + " failed");
if (failed > 0) process.exit(1);
else console.log("All tests passed!");
TESTS
