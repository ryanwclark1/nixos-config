import { describe, it, expect } from "vitest";
import {
  defaultEndpoint,
  defaultModels,
  defaultModel,
  providerLabel,
  providerIcon,
  allProviders,
  needsApiKey,
  envKeyName,
  supportsVision,
} from "../../src/features/ai/services/AiProviders.js";

describe("defaultEndpoint", () => {
  it("returns correct endpoints for known providers", () => {
    expect(defaultEndpoint("ollama")).toBe("http://localhost:11434");
    expect(defaultEndpoint("anthropic")).toContain("anthropic.com");
    expect(defaultEndpoint("openai")).toContain("openai.com");
    expect(defaultEndpoint("gemini")).toContain("googleapis.com");
  });

  it("returns empty for custom/unknown", () => {
    expect(defaultEndpoint("custom")).toBe("");
    expect(defaultEndpoint("unknown")).toBe("");
  });
});

describe("defaultModels", () => {
  it("returns model lists for API providers", () => {
    expect(defaultModels("anthropic").length).toBeGreaterThan(0);
    expect(defaultModels("openai").length).toBeGreaterThan(0);
    expect(defaultModels("gemini").length).toBeGreaterThan(0);
  });

  it("returns empty for ollama (dynamic) and custom", () => {
    expect(defaultModels("ollama")).toEqual([]);
    expect(defaultModels("custom")).toEqual([]);
  });
});

describe("defaultModel", () => {
  it("returns first model from list", () => {
    expect(defaultModel("anthropic")).toBe("claude-sonnet-4-20250514");
    expect(defaultModel("openai")).toBe("gpt-4.1");
  });

  it("returns empty for providers with no default models", () => {
    expect(defaultModel("ollama")).toBe("");
  });
});

describe("providerLabel", () => {
  it("returns human-readable labels", () => {
    expect(providerLabel("ollama")).toBe("Ollama");
    expect(providerLabel("anthropic")).toBe("Anthropic");
    expect(providerLabel("openai")).toBe("OpenAI");
  });

  it("returns raw key for unknown provider", () => {
    expect(providerLabel("mystery")).toBe("mystery");
  });
});

describe("allProviders", () => {
  it("includes all known providers", () => {
    const all = allProviders();
    expect(all).toContain("ollama");
    expect(all).toContain("anthropic");
    expect(all).toContain("openai");
    expect(all).toContain("gemini");
    expect(all).toContain("custom");
    expect(all).toHaveLength(5);
  });
});

describe("needsApiKey", () => {
  it("returns true for API providers", () => {
    expect(needsApiKey("anthropic")).toBe(true);
    expect(needsApiKey("openai")).toBe(true);
    expect(needsApiKey("gemini")).toBe(true);
    expect(needsApiKey("custom")).toBe(true);
  });

  it("returns false for ollama", () => {
    expect(needsApiKey("ollama")).toBe(false);
  });
});

describe("envKeyName", () => {
  it("returns env var names for API providers", () => {
    expect(envKeyName("anthropic")).toBe("ANTHROPIC_API_KEY");
    expect(envKeyName("openai")).toBe("OPENAI_API_KEY");
    expect(envKeyName("gemini")).toBe("GEMINI_API_KEY");
  });

  it("returns empty for ollama/unknown", () => {
    expect(envKeyName("ollama")).toBe("");
  });
});

describe("supportsVision", () => {
  it("detects Claude vision models", () => {
    expect(supportsVision("anthropic", "claude-sonnet-4-20250514")).toBe(true);
    expect(supportsVision("anthropic", "claude-3-7-sonnet-20250219")).toBe(true);
    expect(supportsVision("anthropic", "claude-3-5-haiku-20241022")).toBe(true);
  });

  it("detects OpenAI vision models", () => {
    expect(supportsVision("openai", "gpt-4o")).toBe(true);
    expect(supportsVision("openai", "gpt-4.1")).toBe(true);
    expect(supportsVision("openai", "o3-mini")).toBe(true);
  });

  it("all Gemini models support vision", () => {
    expect(supportsVision("gemini", "gemini-2.5-flash")).toBe(true);
    expect(supportsVision("gemini", "anything")).toBe(true);
  });

  it("detects Ollama vision models", () => {
    expect(supportsVision("ollama", "llava")).toBe(true);
    expect(supportsVision("ollama", "moondream")).toBe(true);
    expect(supportsVision("ollama", "llama3")).toBe(false);
  });

  it("returns false for unknown providers", () => {
    expect(supportsVision("unknown", "model")).toBe(false);
  });
});
