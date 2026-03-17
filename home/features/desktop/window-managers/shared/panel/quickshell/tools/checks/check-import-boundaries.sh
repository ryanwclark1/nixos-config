#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"
src_dir="${repo_root}/src"

python - <<'PY' "${src_dir}"
from pathlib import Path
import re
import sys

src_dir = Path(sys.argv[1])
fail = 0

allowed_feature_imports = {
    '../bar',
    '../launcher',
    '../menu',
    '../system/sections',
    '../notifications',
    '../services',
    '../shell',
    '../widgets',
    '../services/AiProviders.js',
    '../system/sections',
    '../../services',
    '../../../services',
    '../../widgets',
    '../../../widgets',
    '../../../../services',
    '../../../../widgets',
    '../../menu/settings',
    '../../widgets/lock',
    '../../widgets/osd',
    '../../menu',
    '../../../menu',
    '../sections',
    '../models/ModuleUtils.js',
    '..',
    '.',
    'components',
    'services/AiProviders.js',
    'services/AiMarkdown.js',
    '../../menu/settings',
}

import_re = re.compile(r'^\s*import\s+"([^"]+)"', re.MULTILINE)

migrated_roots = (
    src_dir / 'app',
    src_dir / 'features' / 'ai',
    src_dir / 'features' / 'control-center',
    src_dir / 'features' / 'settings',
    src_dir / 'features' / 'system',
    src_dir / 'features' / 'system' / 'surfaces',
    src_dir / 'features' / 'lock',
    src_dir / 'features' / 'osd',
)

for root in migrated_roots:
    if not root.exists():
        continue
    paths = root.rglob('*.qml')
    for path in paths:
        text = path.read_text()
        for match in import_re.finditer(text):
            target = match.group(1)
            if target.startswith('root:'):
                print(f'check-import-boundaries: forbidden root import in {path}: {target}', file=sys.stderr)
                fail = 1
            if '/features/' in path.as_posix() and target.startswith('../') and target not in allowed_feature_imports:
                print(f'check-import-boundaries: suspicious migrated-feature import in {path}: {target}', file=sys.stderr)
                fail = 1

shared_dir = src_dir / 'shared'
if shared_dir.exists():
    for path in shared_dir.rglob('*.qml'):
        text = path.read_text()
        for match in import_re.finditer(text):
            target = match.group(1)
            if '/features/' in target:
                print(f'check-import-boundaries: shared code imports feature-owned path in {path}: {target}', file=sys.stderr)
                fail = 1

for path in src_dir.rglob('*.qml'):
    text = path.read_text()
    for match in import_re.finditer(text):
        target = match.group(1)
        if target.startswith('root:'):
            print(f'check-import-boundaries: forbidden root import in {path}: {target}', file=sys.stderr)
            fail = 1

for module in (
    src_dir / 'app',
    src_dir / 'features' / 'ai',
    src_dir / 'features' / 'control-center',
    src_dir / 'features' / 'settings',
    src_dir / 'features' / 'system',
    src_dir / 'features' / 'system' / 'sections',
    src_dir / 'features' / 'system' / 'surfaces',
):
    if not (module / 'qmldir').exists():
        print(f'check-import-boundaries: missing qmldir in {module}', file=sys.stderr)
        fail = 1

raise SystemExit(fail)
PY
