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
      "--disable-ctrl-r"
    ];
    settings = {
      auto_sync = true;
      dialect = "us";
      enter_accept = false;
      exit_mode = "return-original";
      filter_mode = "global";
      filter_mode_shell_up_key_binding = "global";
      history_format = "history list";
      keymap_mode = "vim-normal";
      local_timeout = 5;
      max_preview_height = 4;
      network_connect_timeout = 5;
      network_timeout = 30;
      sync_address = "https://atuin-1.tail5825d.ts.net";
      sync_frequency = "10m";
      search_mode = "daemon-fuzzy";
      search_mode_shell_up_key_binding = "fuzzy";
      secrets_filter = true;
      show_help = true;
      show_preview = true;
      show_tabs = true;
      store_failed = true;
      style = "auto";
      update_check = false;
      workspaces = false;
      prefers_reduced_motion = false;

      daemon = {
        enabled = true;
        autostart = true;
      };

      keymap_cursor = {
        emacs = "blink-block";
        vim_insert = "blink-block";
        vim_normal = "steady-block";
      };

      sync = {
        records = true;
      };

      stats = {
        common_subcommands = [
          "apt"
          "cargo"
          "claude"
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
          "poetry"
          "port"
          "systemctl"
          "tmux"
          "uv"
          "yarn"
          "yt-dlp"
        ];
        common_prefix = [
          "noti"
          "sudo"
        ];
      };
    };
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    enableNushellIntegration = lib.mkIf config.programs.nushell.enable true;
  };
}
