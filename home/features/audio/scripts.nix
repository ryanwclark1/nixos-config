{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Audio utility scripts
  
  home.packages = with pkgs; [
    # Audio sink switcher script
    (writeShellScriptBin "audio-switch" ''
      PATH="${pkgs.wireplumber}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.gawk}/bin:$PATH"
      
      # Find all audio sinks, exit if none found
      sinks=($(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep -E '^\s*│\s+\*?\s*[0-9]+\.' | sed -E 's/^[^0-9]*([0-9]+)\..*/\1/'))
      if [[ ''${#sinks[@]} -eq 0 ]]; then
        echo "No audio sinks found"
        exit 1
      fi
      
      # Find current active audio sink
      current=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep '^\s*│\s*\*' | sed -E 's/^[^0-9]*([0-9]+)\..*/\1/')
      
      # Find the next sink (cycling through available sinks)
      next=""
      for i in "''${!sinks[@]}"; do
        if [[ "''${sinks[$i]}" = "$current" ]]; then
          next="''${sinks[$(((i + 1) % ''${#sinks[@]}))]}"
          break
        fi
      done
      
      # Fallback to first sink if current not found
      next="''${next:-''${sinks[0]}}"
      
      # Get sink name for notification
      sink_name=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep "^\s*│\s*\*\?\s*$next\." | sed -E 's/^[^.]*\.\s*//')
      
      # Switch to next sink and unmute it
      wpctl set-default "$next"
      wpctl set-mute "$next" 0
      
      # Send notification about the switch
      ${pkgs.libnotify}/bin/notify-send "🔊 Audio Output" "Switched to: $sink_name" -t 2000
    '')
    
    # Audio volume control scripts  
    (writeShellScriptBin "audio-volume-up" ''
      PATH="${pkgs.wireplumber}/bin:$PATH"
      wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
      ${pkgs.libnotify}/bin/notify-send "🔊 Volume" "$(wpctl get-volume @DEFAULT_AUDIO_SINK@)" -t 1000
    '')
    
    (writeShellScriptBin "audio-volume-down" ''
      PATH="${pkgs.wireplumber}/bin:$PATH"
      wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      ${pkgs.libnotify}/bin/notify-send "🔉 Volume" "$(wpctl get-volume @DEFAULT_AUDIO_SINK@)" -t 1000
    '')
    
    (writeShellScriptBin "audio-volume-mute" ''
      PATH="${pkgs.wireplumber}/bin:$PATH"
      wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED"; then
        ${pkgs.libnotify}/bin/notify-send "🔇 Audio" "Muted" -t 1000
      else
        ${pkgs.libnotify}/bin/notify-send "🔊 Audio" "Unmuted" -t 1000
      fi
    '')
  ];
}