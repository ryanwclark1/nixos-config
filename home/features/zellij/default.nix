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
    fish = lib.getExe pkgs.fish;
    wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
  in
  {
    enable = true;
    package = pkgs.zellij;
    settings = {
      on_force_close = "quit";
      simplified_ui = false;
      default_shell = fish;
      pane_frames = true;
      default_layout = "default";
      mouse_mode = false;
      copy_command = wl-copy;
      copy_clipboard = "primary";
      copy_on_select = true;
      scroll_buffer_size = 25000;
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
