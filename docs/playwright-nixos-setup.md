# Playwright MCP Setup for NixOS

## Problem

Playwright MCP server struggles with NixOS because:

1. **Browser Path Issues**: Playwright looks for browsers in standard Linux locations (e.g., `/opt/google/chrome/chrome`), but NixOS stores packages in the Nix store with hashed paths
2. **Dependency Isolation**: NixOS isolates package dependencies, so browsers may not find all required libraries
3. **Hardcoded Paths**: Some Playwright tools have hardcoded browser search paths that don't work in NixOS

## Solution

We've implemented a multi-layered approach:

### 1. Use Playwright's Bundled Browsers (Recommended)

The most reliable solution is to use Playwright's bundled browsers via the `playwright.browsers` package:

```nix
home.packages = with pkgs; [
  playwright-mcp
  playwright.browsers  # Provides Chromium, Firefox, and WebKit
];
```

This ensures Playwright always has access to browsers without path issues.

### 2. Environment Variables

Set `PLAYWRIGHT_BROWSERS_PATH` to point to the bundled browsers:

```nix
home.sessionVariables = {
  PLAYWRIGHT_BROWSERS_PATH = "${lib.getLib pkgs.playwright.browsers}";
};
```

### 3. Wrapper Script

A wrapper script (`mcp-server-playwright-nixos`) handles:
- Setting `PLAYWRIGHT_BROWSERS_PATH` to bundled browsers
- Falling back to system Chrome/Chromium if needed
- Ensuring all browser dependencies are in PATH

The wrapper is automatically created and available as `mcp-server-playwright-nixos`.

### 4. MCP Server Configuration

The MCP server configurations (both in VSCode and JSON files) now use the wrapper script with proper environment variables.

## Usage

### For VSCode MCP

The VSCode configuration automatically uses the wrapper. No additional setup needed.

### For JSON-based MCP Configs

Update your MCP server JSON configuration:

```json
{
  "playwright": {
    "command": "mcp-server-playwright-nixos",
    "args": ["--browser=chrome", "--headless"],
    "env": {
      "PLAYWRIGHT_BROWSERS_PATH": "${PLAYWRIGHT_BROWSERS_PATH}"
    },
    "description": "Browser automation and web scraping via Playwright"
  }
}
```

Or use the direct path:

```json
{
  "playwright": {
    "command": "/nix/store/.../bin/mcp-server-playwright-nixos",
    "args": ["--headless"],
    "env": {
      "PLAYWRIGHT_BROWSERS_PATH": "/nix/store/.../playwright-browsers"
    }
  }
}
```

## Browser Options

### Option 1: Bundled Browsers (Default, Recommended)

- **Chromium**: Provided by `playwright.browsers`
- **Firefox**: Provided by `playwright.browsers`
- **WebKit**: Provided by `playwright.browsers`

**Pros**: Most reliable, always works, no path issues
**Cons**: Larger download, separate from system browsers

### Option 2: System Chrome/Chromium

If you prefer using your system-installed Chrome:

```nix
home.sessionVariables = {
  PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH = "${pkgs.google-chrome}/bin/google-chrome-stable";
};
```

**Pros**: Uses your configured Chrome with extensions/settings
**Cons**: May have path/dependency issues, less reliable

## Troubleshooting

### Playwright can't find browsers

1. Check that `playwright.browsers` is installed:
   ```bash
   nix-env -q | grep playwright
   ```

2. Verify `PLAYWRIGHT_BROWSERS_PATH` is set:
   ```bash
   echo $PLAYWRIGHT_BROWSERS_PATH
   ```

3. Test the wrapper script:
   ```bash
   mcp-server-playwright-nixos --help
   ```

### Browser launches but crashes

This usually indicates missing dependencies. The wrapper script includes common dependencies, but you may need to add more:

```nix
home.packages = with pkgs; [
  # Additional browser dependencies
  libglvnd
  libdrm
  mesa
  # ... other dependencies
];
```

### Using system Chrome instead of bundled

If you want to force using system Chrome:

```bash
export PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=$(which google-chrome-stable)
mcp-server-playwright-nixos --browser=chrome
```

## References

- [NixOS Playwright Package](https://search.nixos.org/packages?query=playwright)
- [Playwright Documentation](https://playwright.dev/)
- [NixOS Browser Packaging](https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/go/google-chrome/package.nix)

## Related Files

- `home/features/chrome/default.nix` - Chrome configuration with Playwright support
- `home/features/ai/default.nix` - AI features with Playwright MCP wrapper
- `home/features/vscode/default.nix` - VSCode MCP configuration
- `home/features/ai/mcp-servers.json` - JSON-based MCP server configs


