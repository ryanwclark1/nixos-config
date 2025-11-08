# Chromium Browser Configuration

Chromium browser with privacy-focused defaults, Wayland support, and integration with your NixOS environment.

## Package Choice

This configuration uses **ungoogled-chromium** instead of standard Chromium or Google Chrome:

- **ungoogled-chromium**: Chromium without Google integration, telemetry, or sync
- Enhanced privacy and control
- Extension support (requires manual installation or web store enabler)

For Google Chrome with sync capabilities, use `home/features/chrome` instead.

## Features

### Wayland Integration
- ✅ Native Wayland support (Ozone platform)
- ✅ GTK4 integration for consistent theming
- ✅ Hardware-accelerated video decode/encode (VA-API)
- ✅ Native window decorations

### Privacy & Security
- 🔒 DuckDuckGo as default search engine
- 🔒 Third-party cookies blocked by default
- 🔒 Google sync disabled
- 🔒 Metrics and telemetry disabled
- 🔒 DNS-over-HTTPS enabled
- 🔒 TLS 1.2+ enforced
- 🔒 Built-in password manager disabled (use external like Bitwarden/pass)

### Visual
- 🎨 Force dark mode enabled
- 🎨 Dark chrome:// pages
- 🎨 Catppuccin-compatible color scheme

### Performance
- ⚡ GPU rasterization enabled
- ⚡ Zero-copy enabled
- ⚡ Hardware acceleration for video

## Directory Structure

```
chromium/
├── default.nix           # Main Chromium configuration
└── README.md             # This file
```

## Configuration Files Generated

```
~/.config/chromium/
├── policies/
│   └── managed/
│       └── privacy.json              # Privacy & security policies
├── Default/
│   └── Preferences                   # Browser preferences
└── chromium-flags.conf               # Additional launch flags
```

## Usage

### Launch Chromium
```bash
chromium
```

### Launch in Private Mode
A wrapper script is provided for enhanced privacy:
```bash
chromium-private [URL]
```

This launches with:
- Incognito mode
- Sync disabled
- Media router disabled

### Set as Default Browser
```bash
xdg-settings set default-web-browser chromium.desktop
```

## Extensions

Extensions are defined in `default.nix` and include:

| Extension | Purpose |
|-----------|---------|
| uBlock Origin | Ad blocking and privacy |
| HTTPS Everywhere | Force HTTPS connections |

### Adding More Extensions

1. Find the extension ID from the Chrome Web Store URL:
   - Example: `https://chrome.google.com/webstore/detail/extension-name/EXTENSION_ID`

2. Add to `extensions` list in `default.nix`:
   ```nix
   extensions = [
     { id = "EXTENSION_ID"; }
   ];
   ```

3. Rebuild home-manager configuration

### Manual Extension Installation (ungoogled-chromium)

Ungoogled-chromium doesn't include the Chrome Web Store by default. To install extensions:

1. **Enable Chrome Web Store** (one-time setup):
   - Download the [Chromium Web Store](https://github.com/NeverDecaf/chromium-web-store) extension
   - Extract to a folder
   - Load unpacked extension from `chrome://extensions`

2. **Or install manually**:
   - Download `.crx` files from [CRX Extractor](https://crxextractor.com/)
   - Drag and drop into `chrome://extensions`

## Command-Line Arguments

The following flags are automatically applied (see `commandLineArgs` in `default.nix`):

### Wayland
- `--enable-features=UseOzonePlatform` - Use Ozone for Wayland
- `--ozone-platform=wayland` - Select Wayland backend
- `--enable-features=WaylandWindowDecorations` - Native decorations
- `--gtk-version=4` - Use GTK4

### Hardware Acceleration
- `--enable-features=VaapiVideoDecoder` - VA-API video decoding
- `--enable-features=VaapiVideoEncoder` - VA-API video encoding
- `--enable-accelerated-video-decode` - GPU video decode
- `--enable-gpu-rasterization` - GPU rendering
- `--enable-zero-copy` - Zero-copy performance

### Visual
- `--force-dark-mode` - Dark theme everywhere
- `--enable-features=WebUIDarkMode` - Dark chrome:// pages

## Privacy Policies

Browser policies are enforced via `~/.config/chromium/policies/managed/privacy.json`:

```json
{
  "DefaultSearchProviderName": "DuckDuckGo",
  "SSLVersionMin": "tls1.2",
  "DNSOverHttpsMode": "automatic",
  "BlockThirdPartyCookies": true,
  "SyncDisabled": true,
  "MetricsReportingEnabled": false,
  "PasswordManagerEnabled": false
}
```

These settings **cannot be changed** through the UI when enforced by policy.

## Session Management

### Restore Previous Session
By default, Chromium restores your previous tabs on startup.

To change this behavior, modify `Preferences` in `default.nix`:
```nix
"session" = {
  "restore_on_startup" = 1;  # 1=New tab, 4=Restore previous, 5=Open URLs
};
```

## Integration with Environment

### Environment Variables (from Hyprland)

The following environment variables from your Hyprland config affect Chromium:

```bash
OZONE_PLATFORM=wayland              # Forces Wayland mode
ELECTRON_OZONE_PLATFORM_HINT=wayland # Electron apps use Wayland
```

These are set in:
- `home/features/desktop/window-managers/hyprland/conf/environments/default.conf`

### Wayland Window Rules

Add Chromium-specific window rules to Hyprland config if needed:

```conf
# home/features/desktop/window-managers/hyprland/conf/windowrules/default.conf
windowrulev2 = idleinhibit fullscreen, class:^(chromium)$
windowrulev2 = opacity 0.98 0.95, class:^(chromium)$
```

## Theming

Chromium uses GTK4 for native theming, which integrates with your Catppuccin GTK theme:

- Configured in: `home/features/desktop/common/theming/gtk.nix`
- Theme: Catppuccin Mocha
- Force dark mode ensures dark theme everywhere

## Troubleshooting

### Chromium not using Wayland

Check that Wayland backend is active:
```bash
chromium --version
chrome://gpu  # Should show "Ozone: Wayland"
```

If not, ensure environment variables are set:
```bash
echo $OZONE_PLATFORM        # Should be "wayland"
echo $XDG_SESSION_TYPE      # Should be "wayland"
```

### Hardware acceleration not working

1. Check GPU status at `chrome://gpu`
2. Verify VA-API support:
   ```bash
   vainfo  # Should list supported profiles
   ```
3. For Intel GPUs, ensure `intel-media-driver` is installed
4. For AMD GPUs, ensure `mesa` VA-API drivers are installed

### Extensions not loading

For ungoogled-chromium:
1. Enable "Developer mode" in `chrome://extensions`
2. Install Chromium Web Store extension
3. Or manually load unpacked extensions

### Dark mode not applying

Force dark mode is enabled by default. If sites don't respect it:
1. Visit `chrome://flags`
2. Search for "Auto Dark Mode for Web Contents"
3. Enable and relaunch

### Website compatibility issues

Some sites may not work well with ungoogled-chromium due to:
- User agent detection
- Missing Google APIs
- DRM content (Widevine)

For maximum compatibility, consider using `google-chrome` instead:
```bash
# Switch to Google Chrome configuration
# Use: home/features/chrome instead
```

## Comparison with Google Chrome

| Feature | ungoogled-chromium (this) | Google Chrome |
|---------|--------------------------|---------------|
| Privacy | ⭐⭐⭐⭐⭐ (No telemetry) | ⭐⭐ (Telemetry enabled) |
| Sync | ❌ Disabled | ✅ Google account sync |
| Updates | Via NixOS | Via NixOS |
| Extensions | Manual/Web Store | Web Store |
| Compatibility | Good (95%) | Excellent (100%) |
| Widevine DRM | Optional | Built-in |

## Customization

### Change Default Search Engine

Edit `default.nix`:
```nix
"DefaultSearchProviderName" = "Brave";
"DefaultSearchProviderSearchURL" = "https://search.brave.com/search?q={searchTerms}";
```

### Enable Google Sync (requires standard Chromium)

Change package to standard chromium:
```nix
package = pkgs.chromium;  # Instead of pkgs.ungoogled-chromium
```

And enable sync:
```nix
"SyncDisabled" = false;
```

### Disable Dark Mode

Remove from `commandLineArgs`:
```nix
# "--force-dark-mode"
# "--enable-features=WebUIDarkMode"
```

## Related Configuration

- **Chrome**: `home/features/chrome/` - Google Chrome with sync
- **Firefox**: `home/features/firefox/` - Alternative browser
- **GTK Theme**: `home/features/desktop/common/theming/gtk.nix`
- **Hyprland**: Window manager integration

## References

- [Chromium on NixOS Wiki](https://nixos.wiki/wiki/Chromium)
- [ungoogled-chromium](https://github.com/ungoogled-software/ungoogled-chromium)
- [Home Manager Chromium Options](https://nix-community.github.io/home-manager/options.html#opt-programs.chromium.enable)
- [Chromium Command Line Switches](https://peter.sh/experiments/chromium-command-line-switches/)
- [Chrome Policies](https://chromeenterprise.google/policies/)
