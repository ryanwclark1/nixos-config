{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../../home/theme
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = {
      inherit inputs outputs;
    };
  };

  nixpkgs = {
    hostPlatform = lib.mkDefault "aarch64-darwin";
    config.allowBroken = lib.mkDefault true;
    config.allowUnfree = true;
    overlays = builtins.attrValues outputs.overlays;
  };

  environment.systemPackages = with pkgs; [
    neovim
    alacritty
    mkalias
    tmux
    git
  ];

  nix-homebrew = {
    enable = true;
    user = config.system.primaryUser;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    taps = [
      "nikitabobko/tap"
    ];
    casks = [
      "google-chrome"
      "antigravity"
      "antigravity-cli"
      "claude"
      "codex"
      "aerospace"
      "ghostty"
      "cursor"
      "tailscale-app"
    ];
  };

  programs.zsh.enable = true;

  fonts = {
    packages = with pkgs; [
      nerd-fonts.dejavu-sans-mono
      nerd-fonts.droid-sans-mono
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      nerd-fonts.jetbrains-mono
      nerd-fonts.monaspace
      nerd-fonts.noto
      nerd-fonts.ubuntu
      nerd-fonts.ubuntu-mono
      nerd-fonts.ubuntu-sans
      noto-fonts
      noto-fonts-color-emoji
      liberation_ttf
      powerline-symbols
    ];
  };

  system.activationScripts.applications.text =
    let
      env = pkgs.buildEnv {
        name = "system-applications";
        paths = config.environment.systemPackages;
        pathsToLink = [ "/Applications" ];
      };
    in
    pkgs.lib.mkForce ''
      # Set up applications.
      echo "setting up /Applications..." >&2
      rm -rf /Applications/Nix\ Apps
      mkdir -p /Applications/Nix\ Apps
      find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
      while read -r src; do
        app_name=$(basename "$src")
        echo "copying $src" >&2
        ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
      done
    '';

  system.defaults = {
    dock = {
      autohide = true;
      persistent-apps = [
        "${pkgs.alacritty}/Applications/Alacritty.app"
        "/System/Applications/Calendar.app"
      ];
    };

    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "clmv";
    };

    NSGlobalDomain = {
      AppleICUForce24HourTime = true;
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
    };
  };

  # Determinate installer manages the Nix daemon on Darwin hosts.
  nix.enable = false;

  system.stateVersion = 5;
}
