# Centralized tmux Option Functions

This document describes the robust, centralized tmux option functions that replace the 37+ scattered implementations across the codebase.

## Problem Solved

**Before**: 37 different implementations of `get_tmux_option()` with inconsistent:
- Error handling
- Scope behavior (-qv vs -gqv)
- Fallback strategies
- Input validation

**After**: Single robust implementation with comprehensive error handling and smart scope detection.

## Available Functions

### `get_tmux_option(option, [default], [scope])`

Robust option retrieval with smart scope detection and error handling.

**Parameters:**
- `option` (required): tmux option name
- `default` (optional): fallback value if option not found
- `scope` (optional): "session", "global", "auto" (default)

**Scope Behavior:**
- `"session"`: Try session first, then global
- `"global"`: Global scope only  
- `"auto"`: Smart detection (global for @forceline_*, session+global fallback for others)

**Return Codes:**
- `0`: Option found and returned
- `1`: Error (invalid parameters, tmux unavailable)
- `2`: Default value used (option not found)

**Examples:**
```bash
# Basic usage (auto scope)
value=$(get_tmux_option "@forceline_theme" "default")

# Explicit global scope
value=$(get_tmux_option "status-left" "" "global")

# Session scope with fallback
value=$(get_tmux_option "window-status-format" "#I:#W" "session")

# Check return code
if get_tmux_option "@forceline_debug" "no" "auto" >/dev/null; then
    echo "Option exists"
fi
```

### `set_tmux_option(option, value, [scope], [flags])`

Robust option setting with scope control and additional flags.

**Parameters:**
- `option` (required): tmux option name
- `value` (required): value to set
- `scope` (optional): "session", "global" (default), "auto"
- `flags` (optional): additional tmux flags (e.g., "-a" for append)

**Examples:**
```bash
# Basic setting (global scope)
set_tmux_option "@forceline_theme" "catppuccin"

# Session scope
set_tmux_option "status-left" "#S " "session"

# Append to existing value
set_tmux_option "@forceline_plugins" ",gpu" "global" "-a"

# Auto scope (global for @forceline_*, session for others)
set_tmux_option "@forceline_debug" "yes" "auto"
```

### `tmux_option_exists(option)`

Check if option exists in any scope.

**Examples:**
```bash
if tmux_option_exists "@forceline_theme"; then
    echo "Theme is configured"
fi
```

### `unset_tmux_option(option, [scope])`

Remove/unset tmux option.

**Scope Options:**
- `"session"`: Remove from session scope
- `"global"`: Remove from global scope (default)
- `"both"`: Remove from both scopes

**Examples:**
```bash
# Remove global option
unset_tmux_option "@forceline_old_option"

# Remove from both scopes
unset_tmux_option "status-left" "both"
```

## Migration Guide

### Step 1: Source Central Functions

**Instead of local implementation:**
```bash
get_tmux_option() {
    local option="$1"
    local default="$2"
    tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
}
```

**Use central functions:**
```bash
# Source centralized utilities
FORCELINE_DIR="$(get_forceline_dir)"
source "$FORCELINE_DIR/utils/common.sh"

# Functions now available: get_tmux_option, set_tmux_option, etc.
```

### Step 2: Update Function Calls

**Old inconsistent calls:**
```bash
theme=$(tmux show-option -gqv "@forceline_theme" 2>/dev/null || echo "default")
option_value="$(tmux show-option -qv "$option")"
if [ -z "$option_value" ]; then
    option_value="$(tmux show-option -gqv "$option")"
fi
```

**New centralized calls:**
```bash
theme=$(get_tmux_option "@forceline_theme" "default")
option_value=$(get_tmux_option "$option" "" "session")
```

### Step 3: Remove Local Implementations

Delete local `get_tmux_option()` function definitions and replace calls with centralized versions.

## Benefits

1. **Consistency**: All modules use identical tmux option handling
2. **Robustness**: Comprehensive error handling and input validation
3. **Maintainability**: Single source of truth for tmux option logic
4. **Smart Scope**: Auto-detection for optimal scope selection
5. **Backward Compatibility**: Existing calls continue to work
6. **Debugging**: Built-in logging for troubleshooting
7. **Future-Proof**: Easy to extend with new features

## Advanced Features

### Smart Scope Detection
- `@forceline_*` options automatically use global scope
- Other options try session first, then global
- Automatic fallback when not in tmux session

### Error Handling
- Input validation with informative warnings
- tmux availability checking
- Session context detection
- Graceful degradation

### Logging Integration
- Debug logs for option retrieval/setting
- Warning logs for failures
- Configurable via `FL_DEBUG` environment variable

## Implementation Status

✅ **Centralized functions implemented** in `utils/common.sh`
✅ **Comprehensive error handling** and input validation
✅ **Smart scope detection** for optimal behavior
✅ **Backward compatibility** helpers
📋 **Migration needed**: 37 modules need to adopt centralized functions