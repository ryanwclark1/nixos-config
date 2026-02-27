# Rofi Scripts Review

## Overview
Comprehensive review of rofi menu scripts for NixOS configuration.

## Critical Issues

### 1. Security: `eval` Usage in `rofi-apps-unified.sh`
**Location**: Lines 127-151
**Risk**: Medium (commands are hardcoded, but `eval` is still risky)
**Recommendation**: Replace `eval` with direct command execution

**Current**:
```bash
eval "$CMD_TERMINAL" &
```

**Recommended**:
```bash
# Store commands as arrays or execute directly
case "$CHOICE" in
    "$APP_TERMINAL")
        if [[ "$MODE" == "root" ]]; then
            pkexec env PATH="$PATH" WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
                XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" kitty &
        else
            kitty &
        fi
        ;;
```

### 2. Hardcoded Paths
**Location**: `rofi-apps-unified.sh:101`
**Issue**: Assumes Hyprland-specific path structure
**Fix**: Use script-relative paths or environment variables

```bash
# Instead of:
CMD_SETTINGS="$HOME/.config/hypr/scripts/rofi/settings-menu.sh"

# Use:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CMD_SETTINGS="$SCRIPT_DIR/settings-menu.sh"
# Or check for existence first
```

### 3. Missing Error Handling
**Affected Scripts**: `rofi-quicklinks.sh`, `settings-menu.sh`, `rofi-system-menu.sh`

**Example Issue** (`rofi-quicklinks.sh:14`):
```bash
mesg="Using '$BROWSER' as web browser"
```
If `$BROWSER` is unset, this shows "Using '' as web browser"

**Fix**:
```bash
BROWSER="${BROWSER:-firefox}"  # Default fallback
mesg="Using '$BROWSER' as web browser"
```

### 4. Inconsistent Shell Safety
**Good Example**: `rofi-web-search.sh` uses `set -euo pipefail`
**Bad Examples**: Most other scripts lack this

**Recommendation**: Add to all scripts:
```bash
#!/usr/bin/env bash
set -euo pipefail
```

### 5. Portability Issues
**Location**: `rofi-code.sh:51`
**Issue**: Uses GNU-specific `stat -c`
**Fix**: Use portable alternatives or check for availability

```bash
# Instead of:
stat -c %Y "$folder"

# Use:
if command -v stat >/dev/null; then
    # Try GNU stat first
    stat -c %Y "$folder" 2>/dev/null || \
    # Fallback to BSD stat
    stat -f %m "$folder" 2>/dev/null || \
    # Fallback to find
    find "$folder" -printf '%T@' 2>/dev/null || echo 0
else
    echo 0
fi
```

## Medium Priority Issues

### 6. Command Availability Checks
**Location**: Multiple scripts
**Issue**: Commands executed without checking availability
**Good Example**: `rofi-system-menu.sh` checks with `command -v`
**Bad Example**: `rofi-quicklinks.sh` doesn't check `xdg-open`

**Recommendation**: Add checks before execution:
```bash
if ! command -v xdg-open >/dev/null; then
    notify-send "Error" "xdg-open not found" 2>/dev/null || echo "Error: xdg-open not found" >&2
    exit 1
fi
```

### 7. Inconsistent Theme Handling
**Location**: Multiple scripts
**Issue**: Different approaches to theme configuration

- `rofi-apps-unified.sh`: Uses environment variables with defaults
- `rofi-system-menu.sh`: Hardcoded theme path
- `system-menu-rofi.sh`: Hardcoded theme name

**Recommendation**: Standardize on environment variables with sensible defaults

### 8. Missing Input Validation
**Location**: `rofi-code.sh`, `rofi-web-search.sh`
**Issue**: Some scripts validate, others don't

**Example**: `rofi-code.sh` doesn't validate workspace paths exist before opening

## Low Priority / Style Issues

### 9. Inconsistent Formatting
- Mixed use of tabs vs spaces
- Inconsistent spacing around operators
- Some scripts use `[[ ]]`, others use `[ ]`

**Recommendation**: Use `[[ ]]` consistently (bash-specific, but all scripts use bash)

### 10. Missing Documentation
**Good Example**: `rofi-web-search.sh` has comprehensive header
**Bad Examples**: `rofi-capture.sh`, `rofi-power.sh` are just wrappers with no docs

**Recommendation**: Add brief headers explaining purpose

### 11. Magic Numbers
**Location**: `rofi-quicklinks.sh`, `rofi-apps-unified.sh`
**Issue**: Hardcoded column/row counts

**Recommendation**: Extract to named variables at top of script

## Recommendations Summary

### High Priority
1. ✅ Remove `eval` from `rofi-apps-unified.sh`
2. ✅ Fix hardcoded paths to use script-relative or configurable paths
3. ✅ Add `set -euo pipefail` to all scripts
4. ✅ Add error handling for command execution failures

### Medium Priority
5. ✅ Standardize command availability checks
6. ✅ Fix portability issues (GNU-specific commands)
7. ✅ Add input validation where missing
8. ✅ Standardize theme configuration approach

### Low Priority
9. ✅ Add documentation headers to wrapper scripts
10. ✅ Standardize code formatting
11. ✅ Extract magic numbers to named constants

## Script-Specific Notes

### `rofi-web-search.sh` ⭐
**Status**: Excellent
**Notes**: Best practices example - use as reference for other scripts

### `rofi-apps-unified.sh`
**Priority Fixes**:
- Remove `eval` usage
- Fix hardcoded path on line 101
- Add error handling

### `rofi-code.sh`
**Priority Fixes**:
- Fix `stat -c` portability issue
- Add workspace path validation
- Better error handling for jq failures

### `rofi-quicklinks.sh`
**Priority Fixes**:
- Check `$BROWSER` variable
- Add command availability checks
- Fix theme parsing (line 31 uses `cat` unnecessarily)

### `rofi-system-menu.sh` & `system-menu-rofi.sh`
**Notes**: Two similar scripts - consider consolidating or clearly documenting differences

### Wrapper Scripts
**Files**: `rofi-capture.sh`, `rofi-power.sh`, `rofi-settings.sh`
**Recommendation**: Add brief documentation explaining they're wrappers

### `mpd-menu.sh`
**Status**: Good
**Minor**: Could add better error handling for MPD connection failures

## Testing Recommendations

1. Test all scripts with missing dependencies
2. Test with unset environment variables
3. Test theme file missing scenarios
4. Test on non-Hyprland systems (where applicable)
5. Test with special characters in paths/names

## Code Quality Metrics

- **Scripts with `set -euo pipefail`**: 1/12 (8%)
- **Scripts with error handling**: 3/12 (25%)
- **Scripts with input validation**: 2/12 (17%)
- **Scripts with documentation**: 2/12 (17%)

**Target**: 100% for all metrics
