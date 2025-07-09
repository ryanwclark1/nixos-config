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
   sops.secrets = {
    atuin-key = {
      sopsFile = ../../../secrets/secrets.yaml;
    };
  };

  programs.atuin = {
    enable = true;
    package = pkgs.atuin;
    flags = [
    ];
    # https://docs.atuin.sh/configuration/config/
    settings = {
      # sync_address = "https://atuin.techcasa.io";
      auto_sync = true;
      # sync_address = "http://100.112.124.7:8888";
      # key_path = config.sops.secrets.atuin-key.path;
      sync_frequency = "1m";
      dialect = "us";
      enter_accept = false;
      exit_mode = "return-original";
      filter_mode = "global";
      filter_mode_shell_up_key_binding = "global";
      history_format = "history list";
      keymap_mode = "vim-normal";
      local_timeout = 5;
      max_preview_height = 4;
      network_connection_timeout = 5;
      network_timeout = 30;
      search_mode = "fuzzy";
      search_mode_shell_up_key_binding = "fuzzy";
      secrets_filter = false;
      show_help = true;
      show_preview = true;
      show_tabs = true;
      store_failed = true;
      style = "auto";
      update_check = false;
      workspace = false;
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
          "yt-dlp"
          "uv"
          "poetry"
          "claude"
          "yt-dlp"
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
