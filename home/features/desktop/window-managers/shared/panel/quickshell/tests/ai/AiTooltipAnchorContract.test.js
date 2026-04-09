import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const tooltipPath = resolve(quickshellRoot, "src/shared/Tooltip.qml");
const iconButtonPath = resolve(quickshellRoot, "src/shared/IconButton.qml");
const aiChatPath = resolve(quickshellRoot, "src/features/ai/AiChat.qml");
const messageListPath = resolve(quickshellRoot, "src/features/ai/components/AiMessageList.qml");
const codeBlockPath = resolve(quickshellRoot, "src/features/ai/components/AiCodeBlock.qml");

describe("AI tooltip anchor contract", () => {
  it("supports popup anchored tooltips in the shared tooltip primitive", () => {
    const tooltipSource = readFileSync(tooltipPath, "utf8");

    expect(tooltipSource).toContain("property Item anchorItem: null");
    expect(tooltipSource).toContain("property var anchorWindow: null");
    expect(tooltipSource).toContain("readonly property bool usePopup: !!anchorWindow && !!effectiveAnchorItem");
    expect(tooltipSource).toContain("PopupWindow {");
    expect(tooltipSource).toContain("anchor.window: root.anchorWindow");
  });

  it("wires AI chat controls through the anchored tooltip path", () => {
    const iconButtonSource = readFileSync(iconButtonPath, "utf8");
    const aiChatSource = readFileSync(aiChatPath, "utf8");
    const messageListSource = readFileSync(messageListPath, "utf8");
    const codeBlockSource = readFileSync(codeBlockPath, "utf8");

    expect(iconButtonSource).toContain("property var tooltipAnchorWindow: null");
    expect(iconButtonSource).toContain("anchorWindow: root.tooltipAnchorWindow");
    expect(aiChatSource).toContain("anchorWindow: root");
    expect(aiChatSource).toContain("anchorItem: systemContextToggle");
    expect(messageListSource).toContain("property var anchorWindow: null");
    expect(messageListSource).toContain("anchorWindow: root.anchorWindow");
    expect(codeBlockSource).toContain("property var anchorWindow: null");
    expect(codeBlockSource).toContain("anchorWindow: root.anchorWindow");
  });
});
