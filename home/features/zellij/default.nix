# Similar to TMUX
{
  pkgs,
  ...
}:
# Update theme

{
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    # https://zellij.dev/documentation
    settings = {
      copy_command = "wl-copy";
      on_force_close = "quit";
      simplified_ui = false;
      default_shell = "fish";
      pane_frames = true;
      theme = "nord";
      default_layout = "default";
      mouse_mode = false;
      copy_clipboard = "primary";
      copy_on_select = true;
      scrollback_editor = "$EDITOR";


    };
    # enableZshIntegration = true;
    enableFishIntegration = true;
    # enableBashIntegration = true;
  };

}
