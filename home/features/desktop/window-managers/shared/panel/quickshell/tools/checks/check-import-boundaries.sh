#!/usr/bin/env bash
set -euo pipefail

script_path="$(realpath "${BASH_SOURCE[0]}")"
script_dir="$(dirname "${script_path}")"
repo_root="$(realpath "${script_dir}/../..")"
src_dir="${repo_root}/src"

python - <<'PY' "${repo_root}" "${src_dir}"
from pathlib import Path
import re
import sys

repo_root = Path(sys.argv[1])
src_dir = Path(sys.argv[2])
fail = 0

allowed_feature_imports = {
    '../features/ai',
    '../features/bar',
    '../features/color-picker',
    '../features/control-center',
    '../features/display',
    '../features/launcher',
    '../features/lock',
    '../features/media',
    '../features/osd',
    '../features/notifications',
    '../features/power',
    '../features/settings',
    '../features/system/surfaces',
    '../features/workspace',
    '../system/sections',
    '../../system/sections',
    '../../../system/sections',
    '../shell',
    '../services/AiProviders.js',
    '../../services/ColorUtils.js',
    '../../services/ShellUtils.js',
    '../system/sections',
    '../settings/components',
    '../../features/settings/components',
    '../../../features/settings/components',
    '../../services',
    '../../shared',
    '../../../services',
    '../../../shared',
    '../../widgets',
    '../../../widgets',
    '../../../../services',
    '../../../../services/ColorUtils.js',
    '../../../../widgets',
    '../../../../services/ShellUtils.js',
    '../../menu/settings',
    '../../../menu/settings',
    '../../../services/ShellUtils.js',
    '../../../modules',
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
    '../../../../features/ai/services/AiProviderProfiles.js',
    '../../../../launcher/LauncherModeData.js',
    '../../../../services/IconHelpers.js',
    '../../../../shared',
    '../../../background',
    '../../../bar/VerticalWidgetPolicy.js',
    '../../../services/IconHelpers.js',
    '../../../services/PopupAnchorUtils.js',
    '../../../widgets/ssh-settings',
    '../../services/ClipboardDisplayHelpers.js',
    '../../services/IconHelpers.js',
    '../../services/SearchUtils.js',
    '../../settings/components/SettingsReorderHelpers.js',
    '../BatteryHelpers.js',
    '../VpnHelpers.js',
    '../models/GraphUtils.js',
    '../models/SystemCardStyle.js',
    '../pomodoro',
    '../todo',
}

forbidden_legacy_feature_imports = {
    '../bar',
    '../launcher',
    '../menu',
    '../notifications',
    '../services',
    '../widgets',
}

import_re = re.compile(r'^\s*import\s+"([^"]+)"', re.MULTILINE)
compat_path_re = re.compile(r'(?:source\s*:\s*"[^"]*(?:menu/settings|menu|widgets)/|Qt\.resolvedUrl\(".*(?:menu/settings|menu|widgets)/)')

legacy_config_dir = repo_root / 'config'
if legacy_config_dir.exists():
    print(f'check-import-boundaries: legacy runtime mirror still present at {legacy_config_dir}', file=sys.stderr)
    fail = 1

migrated_roots = (
    src_dir / 'app',
    src_dir / 'features' / 'ai',
    src_dir / 'features' / 'audio',
    src_dir / 'features' / 'bar',
    src_dir / 'features' / 'clipboard',
    src_dir / 'features' / 'color-picker',
    src_dir / 'features' / 'control-center',
    src_dir / 'features' / 'desktop',
    src_dir / 'features' / 'display',
    src_dir / 'features' / 'launcher',
    src_dir / 'features' / 'dock',
    src_dir / 'features' / 'media',
    src_dir / 'features' / 'network',
    src_dir / 'features' / 'notifications',
    src_dir / 'features' / 'power',
    src_dir / 'features' / 'screenshot',
    src_dir / 'features' / 'settings',
    src_dir / 'features' / 'ssh',
    src_dir / 'features' / 'status',
    src_dir / 'features' / 'system',
    src_dir / 'features' / 'system' / 'surfaces',
    src_dir / 'features' / 'time',
    src_dir / 'features' / 'workspace',
    src_dir / 'features' / 'lock',
    src_dir / 'features' / 'osd',
)

for root in migrated_roots:
    if not root.exists():
        continue
    paths = root.rglob('*.qml')
    for path in paths:
        rel_parts = path.relative_to(src_dir).parts
        is_feature_file = len(rel_parts) > 0 and rel_parts[0] == 'features'
        text = path.read_text()
        for match in import_re.finditer(text):
            target = match.group(1)
            if target.startswith('root:'):
                print(f'check-import-boundaries: forbidden root import in {path}: {target}', file=sys.stderr)
                fail = 1
            if is_feature_file and target in forbidden_legacy_feature_imports:
                print(f'check-import-boundaries: forbidden legacy feature import in {path}: {target}', file=sys.stderr)
                fail = 1
            if is_feature_file and target.startswith('../') and target not in allowed_feature_imports:
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
    if compat_path_re.search(text):
        print(f'check-import-boundaries: forbidden compatibility file-path load in {path}', file=sys.stderr)
        fail = 1

for path in (repo_root / 'scripts').rglob('*'):
    if not path.is_file():
        continue
    if path.suffix not in {'.sh', '.py', '.js'}:
        continue
    text = path.read_text()
    if compat_path_re.search(text):
        print(f'check-import-boundaries: forbidden compatibility file-path load in {path}', file=sys.stderr)
        fail = 1

for module in (
    src_dir / 'app',
    src_dir / 'features' / 'ai',
    src_dir / 'features' / 'audio',
    src_dir / 'features' / 'bar',
    src_dir / 'features' / 'clipboard',
    src_dir / 'features' / 'color-picker',
    src_dir / 'features' / 'control-center',
    src_dir / 'features' / 'desktop',
    src_dir / 'features' / 'display',
    src_dir / 'features' / 'launcher',
    src_dir / 'features' / 'dock',
    src_dir / 'features' / 'media',
    src_dir / 'features' / 'network',
    src_dir / 'features' / 'notifications',
    src_dir / 'features' / 'power',
    src_dir / 'features' / 'screenshot',
    src_dir / 'features' / 'settings',
    src_dir / 'features' / 'ssh',
    src_dir / 'features' / 'status',
    src_dir / 'features' / 'system',
    src_dir / 'features' / 'system' / 'sections',
    src_dir / 'features' / 'system' / 'surfaces',
    src_dir / 'features' / 'time',
    src_dir / 'features' / 'workspace',
):
    if not (module / 'qmldir').exists():
        print(f'check-import-boundaries: missing qmldir in {module}', file=sys.stderr)
        fail = 1

raise SystemExit(fail)
PY
