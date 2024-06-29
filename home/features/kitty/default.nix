{
  config,
  pkgs,
  ...
}:
let
  kitty-xterm = pkgs.writeShellScriptBin "xterm" ''
    ${config.programs.kitty.package}/bin/kitty -1 "$@"
  '';
in
{
  home = {
    packages = [ kitty-xterm ];
    sessionVariables = {
      TERMINAL = "kitty -1";
    };
  };

  programs.kitty = {
    enable = true;
    package = pkgs.kitty;
    settings = {
      scrollback_lines = 25000;
      scrollback_pager_history_size = 2048;

      copy_on_select = "clipboard";

      wheel_scroll_min_lines = 1;
      window_padding_width = 15;
      update_check_interval = 0;
      repaint_delay = 10;
      input_delay = 1;
      sync_to_monitor = true;

      # changing default behaviors
      confirm_os_window_close = 0;

      enable_audio_bell = false;
      dynamic_background_opacity = true;
      allow_remote_control = true;
    };

  };
}
