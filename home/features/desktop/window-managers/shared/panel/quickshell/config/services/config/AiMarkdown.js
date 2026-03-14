.pragma library

// Lightweight markdown → Qt RichText HTML converter.
// Supports: headings, bold, italic, inline code, code blocks,
// bullet/numbered lists, links, paragraphs, thinking blocks.

// ── Block-based API ──────────────────────────────────────
// toBlocks(markdown, colors) → [{type, content, lang?, html?}]
//   type: "text"     — rendered HTML in .html, raw markdown in .content
//   type: "code"     — raw code in .content, language in .lang
//   type: "thinking" — rendered HTML in .html, raw text in .content

function toBlocks(markdown, colors) {
    if (!markdown) return [];

    // First, extract thinking blocks before markdown parsing
    var segments = _splitThinkingBlocks(markdown);
    var blocks = [];

    for (var s = 0; s < segments.length; s++) {
        var seg = segments[s];
        if (seg.type === "thinking") {
            blocks.push({
                type: "thinking",
                content: seg.content.trim(),
                html: _renderInlineHtml(seg.content.trim(), colors)
            });
        } else {
            // Parse markdown content into text and code blocks
            var parsed = _parseMarkdownBlocks(seg.content, colors);
            blocks = blocks.concat(parsed);
        }
    }

    return blocks;
}

// ── Legacy flat HTML API (kept for simple use cases) ─────
function toHtml(markdown, colors) {
    var blocks = toBlocks(markdown, colors);
    var parts = [];
    for (var i = 0; i < blocks.length; i++) {
        var b = blocks[i];
        if (b.type === "code") {
            var c = colors || {};
            var codeBg = c.codeBg || "rgba(255,255,255,0.06)";
            var fontMono = c.fontMono || "monospace";
            var textColor = c.text || "#ffffff";
            parts.push('<pre style="background-color: ' + codeBg +
                '; padding: 8px 10px; margin: 4px 0; border-radius: 6px; font-family: ' +
                fontMono + '; font-size: 12px; color: ' + textColor + ';">' +
                _escapeHtml(b.content) + '</pre>');
        } else if (b.type === "thinking") {
            var tc = colors || {};
            var secondaryColor = tc.textSecondary || "#aaaaaa";
            parts.push('<p style="color: ' + secondaryColor +
                '; font-style: italic; margin: 4px 0; opacity: 0.7;">💭 ' +
                b.html + '</p>');
        } else {
            parts.push(b.html);
        }
    }
    return parts.join("");
}

// ── Internal: split out <think>/<thinking> blocks ────────
function _splitThinkingBlocks(text) {
    // Match <think>...</think> or <thinking>...</thinking>
    var pattern = /<think(?:ing)?>([\s\S]*?)<\/think(?:ing)?>/gi;
    var segments = [];
    var lastIndex = 0;
    var match;

    while ((match = pattern.exec(text)) !== null) {
        // Text before the thinking block
        if (match.index > lastIndex) {
            var before = text.substring(lastIndex, match.index);
            if (before.trim().length > 0)
                segments.push({ type: "text", content: before });
        }
        // The thinking block content
        if (match[1].trim().length > 0)
            segments.push({ type: "thinking", content: match[1] });
        lastIndex = match.index + match[0].length;
    }

    // Remaining text after last thinking block
    if (lastIndex < text.length) {
        var remaining = text.substring(lastIndex);
        if (remaining.trim().length > 0)
            segments.push({ type: "text", content: remaining });
    }

    // If no thinking blocks found, return the whole thing as text
    if (segments.length === 0 && text.trim().length > 0)
        segments.push({ type: "text", content: text });

    return segments;
}

// ── Internal: parse markdown into text + code blocks ─────
function _parseMarkdownBlocks(markdown, colors) {
    var lines = markdown.split("\n");
    var blocks = [];
    var inCodeBlock = false;
    var codeBlockContent = [];
    var codeBlockLang = "";
    var textLines = [];

    function flushText() {
        if (textLines.length === 0) return;
        var raw = textLines.join("\n");
        if (raw.trim().length > 0) {
            blocks.push({
                type: "text",
                content: raw,
                html: _renderMarkdownLines(textLines, colors)
            });
        }
        textLines = [];
    }

    for (var i = 0; i < lines.length; i++) {
        var line = lines[i];

        // Code block fences
        if (line.match(/^```/)) {
            if (inCodeBlock) {
                // Close code block
                flushText();
                blocks.push({
                    type: "code",
                    content: codeBlockContent.join("\n"),
                    lang: codeBlockLang
                });
                codeBlockContent = [];
                inCodeBlock = false;
            } else {
                flushText();
                codeBlockLang = line.replace(/^```\s*/, "");
                inCodeBlock = true;
            }
            continue;
        }

        if (inCodeBlock) {
            codeBlockContent.push(line);
            continue;
        }

        textLines.push(line);
    }

    // Close any open code block
    if (inCodeBlock) {
        flushText();
        blocks.push({
            type: "code",
            content: codeBlockContent.join("\n"),
            lang: codeBlockLang
        });
    } else {
        flushText();
    }

    return blocks;
}

// ── Internal: render markdown lines to HTML ──────────────
function _renderMarkdownLines(lines, colors) {
    var textColor = (colors && colors.text) || "#ffffff";
    var html = [];
    var inList = false;

    for (var i = 0; i < lines.length; i++) {
        var line = lines[i];

        // Empty line — paragraph break
        if (line.trim() === "") {
            if (inList) { html.push('</ul>'); inList = false; }
            html.push('<br/>');
            continue;
        }

        // Headings
        var headingMatch = line.match(/^(#{1,3})\s+(.+)/);
        if (headingMatch) {
            if (inList) { html.push('</ul>'); inList = false; }
            var level = headingMatch[1].length;
            var sizes = [18, 16, 14];
            var size = sizes[level - 1] || 14;
            html.push('<p style="font-size: ' + size + 'px; font-weight: bold; color: ' +
                textColor + '; margin: 6px 0 2px 0;">' +
                _inlineFormat(headingMatch[2], colors) + '</p>');
            continue;
        }

        // Bullet lists
        var bulletMatch = line.match(/^[\s]*[-*+]\s+(.+)/);
        if (bulletMatch) {
            if (!inList) { html.push('<ul style="margin: 2px 0 2px 16px;">'); inList = true; }
            html.push('<li style="color: ' + textColor + ';">' +
                _inlineFormat(bulletMatch[1], colors) + '</li>');
            continue;
        }

        // Numbered lists
        var numMatch = line.match(/^[\s]*(\d+)[.)]\s+(.+)/);
        if (numMatch) {
            if (!inList) { html.push('<ul style="margin: 2px 0 2px 16px;">'); inList = true; }
            html.push('<li style="color: ' + textColor + ';">' +
                numMatch[1] + '. ' + _inlineFormat(numMatch[2], colors) + '</li>');
            continue;
        }

        // Close list if we're in one
        if (inList) { html.push('</ul>'); inList = false; }

        // Regular paragraph
        html.push('<p style="color: ' + textColor + '; margin: 1px 0;">' +
            _inlineFormat(line, colors) + '</p>');
    }

    if (inList) { html.push('</ul>'); }
    return html.join("");
}

// ── Internal: render text with inline formatting only ────
function _renderInlineHtml(text, colors) {
    var textColor = (colors && colors.text) || "#ffffff";
    var escaped = _escapeHtml(text);
    var lines = escaped.split("\n");
    var result = [];
    for (var i = 0; i < lines.length; i++) {
        result.push('<span style="color: ' + textColor + ';">' +
            _applyInlineFormatting(lines[i], colors) + '</span>');
    }
    return result.join("<br/>");
}

function _inlineFormat(text, colors) {
    var result = _escapeHtml(text);
    return _applyInlineFormatting(result, colors);
}

function _applyInlineFormatting(escapedText, colors) {
    var primaryColor = (colors && colors.primary) || "#7aa2f7";
    var fontMono = (colors && colors.fontMono) || "monospace";
    var codeBg = (colors && colors.codeBg) || "rgba(255,255,255,0.06)";

    var result = escapedText;

    // Bold: **text** or __text__
    result = result.replace(/\*\*(.+?)\*\*/g, '<b>$1</b>');
    result = result.replace(/__(.+?)__/g, '<b>$1</b>');

    // Italic: *text* or _text_
    result = result.replace(/\*(.+?)\*/g, '<i>$1</i>');
    result = result.replace(/_(.+?)_/g, '<i>$1</i>');

    // Inline code: `text`
    result = result.replace(/`([^`]+)`/g,
        '<span style="background-color: ' + codeBg +
        '; padding: 1px 4px; border-radius: 3px; font-family: ' +
        fontMono + '; font-size: 12px;">$1</span>');

    // Links: [text](url) — rendered as colored text (no clickable links in TextEdit)
    result = result.replace(/\[([^\]]+)\]\([^)]+\)/g,
        '<span style="color: ' + primaryColor + ';">$1</span>');

    return result;
}

function _escapeHtml(text) {
    return text
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;");
}
