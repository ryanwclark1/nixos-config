import os
import re

base_path = "/home/administrator/nixos-config/home/features/desktop/window-managers/shared/panel/quickshell/config"
subdirs = ["bar", "launcher", "menu", "modules", "notifications", "services", "widgets"]

components_mapping = {
    "CenterModules": "bar",
    "Logo": "bar",
    "NotificationsIndicator": "bar",
    "Panel": "bar",
    "Taskbar": "bar",
    "WindowTitle": "bar",
    "Workspaces": "bar",
    "WorkspaceStrip": "bar",
    "Launcher": "launcher",
    "Overview": "launcher",
    "BluetoothMenu": "menu",
    "ControlCenter": "menu",
    "HyprActions": "menu",
    "NotificationCenter": "menu",
    "ActionButton": "modules",
    "Calendar": "modules",
    "MediaWidget": "modules",
    "SystemGraphs": "modules",
    "SystemMonitor": "modules",
    "WeatherWidget": "modules",
    "NotificationManager": "notifications",
    "Notifications": "notifications",
    "Colors": "services",
    "HyprlandState": "services",
    "Theme": "services",
    "ActivateLinux": "widgets",
    "AudioWidget": "widgets",
    "BatteryWidget": "widgets",
    "Dock": "widgets",
    "KeyboardLayout": "widgets",
    "MediaOsd": "widgets",
    "NetworkWidget": "widgets",
    "Osd": "widgets",
    "ScratchpadIndicator": "widgets",
    "TrayWidget": "widgets",
    "WorkspaceOsd": "widgets"
}

# Add some specific mentions from the prompt
# "Specifically, Workspaces.qml and Panel.qml are in bar/. MediaWidget.qml is in modules/. ControlCenter.qml is in menu/."
# My mapping covers this.

updated_files = []

for subdir in subdirs:
    dir_path = os.path.join(base_path, subdir)
    if not os.path.exists(dir_path):
        continue
    
    for filename in os.listdir(dir_path):
        if not filename.endswith(".qml"):
            continue
        
        file_path = os.path.join(dir_path, filename)
        with open(file_path, "r") as f:
            lines = f.readlines()
        
        content = "".join(lines)
        needed_imports = set()
        
        # Check for Colors usage
        if "Colors." in content or "Colors " in content:
            needed_imports.add("services")
        
        # Check for other components usage
        for comp, comp_subdir in components_mapping.items():
            # Match component name as a whole word, followed by { or used as a type
            if re.search(r'\b' + comp + r'\b', content):
                if comp_subdir != subdir:
                    needed_imports.add(comp_subdir)
        
        # Find where the imports end
        import_end_idx = 0
        existing_imports = set()
        for i, line in enumerate(lines):
            line_strip = line.strip()
            if line_strip.startswith("import "):
                import_end_idx = i + 1
                # Capture the import path
                match = re.search(r'import\s+"([^"]+)"', line_strip)
                if match:
                    existing_imports.add(match.group(1))

        # Filter out self and existing
        to_add = []
        for imp in sorted(needed_imports):
            if f"../{imp}" not in existing_imports:
                to_add.append(f'import "../{imp}"\n')
        
        # Replace "import components" if it exists (it was found not to, but let's be safe)
        # Or if "import '..'" exists
        # Actually let's just insert after existing imports
        
        if to_add:
            # Insert after the last import
            for stmt in to_add:
                lines.insert(import_end_idx, stmt)
                import_end_idx += 1
            
            with open(file_path, "w") as f:
                f.writelines(lines)
            updated_files.append(file_path)

print(f"Updated {len(updated_files)} files:")
for f in updated_files:
    print(f"  {f}")
