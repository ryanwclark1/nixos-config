{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.fish = {
    enable = true;
    # loginShellInit = /* fish */ ''
    #   # Remove fish greeting
    #   set -U fish_greeting
    # '';
    shellAliases = {
      # Clear screen and scrollback
      clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
    };
    functions = {
      # zellij_tab_name_update --on-variable PWD
      zellij_tab_name_update = /* fish */ ''
        if set -q ZELLIJ
          set tab_name ""
          if git rev-parse --is-inside-work-tree >/dev/null 2>&1
            set git_root (basename (git rev-parse --show-toplevel))
            set git_prefix (git rev-parse --show-prefix)
            set tab_name "$git_root/$git_prefix"
            set tab_name (string trim -c / "$tab_name") # Remove trailing slash
          else
            set tab_name $PWD
            if test "$tab_name" = "$HOME"
              set tab_name "~"
            else
              set tab_name (basename "$tab_name")
            end
          end
          command nohup zellij action rename-tab $tab_name >/dev/null 2>&1 &
        end
      end'';
    };
    interactiveShellInit = /* fish */ ''
        # Remove fish greeting
        set -U fish_greeting

        # Open command buffer in vim when alt+e is pressed
        bind \ee edit_command_buffer
    '';

  };
  programs.atuin.enableFishIntegration = lib.mkIf config.programs.atuin.enable true;
  programs.fzf.enableFishIntegration = lib.mkIf config.programs.fzf.enable true;
  programs.eza.enableFishIntegration = lib.mkIf config.programs.eza.enable true;
  programs.kitty.shellIntegration.enableFishIntegration = lib.mkIf config.programs.kitty.enable true;
  programs.nix-index.enableFishIntegration = lib.mkIf config.programs.nix-index.enable true;
  programs.starship.enableFishIntegration = lib.mkIf config.programs.starship.enable true;
  programs.yazi.enableFishIntegration = lib.mkIf config.programs.yazi.enable true;
  programs.zoxide.enableFishIntegration = lib.mkIf config.programs.zoxide.enable true;
  programs.zellij.enableFishIntegration = lib.mkIf config.programs.zellij.enable true;
}
