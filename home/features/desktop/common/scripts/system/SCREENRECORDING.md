# Screen Recording Scripts

This directory contains multiple screen recording implementations, each optimized for different use cases.

## Available Scripts

### System Scripts (Advanced Features)

#### `os-cmd-screenrecord.sh`
**Tool:** `gpu-screen-recorder`
**Best for:** Production recordings with audio, webcam overlay, and hardware acceleration

**Features:**
- ✅ Desktop audio capture (`--with-desktop-audio`)
- ✅ Microphone audio capture (`--with-microphone-audio`)
- ✅ Webcam overlay (`--with-webcam`)
- ✅ Hardware-accelerated encoding
- ✅ Waybar integration (indicator updates)
- ✅ Automatic toggle behavior (stops if already recording)
- ❌ Full screen only (no region selection)

**Usage:**
```bash
os-cmd-screenrecord.sh                                    # Start recording
os-cmd-screenrecord.sh --with-desktop-audio               # With desktop audio
os-cmd-screenrecord.sh --with-microphone-audio             # With microphone
os-cmd-screenrecord.sh --with-desktop-audio --with-microphone-audio  # Both audio sources
os-cmd-screenrecord.sh --with-webcam                       # With webcam overlay
os-cmd-screenrecord.sh --stop-recording                   # Force stop
```

**Dependencies:**
- `gpu-screen-recorder` (required)
- `ffplay` (for webcam overlay)
- `hyprctl`, `jq` (for webcam positioning)
- `v4l2-ctl` (for webcam detection)

---

### Wayland Scripts (Universal & Portable)

#### `screenrecord-wayland.sh`
**Tool:** `wl-screenrec` or `wf-recorder` (fallback)
**Best for:** Quick recordings, region selection, maximum portability

**Features:**
- ✅ Region/area selection (`region` mode)
- ✅ Full screen recording (`output`/`fullscreen` mode)
- ✅ Hardware acceleration detection (auto-selects best encoder)
- ✅ Works with any Wayland compositor
- ✅ Lightweight and portable
- ❌ No audio capture
- ❌ No webcam support

**Usage:**
```bash
screenrecord-wayland.sh                    # Interactive region selection
screenrecord-wayland.sh region             # Same as above
screenrecord-wayland.sh output             # Full screen recording
screenrecord-wayland.sh fullscreen         # Alias for output
```

**Dependencies:**
- `wl-screenrec` or `wf-recorder` (at least one required)
- `slurp` (for region selection)

#### `screenrecord-wayland-stop.sh`
Stops any active `wl-screenrec` or `wf-recorder` process.

**Usage:**
```bash
screenrecord-wayland-stop.sh
```

#### `screenrecord-wayland-toggle.sh`
Toggles recording on/off (starts if stopped, stops if running).

**Usage:**
```bash
screenrecord-wayland-toggle.sh
```

---

## Comparison Table

| Feature | `os-cmd-screenrecord.sh` | `screenrecord-wayland.sh` |
|---------|------------------------|---------------------------|
| **Tool** | `gpu-screen-recorder` | `wl-screenrec`/`wf-recorder` |
| **Desktop Audio** | ✅ Yes | ❌ No |
| **Microphone Audio** | ✅ Yes | ❌ No |
| **Webcam Overlay** | ✅ Yes | ❌ No |
| **Region Selection** | ❌ No | ✅ Yes |
| **Hardware Acceleration** | ✅ Yes | ✅ Auto-detected |
| **Waybar Integration** | ✅ Yes | ❌ No |
| **Portability** | ⚠️ Requires gpu-screen-recorder | ✅ Universal |
| **Complexity** | High | Low |
| **Best For** | Production, streaming, tutorials | Quick captures, region selection |

---

## Screenshot Scripts

### `os-cmd-screenshot.sh`
**Wrapper script** that calls `wayland/scripts/screenshot.sh` with compatibility mapping.

Maps old interface to new unified screenshot script:
- `region` → `area` mode
- `windows` → `windows` mode
- `fullscreen` → `fullscreen` mode
- `smart` → `smart` mode (default)

**Usage:**
```bash
os-cmd-screenshot.sh [MODE] [PROCESSING]
```

### `screenshot.sh` (wayland/scripts/)
**Comprehensive screenshot utility** with multiple modes and features.

**Location:** `wayland/scripts/screenshot.sh` (deployed to `~/.local/bin/scripts/wayland/screenshot.sh`)

**Features:**
- Multiple capture modes: `screen`, `area`, `window`, `smart`, `windows`, `fullscreen`
- Freeze screen during selection (`--freeze`)
- Delay capture with countdown (`--wait TIME`)
- Clipboard-only mode (`--clipboard-only`)
- Post-capture editing with `satty` (`--satty`)
- Automatic clipboard copying
- Rich notifications with actions

**Usage:**
```bash
screenshot.sh                      # Full screen
screenshot.sh area                 # Interactive area selection
screenshot.sh smart                # Smart mode with window detection
screenshot.sh window --freeze      # Active window with frozen screen
screenshot.sh area --satty         # Area selection with editor
screenshot.sh --clipboard-only     # Copy to clipboard only
```

**Dependencies:**
- `grim` + `slurp` (required)
- `wl-copy` (for clipboard)
- `hyprpicker` or `wayfreeze` (for freeze mode)
- `hyprctl`, `jq` (for smart/window modes)
- `satty` (optional, for editing)

---

## Clipboard Manager

### `clipboard-manager.sh`
**Advanced clipboard history management** with rofi interface.

**Features:**
- View clipboard history
- Select and copy from history
- Delete specific entries
- Clear all history
- Statistics and monitoring
- Daemon mode for automatic history capture

**Usage:**
```bash
clipboard-manager.sh              # Show history (default)
clipboard-manager.sh show         # Same as above
clipboard-manager.sh delete       # Delete specific entries
clipboard-manager.sh clear        # Clear all history
clipboard-manager.sh stats        # Show statistics
clipboard-manager.sh daemon start # Start monitoring daemon
clipboard-manager.sh daemon stop  # Stop monitoring daemon
```

**Dependencies:**
- `cliphist`
- `rofi`
- `wl-clipboard` (wl-copy, wl-paste)

---

## When to Use Which

### Use `os-cmd-screenrecord.sh` when:
- You need audio capture (desktop or microphone)
- You want webcam overlay
- You're recording tutorials, streams, or presentations
- You need Waybar integration
- You're okay with full-screen only

### Use `screenrecord-wayland.sh` when:
- You need region/area selection
- You want maximum portability
- You don't need audio
- You want a lightweight solution
- You're on a system without `gpu-screen-recorder`

### Use `screenshot.sh` (wayland) when:
- You need advanced screenshot features
- You want multiple capture modes
- You need post-capture editing
- You want smart window detection

### Use `os-cmd-screenshot.sh` when:
- You need compatibility with old interface
- You're calling from system menus/keybindings
- You want automatic mode mapping

---

## Indicator Script

### `screenrecording-indicator.sh`
Returns JSON for Waybar indicating if screen recording is active.

**Detects:**
- `gpu-screen-recorder` (system script)
- `wl-screenrec` (wayland script)
- `wf-recorder` (wayland script fallback)

**Usage:** Called automatically by Waybar, no manual invocation needed.

---

## Installation & Configuration

All scripts are automatically deployed via Nix configuration:
- System scripts: `~/.local/bin/scripts/system/`
- Wayland scripts: `~/.local/bin/scripts/wayland/` (primary location for screenshot.sh)
- Direct binaries: `~/.local/bin/` (for convenience)

The screenshot script is located in the wayland directory as it's a Wayland-specific utility.
