import { describe, it, expect } from "vitest";
import {
  defaultProfile,
  loadProfile,
  saveProfile,
  isLocalProvider,
} from "../../src/features/ai/services/AiProviderProfiles.js";

describe("defaultProfile", () => {
  it("returns defaults for each provider", () => {
    expect(defaultProfile("anthropic").model).toBe("claude-sonnet-4-20250514");
    expect(defaultProfile("openai").model).toBe("gpt-4.1");
    expect(defaultProfile("gemini").model).toBe("gemini-2.5-flash");
    expect(defaultProfile("ollama").model).toBe("");
    expect(defaultProfile("custom").model).toBe("");
  });

  it("returns defaults for unknown provider", () => {
    expect(defaultProfile("unknown").temperature).toBe(0.7);
    expect(defaultProfile("unknown").maxTokens).toBe(4096);
  });
});

describe("loadProfile", () => {
  it("returns stored values when available", () => {
    const json = JSON.stringify({ anthropic: { model: "opus", temperature: 0.5 } });
    const profile = loadProfile(json, "anthropic");
    expect(profile.model).toBe("opus");
    expect(profile.temperature).toBe(0.5);
    expect(profile.maxTokens).toBe(4096); // falls back to default
  });

  it("falls back to defaults for missing provider", () => {
    const profile = loadProfile("{}", "anthropic");
    expect(profile.model).toBe("claude-sonnet-4-20250514");
  });

  it("handles invalid JSON gracefully", () => {
    const profile = loadProfile("not-json", "anthropic");
    expect(profile.model).toBe("claude-sonnet-4-20250514");
  });

  it("accepts object input (not just JSON string)", () => {
    const profile = loadProfile({ openai: { model: "custom-model" } }, "openai");
    expect(profile.model).toBe("custom-model");
  });
});

describe("saveProfile", () => {
  it("returns JSON with updated provider", () => {
    const result = saveProfile("{}", "anthropic", {
      model: "opus",
      temperature: 0.9,
    });
    const parsed = JSON.parse(result);
    expect(parsed.anthropic.model).toBe("opus");
    expect(parsed.anthropic.temperature).toBe(0.9);
  });

  it("preserves other providers", () => {
    const existing = JSON.stringify({ openai: { model: "gpt-4.1" } });
    const result = saveProfile(existing, "anthropic", { model: "opus" });
    const parsed = JSON.parse(result);
    expect(parsed.openai.model).toBe("gpt-4.1");
    expect(parsed.anthropic.model).toBe("opus");
  });

  it("does not mutate input", () => {
    const obj = { openai: { model: "gpt-4.1", temperature: 0.7, maxTokens: 4096, endpoint: "" } };
    saveProfile(obj, "anthropic", { model: "opus" });
    expect(obj.anthropic).toBeUndefined();
  });
});

describe("isLocalProvider", () => {
  it("returns true for ollama regardless of endpoint", () => {
    expect(isLocalProvider("ollama", "")).toBe(true);
    expect(isLocalProvider("ollama", "https://remote.com")).toBe(true);
  });

  it("detects localhost endpoints", () => {
    expect(isLocalProvider("custom", "http://localhost:8080")).toBe(true);
    expect(isLocalProvider("custom", "http://127.0.0.1:11434")).toBe(true);
    expect(isLocalProvider("custom", "http://[::1]:8080")).toBe(true);
  });

  it("returns false for remote endpoints", () => {
    expect(isLocalProvider("anthropic", "https://api.anthropic.com")).toBe(false);
    expect(isLocalProvider("custom", "https://my-llm.example.com")).toBe(false);
  });

  it("returns false when no endpoint", () => {
    expect(isLocalProvider("anthropic", "")).toBe(false);
    expect(isLocalProvider("custom", null)).toBe(false);
  });
});
