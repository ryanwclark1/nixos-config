# Similar to TMUX
{ pkgs
, ...
}:
# Update theme

{
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    # https://zellij.dev/documentation
    settings = {
      on_force_close = "quit";
      simplified_ui = false;
      default_shell = "fish";
      pane_frames = true;
      theme = "nord";
      default_layout = "default";

    };
    # enableZshIntegration = true;
    enableFishIntegration = true;
    # enableBashIntegration = true;
  };
}
