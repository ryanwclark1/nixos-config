{
  config,
  lib,
  pkgs,
  ...
}:

let
  atuinConfigDir = "${config.home.homeDirectory}/.config/atuin";
  atuinSettings = {
    auto_sync = true;
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
    prefers_reduced_motion = false;

    keymap_cursor = {
      emacs = "blink-block";
      vim_insert = "blink-block";
      vim_normal = "steady-block";
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
  tomlFormat = pkgs.formats.toml { };
in
{
  sops.secrets = {
    atuin-key = {
      sopsFile = ../../../secrets/secrets.yaml;
    };
  };

  home.packages = [ pkgs.atuin ];

  home.file."${atuinConfigDir}/config.toml" = {
    force = true;
    source = tomlFormat.generate "atuin-config" atuinSettings;
  };

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
  programs.zsh.initContent = lib.mkMerge [
    (lib.mkIf config.programs.zsh.enable ''
      eval "$(${pkgs.atuin}/bin/atuin init zsh)"
    '')
  ];
  programs.nushell.extraEnv = lib.mkMerge [
    (lib.mkIf config.programs.nushell.enable ''
      ${pkgs.atuin}/bin/atuin init nu | save -f ~/.local/share/atuin/init.nu
      if ("~/.local/share/atuin/init.nu" | path exists) {
        source ~/.local/share/atuin/init.nu
      }
    '')
  ];
}
