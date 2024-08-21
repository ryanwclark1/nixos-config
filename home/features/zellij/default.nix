# Similar to TMUX
# https://zellij.dev/documentation
{
  config,
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
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
  };

  home.shellAliases = {
    zj = "zellij";
  };

}
