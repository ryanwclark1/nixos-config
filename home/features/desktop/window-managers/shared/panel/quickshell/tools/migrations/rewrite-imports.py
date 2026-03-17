#!/usr/bin/env python3

import argparse
import json
from pathlib import Path


def rewrite_qmldir(path: Path, mapping: dict[str, str]) -> bool:
    if "features" in path.parts:
        return False
    changed = False
    lines = []
    for raw in path.read_text().splitlines():
        parts = raw.split()
        if len(parts) == 3 and parts[2] in mapping:
            parts[2] = mapping[parts[2]]
            raw = " ".join(parts)
            changed = True
        lines.append(raw)
    if changed:
        path.write_text("\n".join(lines) + "\n")
    return changed


def rewrite_text(path: Path, mapping: dict[str, str]) -> bool:
    original = path.read_text()
    updated = original
    for old, new in mapping.items():
        updated = updated.replace(old, new)
    if updated != original:
        path.write_text(updated)
        return True
    return False


def main() -> int:
    parser = argparse.ArgumentParser(description="Rewrite Quickshell imports and qmldir paths from a checked-in mapping.")
    parser.add_argument("--root", default=".", help="Quickshell project root")
    parser.add_argument("--map", default="tools/migrations/import-map.json", help="Path to JSON mapping file")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    mapping_path = (root / args.map).resolve()
    mapping = json.loads(mapping_path.read_text())

    changed = 0
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix in {".qml", ".js"}:
            if rewrite_text(path, mapping.get("QML_IMPORTS", {})):
                changed += 1
        elif path.name == "qmldir":
            if rewrite_qmldir(path, mapping.get("QMLDIR_PATHS", {})):
                changed += 1

    print(f"rewrite-imports: updated {changed} file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
