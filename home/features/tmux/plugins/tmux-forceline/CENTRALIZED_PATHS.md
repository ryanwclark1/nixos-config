# Centralized Path Management

tmux-forceline now provides centralized path management to eliminate hardcoded paths and improve portability.

## How It Works

### 1. Root Directory Setup (forceline.tmux)
```bash
# Set global tmux option for forceline root directory
set -g @forceline_dir "#{d:current_file}"
```

### 2. Helper Function (Available in all modules)
```bash
# Get forceline root directory from centralized tmux option
get_forceline_dir() {
  local forceline_dir
  forceline_dir="$(get_tmux_option "@forceline_dir" "")"
  if [ -n "$forceline_dir" ]; then
    echo "$forceline_dir"
  else
    # Fallback to legacy method if option not set
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  fi
}
```

## Usage Examples

### In Module Scripts (RECOMMENDED APPROACH)
```bash
#!/usr/bin/env bash

# Source centralized utilities and path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    # shellcheck source=../../../utils/common.sh
    source "$UTILS_DIR/common.sh"
    
    # Use centralized path functions
    FORCELINE_DIR="$(get_forceline_dir)"
    MODULES_DIR="$(get_forceline_modules_dir)"
    THEMES_DIR="$(get_forceline_themes_dir)"
    
    # Access specific paths
    HELPERS_PATH="$(get_forceline_path "modules/cpu/scripts/helpers.sh")"
    source "$HELPERS_PATH"
else
    # Fallback for legacy approach
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/helpers.sh"
fi
```

### Available Centralized Path Functions
```bash
# Get forceline root directory
get_forceline_dir()               # Returns: /path/to/tmux-forceline

# Get common subdirectories  
get_forceline_modules_dir()       # Returns: /path/to/tmux-forceline/modules
get_forceline_utils_dir()         # Returns: /path/to/tmux-forceline/utils
get_forceline_themes_dir()        # Returns: /path/to/tmux-forceline/themes

# Get any path relative to forceline root
get_forceline_path "themes/yaml"  # Returns: /path/to/tmux-forceline/themes/yaml
get_forceline_path "modules/cpu"  # Returns: /path/to/tmux-forceline/modules/cpu

# Deprecated function (for backward compatibility)
get_current_script_dir()          # Returns current script directory (legacy)
```

### In Configuration Files
```bash
# Instead of hardcoded paths:
# source -F "#{d:current_file}/../../utils/common.sh"
# run-shell "/home/user/.config/tmux/plugins/tmux-forceline/modules/cpu/cpu.sh"

# Use centralized paths:
source -F "#{@forceline_dir}/utils/common.sh"
run-shell "#{@forceline_dir}/modules/cpu/cpu.sh"
```

### In Plugin Configurations
```bash
# Load module using centralized path
run-shell "#{@forceline_dir}/modules/memory/memory.sh"

# Source utilities using centralized path
source -F "#{@forceline_dir}/utils/status_module.conf"

# Execute scripts using centralized path
set -ogq "@forceline_memory_text" " #{@forceline_dir}/modules/memory/scripts/memory_percentage.sh"
```

## Benefits

1. **Eliminates Code Duplication**: Removes 68+ instances of `CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
2. **Improved Maintainability**: Single source of truth for all path calculations
3. **Enhanced Portability**: No hardcoded paths, works regardless of installation location
4. **Better Error Handling**: Centralized path functions include proper error checking
5. **Consistent API**: Standardized function names and behavior across all modules
6. **Debugging Support**: Built-in logging for path resolution issues
7. **Future-Proof**: Easy to extend with new path helper functions

## Migration Strategy

### Phase 1: Legacy Support (Current)
- All centralized path functions implemented in `utils/common.sh`
- Fallback support maintains compatibility with existing `CURRENT_DIR` approach
- No breaking changes to existing functionality

### Phase 2: Gradual Migration (Recommended)
Replace the pattern:
```bash
# OLD APPROACH (68+ instances)
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"
OTHER_PATH="$CURRENT_DIR/../../../other/path"
```

With the centralized approach:
```bash
# NEW APPROACH (centralized)
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
    HELPERS_PATH="$(get_forceline_path "modules/current/scripts/helpers.sh")"
    source "$HELPERS_PATH"
    OTHER_PATH="$(get_forceline_path "other/path")"
else
    # Fallback maintains compatibility
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/helpers.sh"
    OTHER_PATH="$CURRENT_DIR/../../../other/path"
fi
```

### Phase 3: Full Migration
- Update all 68+ files to use centralized path management
- Remove legacy `CURRENT_DIR` calculations
- Simplify path logic across entire codebase

## Available Locations

- `@forceline_dir` - tmux option containing root directory
- `get_forceline_dir()` - helper function (in common.sh and module helpers)
- Fallback support for legacy path calculation