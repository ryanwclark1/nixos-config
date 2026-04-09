import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const aiChatPath = resolve(quickshellRoot, "src/features/ai/AiChat.qml");
const sidebarPath = resolve(quickshellRoot, "src/features/ai/components/AiConversationSidebar.qml");
const qmlDirPath = resolve(quickshellRoot, "src/features/ai/components/qmldir");

describe("AI chat layout contract", () => {
  it("uses a collapsible conversation sidebar instead of the legacy tab strip", () => {
    const aiChatSource = readFileSync(aiChatPath, "utf8");
    const qmlDirSource = readFileSync(qmlDirPath, "utf8");

    expect(aiChatSource).toContain("readonly property bool historyOverlayMode: slidePanel.width < 640");
    expect(aiChatSource).toContain("AiConversationSidebar {");
    expect(aiChatSource).toContain('icon: "apps.svg"');
    expect(aiChatSource).not.toContain("AiConversationTabs");
    expect(aiChatSource).not.toContain("id: historyMenu");
    expect(qmlDirSource).toContain("AiConversationSidebar 1.0 AiConversationSidebar.qml");
    expect(qmlDirSource).not.toContain("AiConversationTabs");
  });

  it("moves conversation actions into the sidebar rows and supports inline rename", () => {
    const sidebarSource = readFileSync(sidebarPath, "utf8");

    expect(sidebarSource).toContain('text: "Recent Chats"');
    expect(sidebarSource).toContain('tooltipText: "Conversation actions"');
    expect(sidebarSource).toContain('label: "Copy Transcript"');
    expect(sidebarSource).toContain("property string editingConversationId");
    expect(sidebarSource).toContain("AiService.renameConversation(modelData.id, text);");
    expect(sidebarSource).toContain("onDoubleClicked: root.startRename(modelData.id)");
  });
});
