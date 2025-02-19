# Terminal history search
# https://atuin.sh/docs/
# Updated when enter is pressed select not execute.

{
  config,
  lib,
  pkgs,
  ...
}:

{ 
  programs.atuin = {
    enable = true;
    package = pkgs.atuin;
    flags = [
    ];
    # https://docs.atuin.sh/configuration/config/
    settings = {
      # sync_address = "https://atuin.techcasa.io";
      auto_sync = true;
      sync_address = "http://atuin.tail5825d.ts.net";
      sync_frequency = "1m";
      search_mode = "fuzzy";
      dialect = "us";
      update_check = false;

      filter_mode = "global";
      search_mode_shell_up_key_binding = "fuzzy";
      filter_mode_shell_up_key_binding = "global";
      style = "auto";
      show_preview = true;
      max_preview_height = 4;
      show_help = true;
      show_tabs = true;
      exit_mode = "return-original";
      history_format = "history list";
      store_failed = true;
      secrets_filter = false;
      network_timeout = 30;
      network_connection_timeout = 5;
      local_timeout = 5;
      enter_accept = false;
      # TODO: Switch to vim-normal?
      keymap_mode = "vim-normal";
      keymap_cursor = {
        emacs = "blink-block";
        vim_insert = "blink-block";
        vim_normal = "steady-block";
      };
      prefers_reduced_motion = false;
      stats = {
        common_subcommands = [
          "apt"
          "cargo"
          "composer"
          "dnf"
          "docker"
          "git"
          "go"
          "ip"
          "kubectl"
          "nix"
          "nmcli"
          "npm"
          "pecl"
          "pnpm"
          "podman"
          "port"
          "systemctl"
          "tmux"
          "yarn"
        ];
        common_prefix = [
          "sudo"
          "noti"
        ];
      };
    };
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    enableNushellIntegration = lib.mkIf config.programs.nushell.enable true;
  };
}
