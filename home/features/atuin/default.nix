# Terminal history search
# https://atuin.sh/docs/
# Updated when enter is pressed select not execute.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  atuinConfigDir = "${config.home.homeDirectory}/.config/atuin";
  atuinSettings = {
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
  tomlFormat = pkgs.formats.toml { };
in
{
   sops.secrets = {
    atuin-key = {
      sopsFile = ../../../secrets/secrets.yaml;
    };
  };

  # Install atuin package
  home.packages = [ pkgs.atuin ];

  # Manually manage config.toml to avoid backup conflicts
  # Using home.file instead of programs.atuin to have full control
  home.file."${atuinConfigDir}/config.toml" = {
    force = true;
    text = tomlFormat.generate "atuin-config" atuinSettings;
  };

  # Enable shell integrations manually since we're not using programs.atuin
  # Use lib.mkMerge to append to existing initExtra values
  programs.bash.initExtra = lib.mkMerge [
    (lib.mkIf config.programs.bash.enable ''
      eval "$(${pkgs.atuin}/bin/atuin init bash)"
    '')
  ];
  programs.fish.interactiveShellInit = lib.mkMerge [
    (lib.mkIf config.programs.fish.enable ''
      ${pkgs.atuin}/bin/atuin init fish | source
    '')
  ];
  programs.zsh.initExtra = lib.mkMerge [
    (lib.mkIf config.programs.zsh.enable ''
      eval "$(${pkgs.atuin}/bin/atuin init zsh)"
    '')
  ];
  programs.nushell.extraEnv = lib.mkMerge [
    (lib.mkIf config.programs.nushell.enable ''
      ${pkgs.atuin}/bin/atuin init nu | save -f ~/.local/share/atuin/init.nu
      source ~/.local/share/atuin/init.nu
    '')
  ];
}
