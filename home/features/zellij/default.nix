# Similar to TMUX
# https://zellij.dev/documentation
{
  lib,
  pkgs,
  ...
}:

{
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    settings = {
      copy_command = "wl-copy";
      on_force_close = "quit";
      simplified_ui = false;
      default_shell = lib.mkDefault "${pkgs.fish}/bin/fish";
      pane_frames = true;
      default_layout = "default";
      mouse_mode = false;
      copy_clipboard = "primary";
      copy_on_select = true;
      scrollback_editor = "$EDITOR";
    };
  };

}
