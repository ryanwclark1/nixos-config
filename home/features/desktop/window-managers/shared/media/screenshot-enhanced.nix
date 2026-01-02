{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Enhanced screenshot utilities

  home.packages = with pkgs; [
    hyprshot # Screenshot tool for Hyprland (required for screenshot-enhanced)

    # Enhanced screenshot script with automatic directory creation and better workflow
    (writeShellScriptBin "screenshot-enhanced" ''
      PATH="${pkgs.hyprshot}/bin:${pkgs.satty}/bin:${pkgs.slurp}/bin:${pkgs.libnotify}/bin:${pkgs.coreutils}/bin:${pkgs.procps}/bin:$PATH"

      # Load XDG directories configuration
      if [[ -f ~/.config/user-dirs.dirs ]]; then
        source ~/.config/user-dirs.dirs
      fi

      # Determine output directory (configurable via environment)
      OUTPUT_DIR="''${SCREENSHOT_DIR:-''${XDG_PICTURES_DIR:-$HOME/Pictures}}/Screenshots"

      # Ensure output directory exists
      mkdir -p "$OUTPUT_DIR" || {
        notify-send "Screenshot Error" "Cannot create directory: $OUTPUT_DIR" -u critical -t 3000
        exit 1
      }

      # Stop any existing slurp instances to avoid conflicts
      pkill slurp 2>/dev/null || true

      # Default mode is region if not specified
      mode="''${1:-region}"

      # Generate timestamp filename
      timestamp="$(date +'%Y-%m-%d_%H-%M-%S')"
      output_file="$OUTPUT_DIR/screenshot-$timestamp.png"

      echo "Taking $mode screenshot..."

      # Capture screenshot with hyprshot and pipe to satty
      if hyprshot -m "$mode" --raw 2>/dev/null | satty \
          --filename - \
          --output-filename "$output_file" \
          --early-exit \
          --actions-on-enter save-to-clipboard \
          --save-after-copy \
          --copy-command 'wl-copy' 2>/dev/null; then

        # Success notification
        if [[ -f "$output_file" ]]; then
          notify-send "📷 Screenshot" "Saved: $(basename "$output_file")" -t 2000
          echo "Screenshot saved: $output_file"
        else
          notify-send "📷 Screenshot" "Copied to clipboard" -t 2000
          echo "Screenshot copied to clipboard"
        fi
      else
        # Handle cancellation or error
        exit_code=$?
        if [[ $exit_code -eq 130 || $exit_code -eq 1 ]]; then
          # User cancelled (Ctrl+C or ESC)
          notify-send "📷 Screenshot" "Cancelled" -t 1000
          echo "Screenshot cancelled by user"
        else
          # Actual error
          notify-send "📷 Screenshot Error" "Failed to capture screenshot" -u critical -t 3000
          echo "Screenshot failed with exit code: $exit_code"
          exit 1
        fi
      fi
    '')

    # Quick screenshot shortcuts
    (writeShellScriptBin "screenshot-region" ''
      screenshot-enhanced region
    '')

    (writeShellScriptBin "screenshot-window" ''
      screenshot-enhanced window
    '')

    (writeShellScriptBin "screenshot-output" ''
      screenshot-enhanced output
    '')

    # Screenshot with custom delay
    (writeShellScriptBin "screenshot-delay" ''
      delay=''${1:-3}
      mode=''${2:-region}

      echo "Screenshot in $delay seconds..."
      ${pkgs.libnotify}/bin/notify-send "📷 Screenshot" "Screenshot in $delay seconds..." -t $(( delay * 1000 ))

      sleep "$delay"
      screenshot-enhanced "$mode"
    '')

    # Open screenshots folder
    (writeShellScriptBin "screenshots-folder" ''
      if [[ -f ~/.config/user-dirs.dirs ]]; then
        source ~/.config/user-dirs.dirs
      fi

      SCREENSHOT_DIR="''${SCREENSHOT_DIR:-''${XDG_PICTURES_DIR:-$HOME/Pictures}}/Screenshots"
      mkdir -p "$SCREENSHOT_DIR"

      if command -v nautilus >/dev/null 2>&1; then
        nautilus "$SCREENSHOT_DIR" &
      elif command -v thunar >/dev/null 2>&1; then
        thunar "$SCREENSHOT_DIR" &
      elif command -v dolphin >/dev/null 2>&1; then
        dolphin "$SCREENSHOT_DIR" &
      else
        echo "Screenshot directory: $SCREENSHOT_DIR"
      fi
    '')
  ];
}
