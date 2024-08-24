# Similar to TMUX
# https://zellij.dev/documentation
{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.zellij =
  let
    # fish = lib.getExe pkgs.fish;
    zsh = lib.getExe pkgs.zsh;
    wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
  in
  {
    enable = true;
    package = pkgs.zellij;
    # https://zellij.dev/documentation/options
    settings =
    {
      on_force_close = "detach";
      simplified_ui = false;
      default_shell = zsh;
      default_layout = "default";
      default_mode = "locked";
      mouse_mode = true;
      scroll_buffer_size = 25000;
      copy_command = wl-copy;
      copy_clipboard = "system";
      copy_on_select = true;
      scrollback_editor = "$EDITOR";
      mirror_session = true;
      pane_frames = true;
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
      # Serializes all scroll back to limit
      scrollback_lines_to_serialize = 0;
      disable_session_metadata = false;
    };
  };

  home.shellAliases = {
    zj = "zellij";
  };

}
