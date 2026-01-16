# Yazi Plugins

This directory contains custom Yazi plugins used in this NixOS configuration. Plugins from `pkgs.yaziPlugins.*` are not included here as they are managed by Nix packages.

## Local Plugins

### `arrow.yazi`
**Type:** Entry Plugin
**Purpose:** Navigation wrapper that allows cursor movement to wrap around at the top/bottom of the file list.
**Usage:** Bound to `j`/`k` keys for down/up navigation with wraparound.

### `enhanced-preview.yazi`
**Type:** Preview Plugin
**Purpose:** Enhanced file preview with support for multiple file types:
- **Directories:** Uses `eza` to show tree view (3 levels deep)
- **Images:** Displays image with `ueberzug` and shows EXIF metadata overlay using `exiftool`
- **Text files:** Syntax-highlighted preview using `bat` (up to 500 lines)
- **PDFs:** Text extraction preview using `pdftotext`
- **Fallback:** Uses `file` command for unknown types

**Features:**
- Skips files larger than 10MB
- Optimized previews for different MIME types
- Metadata overlays for images

### `excel.yazi`
**Type:** Preview Plugin
**Purpose:** Preview Excel/Spreadsheet files (`.xlsx`) by converting them to CSV format using `xlsx2csv`.
**Features:**
- Supports scrolling through large spreadsheets
- Handles empty cells and columns gracefully
- Tab-to-space conversion for proper display

### `eza-preview.yazi`
**Type:** Preview Plugin
**Purpose:** Directory preview using `eza` with toggleable tree/list view modes.
**Features:**
- Toggle between tree and list view modes
- Configurable tree depth (default: 3 levels)
- Options to follow symlinks and dereference
- Color and icon support
- Group directories first

**Usage:** Bound to `E` key to toggle tree/list directory preview.

### `folder-rules.yazi`
**Type:** Setup Plugin
**Purpose:** Automatically applies sorting rules based on the current directory.
**Behavior:**
- **Downloads folder:** Sorts by modified time (newest first), directories not prioritized
- **Other folders:** Sorts alphabetically, directories first

**Note:** Automatically triggers when changing directories.

### `fzfbm.yazi`
**Type:** Entry Plugin
**Purpose:** Fuzzy finder bookmark manager for Yazi. Allows you to bookmark frequently accessed directories and files.
**Features:**
- Add/remove bookmarks
- Fuzzy search through bookmarks
- Persistent storage
- Sortable bookmarks

### `hexyl.yazi`
**Type:** Preview Plugin
**Purpose:** Preview binary files in hexadecimal format using `hexyl`.
**Features:**
- Hex dump display with ASCII representation
- Supports scrolling through large binary files
- Borderless mode for terminal width optimization
- Falls back to code preview for empty files

### `max-preview.yazi`
**Type:** Entry Plugin
**Purpose:** Maximizes the preview pane by hiding the parent and current directory panes, giving full screen to the preview.
**Usage:** Bound to `T` key to toggle maximize/restore preview pane.

**Behavior:**
- First call: Hides parent and current panes, shows only preview
- Second call: Restores original layout

### `parent-arrow.yazi`
**Type:** Entry Plugin
**Purpose:** Navigate to directories in the parent pane. Allows moving the cursor in the parent directory view and entering subdirectories.
**Usage:** Used with arrow navigation to move between parent directory entries.

### `preview.yazi`
**Type:** Preview Plugin
**Purpose:** General-purpose preview plugin that delegates to an external shell script (`preview.sh`) for file preview logic.
**Features:**
- Supports image previews with split view (image on top, metadata/text below)
- Handles various file types through external script
- Supports scrolling and offset management
- Can disable auto-peek for certain file types

**Dependencies:** Requires `preview.sh` script in the same directory.

### `yatline.yazi`
**Type:** Status Line Plugin
**Purpose:** Custom status line/header for Yazi tabs showing:
- Current mode (normal/select/unset)
- Current directory path
- File count and selection status
- Task progress indicators
- Tab information

**Features:**
- Customizable sections and styling
- Mode-aware color coding
- Permission indicators
- Task status icons
- Tab width management

**Note:** This is a local version with the `ya.truncate` → `ui.truncate` deprecation fix applied.

## Plugins from Nix Packages

The following plugins are provided by `pkgs.yaziPlugins.*` and are not stored in this directory:

- **`chmod`** - Change file permissions interactively
- **`lazygit`** - Git integration with lazygit
- **`mediainfo`** - Media file metadata display
- **`ouch`** - Archive operations (extract, list, etc.)
- **`piper`** - Pipe command output to Yazi
- **`smart-enter`** - Smart enter behavior (enter dir, open file)
- **`smart-filter`** - Enhanced filtering capabilities
- **`smart-paste`** - Smart paste into hovered directory
- **`yatline-catppuccin`** - Catppuccin theme variant for yatline

## Plugin Development

To add a new plugin:

1. Create a new directory: `your-plugin.yazi/`
2. Add `main.lua` with your plugin code
3. Reference it in `default.nix`:
   ```nix
   plugins = {
     your-plugin = ./plugins/your-plugin.yazi;
   };
   ```

For more information on Yazi plugin development, see the [Yazi documentation](https://yazi-rs.github.io/docs/plugins/overview).

