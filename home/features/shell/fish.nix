{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  packageNames = map (p: p.pname or p.name or null) config.home.packages;
  hasPackage = name: lib.any (x: x == name) packageNames;
  hasRipgrep = hasPackage "ripgrep";
  hasNeomutt = config.programs.neomutt.enable;
in
{
  programs.fish = {
    enable = true;
    loginShellInit = /* fish */ ''
      # Remove fish greeting
      set -U fish_greeting
    '';
    shellAliases = {
      # Clear screen and scrollback
      clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
    };
    functions = {
      # Grep using ripgrep and pass to nvim
      nvimrg = mkIf (hasNeomutt && hasRipgrep) "nvim -q (rg --vimgrep $argv | psub)";
      # Merge history upon doing up-or-search
      # This lets multiple fish instances share history
      up-or-search = /* fish */ ''
        if commandline --search-mode
          commandline -f history-search-backward
          return
        end
        if commandline --paging-mode
          commandline -f up-line
          return
        end
        set -l lineno (commandline -L)
        switch $lineno
          case 1
            commandline -f history-search-backward
            history merge
          case '*'
            commandline -f up-line
        end
      '';
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

        # kitty integration
        set --global KITTY_INSTALLATION_DIR "${pkgs.kitty}/lib/kitty"
        set --global KITTY_SHELL_INTEGRATION enabled
        source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
        set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"
    '';

  };
  programs.atuin.enableFishIntegration = mkIf config.programs.atuin.enable true;
  programs.fzf.enableFishIntegration = mkIf config.programs.fzf.enable true;
  programs.eza.enableFishIntegration = mkIf config.programs.eza.enable true;
  programs.kitty.enableFishIntegration = mkIf config.programs.kitty.enable true;
  programs.nix-index.enableFishIntegration = mkIf config.programs.nix-index.enable true;
  programs.starship.enableFishIntegration = mkIf config.programs.starship.enable true;
  programs.yazi.enableFishIntegration = mkIf config.programs.yazi.enable true;
  programs.zoxide.enableFishIntegration = mkIf config.programs.zoxide.enable true;
  programs.zellij.enableFishIntegration = mkIf config.programs.zellij.enable true;
}
