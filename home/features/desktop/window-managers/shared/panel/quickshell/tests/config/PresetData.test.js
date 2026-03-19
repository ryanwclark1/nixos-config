import { describe, it, expect } from "vitest";
import { sanitizePresetData, mergePresetData } from "../../src/services/preset/PresetData.js";

describe("sanitizePresetData", () => {
  it("removes secrets, volatile state, and preset metadata without mutating input", () => {
    const source = {
      _version: 2,
      description: "Focus mode",
      ai: {
        provider: "openai",
        anthropicKey: "anthropic-secret",
        openaiKey: "openai-secret",
        geminiKey: "gemini-secret",
        timeout: 120,
      },
      state: {
        activeSurfaceId: "launcher",
        debug: true,
      },
      theme: {
        name: "Nord",
      },
    };

    const sanitized = sanitizePresetData(source);

    expect(sanitized).toEqual({
      ai: {
        provider: "openai",
        timeout: 120,
      },
      state: {
        debug: true,
      },
      theme: {
        name: "Nord",
      },
    });
    expect(source.ai.openaiKey).toBe("openai-secret");
    expect(source.state.activeSurfaceId).toBe("launcher");
    expect(source._version).toBe(2);
    expect(source.description).toBe("Focus mode");
  });
});

describe("mergePresetData", () => {
  it("applies presettable settings while preserving current secrets and runtime-only state", () => {
    const currentData = {
      ai: {
        provider: "openai",
        anthropicKey: "current-anthropic",
        openaiKey: "current-openai",
        geminiKey: "current-gemini",
        timeout: 60,
      },
      state: {
        activeSurfaceId: "notifications",
        debug: false,
      },
      theme: {
        name: "Base",
      },
      power: {
        batMonitorTimeout: 5,
      },
    };

    const presetData = {
      description: "Travel",
      ai: {
        provider: "anthropic",
        anthropicKey: "preset-secret",
        timeout: 180,
      },
      state: {
        activeSurfaceId: "launcher",
        debug: true,
      },
      theme: {
        name: "Solarized",
      },
      power: {
        batMonitorTimeout: 12,
      },
    };

    const merged = mergePresetData(currentData, presetData);

    expect(merged.ai).toEqual({
      provider: "anthropic",
      anthropicKey: "current-anthropic",
      openaiKey: "current-openai",
      geminiKey: "current-gemini",
      timeout: 180,
    });
    expect(merged.state).toEqual({
      activeSurfaceId: "notifications",
      debug: true,
    });
    expect(merged.theme.name).toBe("Solarized");
    expect(merged.power.batMonitorTimeout).toBe(12);
  });
});
