import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const aiTabPath = resolve(quickshellRoot, "src/features/settings/components/tabs/AiTab.qml");
const secretInputPath = resolve(quickshellRoot, "src/features/settings/components/SettingsSecretInputRow.qml");

describe("AI secret settings UI", () => {
  it("uses masked secret inputs and opt-in persistence for provider keys", () => {
    const aiTabSource = readFileSync(aiTabPath, "utf8");

    expect((aiTabSource.match(/SettingsSecretInputRow\s*{/g) || []).length).toBe(3);
    expect(aiTabSource).toMatch(/SettingsSecretInputRow\s*{\s*label:\s*"Anthropic API Key"/s);
    expect(aiTabSource).toMatch(/SettingsSecretInputRow\s*{\s*label:\s*"OpenAI API Key"/s);
    expect(aiTabSource).toMatch(/SettingsSecretInputRow\s*{\s*label:\s*"Gemini API Key"/s);
    expect(aiTabSource).toContain("Keys stay session-only by default");
    expect(aiTabSource).toContain('property bool _remember: Config.aiAnthropicKey !== ""');
    expect(aiTabSource).toContain('property bool _remember: Config.aiOpenaiKey !== ""');
    expect(aiTabSource).toContain('property bool _remember: Config.aiGeminiKey !== ""');
    expect(aiTabSource).toContain('onTextEdited: value => root.setRememberedKey("anthropic", parent._remember, value)');
    expect(aiTabSource).toContain('onTextEdited: value => root.setRememberedKey("openai", parent._remember, value)');
    expect(aiTabSource).toContain('onTextEdited: value => root.setRememberedKey("gemini", parent._remember, value)');
  });

  it("masks secrets by default and exposes an explicit reveal toggle", () => {
    const secretInputSource = readFileSync(secretInputPath, "utf8");

    expect(secretInputSource).toContain("echoMode: root.secretVisible ? TextInput.Normal : TextInput.Password");
    expect(secretInputSource).toContain("source: IconHelpers.secretVisibilityIcon(root.secretVisible)");
    expect(secretInputSource).toContain("onClicked: root.secretVisible = !root.secretVisible");
  });
});
