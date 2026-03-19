#!/usr/bin/env python3
"""
Parse niri config.kdl to extract keybinds for cheatsheet display.
Outputs JSON with categorized keybinds.
"""

import json
import os
import re
import sys
from pathlib import Path


def get_niri_config_path():
    xdg_config = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    return Path(xdg_config) / "niri" / "config.kdl"


def parse_binds_from_block(binds_content: str) -> list[dict]:
    results = []
    lines = binds_content.split('\n')
    i = 0

    while i < len(lines):
        line = lines[i].strip()

        if not line or line.startswith('//'):
            i += 1
            continue

        match = re.match(r'^([A-Za-z0-9+_]+)\s*(.*?)(\{.*)$', line)
        if not match:
            i += 1
            continue

        combo = match.group(1)
        options = match.group(2).strip()
        rest = match.group(3)

        title_match = re.search(r'hotkey-overlay-title="([^"]+)"', options)
        overlay_title = title_match.group(1) if title_match else None

        if re.search(r'\{[^}]+\}', rest):
            action_match = re.search(r'\{\s*([^}]+)\s*\}', rest)
            action = action_match.group(1).strip().rstrip(';') if action_match else ''
        else:
            action_lines = []
            i += 1
            while i < len(lines):
                inner_line = lines[i].strip()
                if inner_line == '}':
                    break
                if inner_line and not inner_line.startswith('//'):
                    action_lines.append(inner_line.rstrip(';'))
                i += 1
            action = ' '.join(action_lines)

        parts = combo.split('+')
        mods = []
        shortcut = parts[-1]

        for part in parts[:-1]:
            if part in ('Mod', 'Super'):
                mods.append('Super')
            elif part in ('Alt', 'Shift', 'Ctrl'):
                mods.append(part)
            else:
                mods.append(part)

        if shortcut.startswith('XF86Audio'):
            shortcut = shortcut.replace('XF86Audio', '').replace('RaiseVolume', 'Vol+').replace('LowerVolume', 'Vol-')
        elif shortcut.startswith('XF86MonBrightness'):
            shortcut = shortcut.replace('XF86MonBrightness', 'Brightness').replace('Up', '+').replace('Down', '-')
        elif shortcut.startswith('XF86'):
            shortcut = shortcut.replace('XF86', '')

        comment = overlay_title if overlay_title else generate_comment(action)

        results.append({
            'mods': mods,
            'key': shortcut,
            'action': action,
            'comment': comment
        })

        i += 1

    return results


ACTION_MAP = {
    'toggle-overview': 'Niri Overview',
    'quit': 'Quit Niri',
    'toggle-keyboard-shortcuts-inhibit': 'Toggle shortcuts inhibit',
    'power-off-monitors': 'Power off monitors',
    'show-hotkey-overlay': 'Hotkey overlay',
    'close-window': 'Close window',
    'maximize-column': 'Maximize column',
    'fullscreen-window': 'Fullscreen',
    'toggle-window-floating': 'Toggle floating',
    'center-column': 'Center column',
    'consume-or-expel-window-left': 'Consume/expel left',
    'consume-or-expel-window-right': 'Consume/expel right',
    'expel-window-from-column': 'Expel from column',
    'consume-window-into-column': 'Consume into column',
    'focus-column-left': 'Focus left',
    'focus-column-right': 'Focus right',
    'focus-window-up': 'Focus up',
    'focus-window-down': 'Focus down',
    'focus-column-first': 'Focus first column',
    'focus-column-last': 'Focus last column',
    'focus-monitor-left': 'Focus monitor left',
    'focus-monitor-right': 'Focus monitor right',
    'move-column-left': 'Move left',
    'move-column-right': 'Move right',
    'move-window-up': 'Move up',
    'move-window-down': 'Move down',
    'move-column-to-first': 'Move to first',
    'move-column-to-last': 'Move to last',
    'move-column-to-monitor-left': 'Move to monitor left',
    'move-column-to-monitor-right': 'Move to monitor right',
    'focus-workspace-up': 'Previous workspace',
    'focus-workspace-down': 'Next workspace',
    'move-column-to-workspace-up': 'Move to prev workspace',
    'move-column-to-workspace-down': 'Move to next workspace',
    'move-workspace-up': 'Move workspace up',
    'move-workspace-down': 'Move workspace down',
    'screenshot': 'Screenshot',
    'screenshot-screen': 'Screenshot screen',
    'screenshot-window': 'Screenshot window',
    'screenshot-ocr': 'OCR region',
    'screenshot-analyze': 'Analyze with AI',
}

TERMINALS = ['foot', 'kitty', 'alacritty', 'wezterm', 'ghostty', 'konsole', 'gnome-terminal']
FILE_MANAGERS = ['dolphin', 'nautilus', 'thunar', 'nemo', 'pcmanfm', 'ranger']
BROWSERS = ['firefox', 'zen-browser', 'chromium', 'brave', 'vivaldi']


def generate_comment(action: str) -> str:
    action = action.strip()

    if action in ACTION_MAP:
        return ACTION_MAP[action]

    ws_match = re.match(r'(focus-workspace|move-column-to-workspace)\s+(\d+)', action)
    if ws_match:
        ws_action = 'Focus' if 'focus' in ws_match.group(1) else 'Move to'
        return f'{ws_action} workspace {ws_match.group(2)}'

    if action.startswith('spawn'):
        if any(term in action for term in TERMINALS):
            return 'Terminal'
        if any(fm in action for fm in FILE_MANAGERS):
            return 'File manager'
        if any(br in action for br in BROWSERS):
            return 'Browser'

        if 'wpctl' in action:
            if 'set-volume' in action:
                return 'Volume up' if '+' in action else 'Volume down'
            if 'set-mute' in action:
                return 'Mute toggle'

        if 'brightnessctl' in action or 'light' in action:
            return 'Brightness up' if '+' in action or 'inc' in action else 'Brightness down'

        spawn_match = re.search(r'spawn\s+"([^"]+)"', action)
        if spawn_match:
            app = spawn_match.group(1)
            if '/' in app:
                app = app.split('/')[-1]
            return app

    return action[:30] + '...' if len(action) > 30 else action


def categorize_bind(kb: dict) -> str:
    comment = kb['comment'].lower()

    if any(x in comment for x in ['niri overview', 'quit niri', 'inhibit', 'power off', 'hotkey overlay']):
        return 'System'
    if any(x in comment for x in ['clipboard', 'lock screen', 'wallpaper', 'settings', 'cheatsheet']):
        return 'Shell'
    if 'window' in comment and ('next' in comment or 'previous' in comment):
        return 'Window Switcher'
    if any(x in comment for x in ['screenshot', 'ocr', 'image search', 'analyze with ai']):
        return 'Screenshots'
    if any(x in comment for x in ['terminal', 'file manager', 'browser']):
        return 'Applications'
    if any(x in comment for x in ['close', 'maximize', 'fullscreen', 'floating', 'consume', 'expel', 'center']):
        return 'Window Management'
    if 'focus' in comment and 'workspace' not in comment:
        return 'Focus'
    if 'move' in comment and 'workspace' not in comment and 'track' not in comment:
        return 'Move Windows'
    if 'workspace' in comment:
        return 'Workspaces'
    if any(x in comment for x in ['volume', 'mute', 'play', 'pause', 'track', 'audio', 'microphone']):
        return 'Media'
    if 'brightness' in comment:
        return 'Brightness'
    return 'Other'


def find_binds_block(content: str) -> str | None:
    match = re.search(r'\bbinds\s*\{', content)
    if not match:
        return None

    start = match.end()
    depth = 1
    i = start

    while i < len(content) and depth > 0:
        if content[i] == '{':
            depth += 1
        elif content[i] == '}':
            depth -= 1
        i += 1

    return content[start:i-1] if depth == 0 else None


def parse_niri_config(config_path: Path) -> dict:
    if not config_path.exists():
        return {'error': f'Config not found: {config_path}', 'children': []}

    content = config_path.read_text()
    binds_content = find_binds_block(content)
    if not binds_content:
        return {'error': 'No binds block found', 'children': []}

    binds = parse_binds_from_block(binds_content)
    by_category = {}

    for kb in binds:
        category = categorize_bind(kb)
        if category not in by_category:
            by_category[category] = []
        by_category[category].append({
            'mods': kb['mods'],
            'key': kb['key'],
            'comment': kb['comment']
        })

    category_order = [
        'System', 'Shell', 'Window Switcher', 'Screenshots',
        'Applications', 'Window Management', 'Focus', 'Move Windows',
        'Workspaces', 'Media', 'Brightness', 'Other'
    ]

    children = []
    for cat in category_order:
        if cat in by_category and by_category[cat]:
            children.append({
                'name': cat,
                'children': [{'keybinds': by_category[cat]}]
            })

    return {'children': children, 'configPath': str(config_path)}


def main():
    config_path = get_niri_config_path()
    flatten = "--flatten" in sys.argv
    
    # Remove --flatten from args if present to avoid confusing it with config path
    args = [arg for arg in sys.argv[1:] if arg != "--flatten"]
    if args:
        config_path = Path(args[0])

    if not config_path.exists():
        if flatten:
            print("[]")
        else:
            print(json.dumps({'error': f'Config not found: {config_path}', 'children': []}))
        return

    content = config_path.read_text()
    binds_content = find_binds_block(content)
    if not binds_content:
        if flatten:
            print("[]")
        else:
            print(json.dumps({'error': 'No binds block found', 'children': []}))
        return

    binds = parse_binds_from_block(binds_content)

    if flatten:
        flattened = []
        for kb in binds:
            # Clean up mods for display
            display_mods = [m.upper() for m in kb['mods']]
            name = " + ".join(display_mods + [kb['key']])
            
            # Try to split action into disp and args
            action = kb['action']
            disp = ""
            args = ""
            if action:
                parts = action.split(None, 1)
                disp = parts[0]
                args = parts[1] if len(parts) > 1 else ""
            
            flattened.append({
                'name': name,
                'desc': kb['comment'],
                'disp': disp,
                'args': args
            })
        print(json.dumps(flattened))
    else:
        by_category = {}

        for kb in binds:
            category = categorize_bind(kb)
            if category not in by_category:
                by_category[category] = []
            by_category[category].append({
                'mods': kb['mods'],
                'key': kb['key'],
                'comment': kb['comment']
            })

        category_order = [
            'System', 'Shell', 'Window Switcher', 'Screenshots',
            'Applications', 'Window Management', 'Focus', 'Move Windows',
            'Workspaces', 'Media', 'Brightness', 'Other'
        ]

        children = []
        for cat in category_order:
            if cat in by_category and by_category[cat]:
                children.append({
                    'name': cat,
                    'children': [{'keybinds': by_category[cat]}]
                })

        result = {'children': children, 'configPath': str(config_path)}
        print(json.dumps(result))


if __name__ == '__main__':
    main()
