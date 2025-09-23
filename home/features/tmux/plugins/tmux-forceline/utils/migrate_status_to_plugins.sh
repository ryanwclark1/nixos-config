#!/usr/bin/env bash
# Migration script from status system to plugin system
# tmux-forceline v3.0 consolidation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_FORCELINE_DIR="$(dirname "$SCRIPT_DIR")"
STATUS_DIR="$TMUX_FORCELINE_DIR/status"
BACKUP_DIR="$TMUX_FORCELINE_DIR/status.backup.$(date +%Y%m%d_%H%M%S)"

echo "🔄 tmux-forceline Status to Plugin Migration"
echo "============================================"

# Check if status directory exists
if [[ ! -d "$STATUS_DIR" ]]; then
    echo "✅ No status directory found - migration not needed."
    exit 0
fi

# Create backup
echo "📦 Creating backup at: $BACKUP_DIR"
cp -r "$STATUS_DIR" "$BACKUP_DIR"

# Analyze current status modules
echo ""
echo "📊 Analyzing status modules..."
status_modules=()
while IFS= read -r -d '' file; do
    module_name=$(basename "$file" .conf)
    status_modules+=("$module_name")
done < <(find "$STATUS_DIR" -name "*.conf" -print0)

echo "Found ${#status_modules[@]} status modules: ${status_modules[*]}"

# Check for conflicts with existing plugins
conflicts=()
migrated=()
need_creation=()

for module in "${status_modules[@]}"; do
    if [[ -f "$TMUX_FORCELINE_DIR/plugins/core/$module/$module.conf" ]] || 
       [[ -f "$TMUX_FORCELINE_DIR/plugins/extended/$module/$module.conf" ]]; then
        conflicts+=("$module")
    elif [[ "$module" == "session" ]] || [[ "$module" == "directory" ]]; then
        migrated+=("$module")
    else
        need_creation+=("$module")
    fi
done

echo ""
echo "📋 Migration Status:"
echo "==================="

if [[ ${#conflicts[@]} -gt 0 ]]; then
    echo "⚠️  Conflicting modules (plugin exists, will use plugin version):"
    for module in "${conflicts[@]}"; do
        echo "   - $module"
    done
fi

if [[ ${#migrated[@]} -gt 0 ]]; then
    echo "✅ Already migrated modules:"
    for module in "${migrated[@]}"; do
        echo "   - $module"
    done
fi

if [[ ${#need_creation[@]} -gt 0 ]]; then
    echo "🔨 Modules needing plugin creation:"
    for module in "${need_creation[@]}"; do
        echo "   - $module"
    done
fi

# Generate recommended plugin configuration
echo ""
echo "🔧 Recommended Plugin Configuration:"
echo "==================================="

# Build plugin list from available plugins
available_plugins=()
for module in "${status_modules[@]}"; do
    if [[ -f "$TMUX_FORCELINE_DIR/plugins/core/$module/$module.conf" ]] || 
       [[ -f "$TMUX_FORCELINE_DIR/plugins/extended/$module/$module.conf" ]] ||
       [[ "$module" == "session" ]] || [[ "$module" == "directory" ]]; then
        available_plugins+=("$module")
    fi
done

echo ""
echo "Add this to your tmux configuration:"
echo ""
echo "# tmux-forceline v3.0 - Plugin-based configuration"
echo "set -g @forceline_plugins \"$(IFS=,; echo "${available_plugins[*]}")\""
echo ""

# Create warnings for deprecated status usage
echo "⚠️  Status system is deprecated. Update your configuration to use:"
echo "   - Plugin system: set -g @forceline_plugins \"...\""
echo "   - Remove any @forceline_status_* variables"
echo ""

# Option to remove status directory
echo "🗑️  Status directory backed up to: $(basename "$BACKUP_DIR")"
echo ""
read -p "Remove deprecated status directory? [y/N]: " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$STATUS_DIR"
    echo "✅ Status directory removed"
else
    echo "📁 Status directory preserved (deprecated)"
fi

echo ""
echo "🎉 Migration completed!"
echo ""
echo "Next steps:"
echo "1. Update your tmux configuration to use the plugin system"
echo "2. Restart tmux: tmux kill-server && tmux"
echo "3. Verify everything works correctly"
echo "4. Remove backup directory when satisfied: rm -rf $BACKUP_DIR"