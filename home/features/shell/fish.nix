{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  packageNames = map (p: p.pname or p.name or null) config.home.packages;
  hasPackage = name: lib.any (x: x == name) packageNames;
  hasRipgrep = hasPackage "ripgrep";
  hasNeomutt = config.programs.neomutt.enable;
  # hasShellColor = config.programs.shellcolor.enable;
  # shellcolor = "${pkgs.shellcolord}/bin/shellcolor";
in
{
  programs.fish = {
    enable = true;
    shellAliases = {
      # Clear screen and scrollback
      clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
    };
    functions = {
      # Disable greeting
      fish_greeting = "";
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
      # Integrate ssh with shellcolord
      # ssh = mkIf hasShellColor /* fish */ ''
      #   ${shellcolor} disable $fish_pid
      #   # Check if kitty is available
      #   if set -q KITTY_PID && set -q KITTY_WINDOW_ID && type -q -f kitty
      #     kitty +kitten ssh $argv
      #   else
      #     command ssh $argv
      #   end
      #   ${shellcolor} enable $fish_pid
      #   ${shellcolor} apply $fish_pid
      # '';
    };
    #   interactiveShellInit = /* fish */ ''
    #       # Open command buffer in vim when alt+e is pressed
    #       bind \ee edit_command_buffer

    #       # kitty integration
    #       set --global KITTY_INSTALLATION_DIR "${pkgs.kitty}/lib/kitty"
    #       set --global KITTY_SHELL_INTEGRATION enabled
    #       source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
    #       set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"


  };
  programs.atuin.enableFishIntegration = mkIf config.programs.atuin.enable true;
  programs.fzf.enableFishIntegration = mkIf config.programs.fzf.enable true;
  programs.nix-index.enableFishIntegration = mkIf config.programs.nix-index.enable true;
  programs.starship.enableFishIntegration = mkIf config.programs.starship.enable true;
  programs.zoxide.enableFishIntegration = mkIf config.programs.zoxide.enable true;
  programs.zellij.enableFishIntegration = mkIf config.programs.zellij.enable true;
}
