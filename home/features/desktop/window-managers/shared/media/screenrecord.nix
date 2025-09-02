{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Screen recording utilities with area selection
  
  home.packages = with pkgs; [
    wl-screenrec  # Modern Wayland screen recorder
    wf-recorder   # Alternative recorder for compatibility
    slurp        # Area selection tool
    
    # Screen recording script with intelligent area selection
    (writeShellScriptBin "screenrecord" ''
      PATH="${pkgs.coreutils}/bin:${pkgs.libnotify}/bin:${pkgs.procps}/bin:${pkgs.slurp}/bin:${pkgs.wl-screenrec}/bin:${pkgs.wf-recorder}/bin:${pkgs.gnugrep}/bin:${pkgs.pciutils}/bin:$PATH"
      
      # Load XDG directories configuration
      if [[ -f ~/.config/user-dirs.dirs ]]; then
        source ~/.config/user-dirs.dirs
      fi
      
      # Determine output directory (configurable via environment)
      OUTPUT_DIR="''${SCREENRECORD_DIR:-''${XDG_VIDEOS_DIR:-$HOME/Videos}}"
      
      # Ensure output directory exists
      if [[ ! -d "$OUTPUT_DIR" ]]; then
        mkdir -p "$OUTPUT_DIR" || {
          notify-send "Screen Recording Error" "Cannot create directory: $OUTPUT_DIR" -u critical -t 3000
          exit 1
        }
      fi
      
      # Function to start screen recording
      start_recording() {
        local filename="$OUTPUT_DIR/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"
        notify-send "🎬 Screen Recording" "Starting recording..." -t 1500
        sleep 1
        
        # Choose recorder based on graphics hardware
        if lspci | grep -Eqi 'nvidia|intel.*graphics'; then
          # Use wf-recorder for better hardware acceleration support
          echo "Using wf-recorder (hardware accelerated)"
          wf-recorder -f "$filename" -c libx264 -p crf=23 -p preset=medium -p movflags=+faststart "$@"
        else
          # Use wl-screenrec as default
          echo "Using wl-screenrec"  
          wl-screenrec -f "$filename" --ffmpeg-encoder-options="-c:v libx264 -crf 23 -preset medium -movflags +faststart" "$@"
        fi
        
        # Notify when recording stops
        if [[ -f "$filename" ]]; then
          notify-send "✅ Screen Recording" "Saved: $(basename "$filename")" -t 3000
          echo "Recording saved to: $filename"
        fi
      }
      
      # Check if recording is already in progress
      if pgrep -x wl-screenrec >/dev/null || pgrep -x wf-recorder >/dev/null; then
        # Stop existing recording
        pkill -x wl-screenrec 2>/dev/null
        pkill -x wf-recorder 2>/dev/null
        notify-send "⏹️ Screen Recording" "Recording stopped" -t 2000
        exit 0
      fi
      
      # Start recording based on argument
      case "''${1:-region}" in
        "output"|"fullscreen")
          echo "Recording full screen"
          start_recording
          ;;
        "region"|*)
          echo "Recording selected region"
          region=$(slurp 2>/dev/null) || {
            notify-send "Screen Recording" "Region selection cancelled" -t 1000
            exit 1
          }
          start_recording -g "$region"
          ;;
      esac
    '')
    
    # Simple stop script
    (writeShellScriptBin "screenrecord-stop" ''
      PATH="${pkgs.procps}/bin:${pkgs.libnotify}/bin:$PATH"
      
      if pgrep -x wl-screenrec >/dev/null || pgrep -x wf-recorder >/dev/null; then
        pkill -x wl-screenrec 2>/dev/null
        pkill -x wf-recorder 2>/dev/null
        notify-send "⏹️ Screen Recording" "Recording stopped" -t 2000
        echo "Screen recording stopped"
      else
        echo "No screen recording in progress"
      fi
    '')
    
    # Combined screen recording toggle
    (writeShellScriptBin "screenrecord-toggle" ''
      PATH="${pkgs.procps}/bin:$PATH"
      
      if pgrep -x wl-screenrec >/dev/null || pgrep -x wf-recorder >/dev/null; then
        screenrecord-stop
      else
        screenrecord "$@"
      fi
    '')
  ];
  
  # Ensure Videos directory exists
  home.activation.createVideosDir = ''
    mkdir -p "$HOME/Videos"
  '';
}