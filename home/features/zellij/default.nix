# Similar to TMUX
# https://zellij.dev/documentation
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./themes/theme.kdl.nix
    ./layouts/default.kdl.nix
  ];

  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    # https://zellij.dev/documentation/options
    settings ={
      on_force_close = "detach";
      simplified_ui = false;
      default_shell = lib.getExe pkgs.zsh;
      pane_frames = true;
      theme = "theme";
      default_layout = "default";
      default_mode = "locked";
      mouse_mode = true;
      scroll_buffer_size = 25000;
      copy_command = "${pkgs.wl-clipboard}/bin/wl-copy";
      copy_clipboard = "system";
      copy_on_select = true;
      scrollback_editor = lib.getExe pkgs.nvim;
      mirror_session = true;
      layout_dirs = "${config.home.homeDirectory}/.config/zellij/layouts";
      theme_dirs = "${config.home.homeDirectory}/.config/zellij/themes";
      env = {
        RUST_BACKTRACE = 1;
      };
      ui = {
        pane_frame = {
          rounded_corners = true;
          hide_session_name = true;
        };
      };
      auto_layout = true;
      styled_underlines = true;
      session_serialization = true;
      pane_viewport_serialization = false;
      scrollback_lines_to_serialize = 0;
      serialization_interval = 30;
      disable_session_metadata = false;
      stacked_resize = true;
      show_startup_tips = false;
      show_release_notes = true;
      web_server = true;
      web_server_ip = "127.0.0.1";
      web_server_port = 8085;
      web_client = true;
      advanced_mouse_actions = true;
    };
    enableBashIntegration = lib.mkIf config.programs.bash.enable false;
    enableFishIntegration = lib.mkIf config.programs.fish.enable false;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable false;
  };

  home.shellAliases = {
    zj = "zellij";
  };
}
