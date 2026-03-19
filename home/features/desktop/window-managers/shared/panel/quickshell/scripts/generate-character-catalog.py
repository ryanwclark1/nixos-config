#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path


REPO_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = REPO_DIR / "src" / "launcher" / "data" / "characters"
OUT_PATH = REPO_DIR / "src" / "launcher" / "CharacterData.js"

TOKEN_RE = re.compile(r"[a-z0-9]+", re.IGNORECASE)

EMOJI_ALIAS_KEYWORDS = {
    "grinning": ["smile", "happy"],
    "smiling": ["smile", "happy"],
    "heart": ["love"],
    "tears": ["cry"],
    "laughing": ["laugh", "funny"],
    "party": ["celebrate"],
    "partying": ["celebrate"],
    "fire": ["flame", "hot"],
    "star": ["favorite", "sparkle"],
    "toolbox": ["tools"],
    "gear": ["settings"],
}


def title_case(text: str) -> str:
    parts = re.split(r"(\s+)", text.strip().lower())
    return "".join(part.capitalize() if not part.isspace() else part for part in parts)


def keyword_tokens(*values: str) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for value in values:
        for token in TOKEN_RE.findall(value.lower()):
            if token in seen:
                continue
            seen.add(token)
            out.append(token)
    return out


def merge_entry(
    entries: dict[str, dict],
    char: str,
    title: str,
    category: str,
    category_label: str,
    keywords: list[str],
    aliases: list[str] | None = None,
) -> None:
    if not char:
        return
    entry = entries.get(char)
    if entry is None:
        entry = {
            "name": char,
            "title": title,
            "category": category,
            "categoryLabel": category_label,
            "keywords": [],
            "aliases": [],
        }
        entries[char] = entry
    elif len(title) > len(str(entry.get("title", ""))):
        entry["title"] = title

    for field, values in (("keywords", keywords), ("aliases", aliases or [])):
        existing = set(entry[field])
        for value in values:
            clean = str(value or "").strip().lower()
            if not clean or clean in existing:
                continue
            entry[field].append(clean)
            existing.add(clean)


def parse_emojis(entries: dict[str, dict]) -> None:
    for raw in (DATA_DIR / "emojis.txt").read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line:
            continue
        parts = line.split(" ", 1)
        if len(parts) != 2:
            continue
        char, raw_title = parts
        title = title_case(raw_title)
        keywords = keyword_tokens(raw_title, "emoji")
        lower_title = raw_title.lower()
        for needle, alias_keywords in EMOJI_ALIAS_KEYWORDS.items():
            if needle in lower_title:
                keywords.extend(alias_keywords)
        merge_entry(entries, char, title, "emoji", "Emoji", keywords)


def parse_math(entries: dict[str, dict]) -> None:
    for raw in (DATA_DIR / "math.txt").read_text(encoding="utf-8").splitlines():
        line = raw.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        match = re.match(r"^(\S)\s+(.*)$", line)
        if not match:
            continue
        char = match.group(1)
        raw_title = match.group(2).strip()
        if not raw_title:
            continue
        title = title_case(raw_title)
        keywords = keyword_tokens(raw_title, "symbol", "unicode")
        lower_title = raw_title.lower()
        if any(token in lower_title for token in ("integral", "sum", "fraction", "plus", "minus", "equals", "pi", "sqrt")):
            keywords.append("math")
        merge_entry(entries, char, title, "symbol", "Symbols", keywords)


def parse_latin(entries: dict[str, dict]) -> None:
    current_section_keywords: list[str] = ["latin", "accented"]
    for raw in (DATA_DIR / "latin-extended.txt").read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line:
            continue
        if line.startswith("#"):
            heading = line.lstrip("#").strip()
            if heading and "latin extended" not in heading.lower() and "common accented" not in heading.lower():
                current_section_keywords = keyword_tokens(heading, "latin", "accented")
            continue
        parts = line.split(" ", 1)
        if len(parts) != 2:
            continue
        char, raw_title = parts
        title = title_case(raw_title)
        keywords = keyword_tokens(raw_title, *current_section_keywords)
        lower_title = raw_title.lower()
        if "tilde" in lower_title:
            keywords.extend(["spanish", "tilde"])
        merge_entry(entries, char, title, "latin", "Latin", keywords)


def main() -> None:
    entries: dict[str, dict] = {}
    parse_emojis(entries)
    parse_math(entries)
    parse_latin(entries)

    category_order = {"emoji": 0, "symbol": 1, "latin": 2}
    ordered = sorted(
        entries.values(),
        key=lambda item: (
            category_order.get(str(item.get("category", "")), 99),
            str(item.get("title", "")),
            str(item.get("name", "")),
        ),
    )

    payload = json.dumps(ordered, ensure_ascii=False, separators=(", ", ": "))
    output = (
        ".pragma library\n\n"
        "// Auto-generated by scripts/generate-character-catalog.py.\n"
        "// Source data lives in src/launcher/data/characters/.\n"
        "var characterEntries = " + payload + ";\n"
    )
    OUT_PATH.write_text(output, encoding="utf-8")


if __name__ == "__main__":
    main()
