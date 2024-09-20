{
  ...
}:

{
  home.file.".config/hypr/scripts/rofi-launcher.sh" = {
    text = ''
    #!/usr/bin/env bash
    if pgrep -x "rofi" > /dev/null; then
      # Rofi is running, kill it
      pkill -x rofi
      exit 0
    fi
    rofi -show drun
  '';
  };
  executable = true;
}
