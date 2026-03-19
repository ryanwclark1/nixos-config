import { describe, it, expect } from "vitest";
import {
  toBlocks,
  toHtml,
  _splitThinkingBlocks,
  _escapeHtml,
} from "../../src/features/ai/services/AiMarkdown.js";

const colors = {
  text: "#ffffff",
  primary: "#7aa2f7",
  secondary: "#bb9af7",
  accent: "#e0af68",
  success: "#9ece6a",
  textSecondary: "#aaaaaa",
  textDisabled: "#565f89",
  codeBg: "rgba(255,255,255,0.06)",
  fontMono: "monospace",
};

// ---------------------------------------------------------------------------
// _escapeHtml
// ---------------------------------------------------------------------------

describe("_escapeHtml", () => {
  it("escapes HTML entities", () => {
    expect(_escapeHtml('<script>"alert"</script>')).toBe(
      "&lt;script&gt;&quot;alert&quot;&lt;/script&gt;"
    );
  });

  it("escapes ampersands", () => {
    expect(_escapeHtml("a & b")).toBe("a &amp; b");
  });
});

// ---------------------------------------------------------------------------
// _splitThinkingBlocks
// ---------------------------------------------------------------------------

describe("_splitThinkingBlocks", () => {
  it("returns text segment when no thinking blocks", () => {
    const result = _splitThinkingBlocks("Hello world");
    expect(result).toHaveLength(1);
    expect(result[0]).toMatchObject({ type: "text", content: "Hello world" });
  });

  it("extracts <think> block", () => {
    const result = _splitThinkingBlocks("Before <think>inner thought</think> After");
    expect(result).toHaveLength(3);
    expect(result[0].type).toBe("text");
    expect(result[1]).toMatchObject({ type: "thinking", content: "inner thought" });
    expect(result[2].type).toBe("text");
  });

  it("extracts <thinking> block", () => {
    const result = _splitThinkingBlocks("<thinking>thought</thinking>");
    expect(result).toHaveLength(1);
    expect(result[0].type).toBe("thinking");
  });

  it("handles multiple thinking blocks", () => {
    const text = "A <think>one</think> B <thinking>two</thinking> C";
    const result = _splitThinkingBlocks(text);
    const thinking = result.filter((s) => s.type === "thinking");
    expect(thinking).toHaveLength(2);
  });
});

// ---------------------------------------------------------------------------
// toBlocks
// ---------------------------------------------------------------------------

describe("toBlocks", () => {
  it("returns empty array for null/empty", () => {
    expect(toBlocks(null, colors)).toEqual([]);
    expect(toBlocks("", colors)).toEqual([]);
  });

  it("parses simple text into text block", () => {
    const blocks = toBlocks("Hello world", colors);
    expect(blocks).toHaveLength(1);
    expect(blocks[0].type).toBe("text");
    expect(blocks[0].html).toContain("Hello world");
  });

  it("extracts code blocks with language", () => {
    const md = "Text before\n```javascript\nconst x = 1;\n```\nText after";
    const blocks = toBlocks(md, colors);
    const code = blocks.find((b) => b.type === "code");
    expect(code).toBeDefined();
    expect(code.lang).toBe("javascript");
    expect(code.content).toBe("const x = 1;");
  });

  it("handles unclosed code block", () => {
    const md = "```python\nprint('hi')\n";
    const blocks = toBlocks(md, colors);
    const code = blocks.find((b) => b.type === "code");
    expect(code).toBeDefined();
    expect(code.content).toContain("print('hi')");
  });

  it("extracts thinking blocks", () => {
    const md = "<think>Let me think...</think>\nHere's the answer.";
    const blocks = toBlocks(md, colors);
    expect(blocks.some((b) => b.type === "thinking")).toBe(true);
    expect(blocks.some((b) => b.type === "text")).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// toHtml
// ---------------------------------------------------------------------------

describe("toHtml", () => {
  it("renders headings with appropriate sizes", () => {
    const html = toHtml("# Big\n## Medium\n### Small", colors);
    expect(html).toContain("font-size: 18px");
    expect(html).toContain("font-size: 16px");
    expect(html).toContain("font-size: 14px");
  });

  it("renders bold and italic", () => {
    const html = toHtml("**bold** and *italic*", colors);
    expect(html).toContain("<b>bold</b>");
    expect(html).toContain("<i>italic</i>");
  });

  it("renders inline code", () => {
    const html = toHtml("Use `npm install`", colors);
    expect(html).toContain("npm install");
    expect(html).toContain("monospace");
  });

  it("renders bullet lists", () => {
    const html = toHtml("- item one\n- item two", colors);
    expect(html).toContain("<ul");
    expect(html).toContain("<li");
    expect(html).toContain("item one");
  });

  it("renders numbered lists", () => {
    const html = toHtml("1. first\n2. second", colors);
    expect(html).toContain("1.");
    expect(html).toContain("2.");
  });

  it("renders code blocks in pre tags", () => {
    const html = toHtml("```\ncode here\n```", colors);
    expect(html).toContain("<pre");
    expect(html).toContain("code here");
  });

  it("renders links as colored text", () => {
    const html = toHtml("[click me](https://example.com)", colors);
    expect(html).toContain("click me");
    expect(html).toContain(colors.primary);
    // Links are not clickable in Qt RichText — no <a> tags
    expect(html).not.toContain("<a ");
  });

  it("renders blockquotes", () => {
    const html = toHtml("> This is quoted", colors);
    expect(html).toContain("border-left");
    expect(html).toContain("This is quoted");
  });

  it("renders strikethrough", () => {
    const html = toHtml("~~deleted~~", colors);
    expect(html).toContain("<s>deleted</s>");
  });

  it("renders horizontal rules", () => {
    const html = toHtml("---", colors);
    expect(html).toContain("<hr");
  });

  it("renders thinking blocks with indicator", () => {
    const html = toHtml("<think>pondering</think>\nAnswer", colors);
    expect(html).toContain("pondering");
    expect(html).toContain("italic");
  });

  it("handles GFM tables", () => {
    const md = "| Col1 | Col2 |\n| --- | --- |\n| a | b |";
    const html = toHtml(md, colors);
    expect(html).toContain("<table");
    expect(html).toContain("<th");
    expect(html).toContain("<td");
    expect(html).toContain("Col1");
    expect(html).toContain("a");
  });

  it("highlights numeric inline code", () => {
    const html = toHtml("`42`", colors);
    expect(html).toContain(colors.accent);
  });
});
