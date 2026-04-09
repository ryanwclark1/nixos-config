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
    expect(tooltipSource).toContain("property bool cursorAware: true");
    expect(tooltipSource).toContain("property point hoverPoint: Qt.point(-1, -1)");
    expect(tooltipSource).toContain("property int cursorClearance: Appearance.spacingM");
    expect(tooltipSource).toContain("property int effectiveSide: preferredSide");
    expect(tooltipSource).toContain("property point effectiveHoverPoint: Qt.point(-1, -1)");
    expect(tooltipSource).toContain("readonly property var resolvedAnchorWindow:");
    expect(tooltipSource).toContain("function freezePlacement()");
    expect(tooltipSource).toContain("function anchorRectPoint()");
    expect(tooltipSource).toContain("function chooseBestSide(pointValue)");
    expect(tooltipSource).toContain("PopupWindow {");
    expect(tooltipSource).toContain("anchor.item: root.effectiveAnchorItem");
    expect(tooltipSource).not.toContain("anchor.window: root.resolvedAnchorWindow");
    expect(tooltipSource).toContain("anchor.rect.x: root.anchorRectPoint().x");
    expect(tooltipSource).toContain("anchor.rect.y: root.anchorRectPoint().y");
    expect(tooltipSource).toContain("property int popupAdjustment: PopupAdjustment.Flip | PopupAdjustment.Slide");
    expect(tooltipSource).toContain("popupTooltip.anchor.updateAnchor()");
  });

  it("wires AI chat controls through the anchored tooltip path", () => {
    const iconButtonSource = readFileSync(iconButtonPath, "utf8");
    const aiChatSource = readFileSync(aiChatPath, "utf8");
    const messageListSource = readFileSync(messageListPath, "utf8");
    const codeBlockSource = readFileSync(codeBlockPath, "utf8");

    expect(iconButtonSource).toContain("property var tooltipAnchorWindow: null");
    expect(iconButtonSource).toContain("anchorWindow: root.tooltipAnchorWindow");
    expect(iconButtonSource).toContain("hoverPoint: Qt.point(hoverArea.mouseX, hoverArea.mouseY)");
    expect(aiChatSource).toContain("anchorWindow: root");
    expect(aiChatSource).toContain("hoverPoint: Qt.point(providerPickerMouse.mouseX, providerPickerMouse.mouseY)");
    expect(aiChatSource).toContain("anchorItem: systemContextToggle");
    expect(messageListSource).toContain("property var anchorWindow: null");
    expect(messageListSource).toContain("anchorWindow: root.anchorWindow");
    expect(messageListSource).toContain("hoverPoint: Qt.point(regenHover.mouseX, regenHover.mouseY)");
    expect(codeBlockSource).toContain("property var anchorWindow: null");
    expect(codeBlockSource).toContain("anchorWindow: root.anchorWindow");
    expect(codeBlockSource).toContain("hoverPoint: Qt.point(codeCopyHover.mouseX, codeCopyHover.mouseY)");
  });
});
