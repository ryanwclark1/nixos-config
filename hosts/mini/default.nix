{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  user = "administrator";
  hostName = "mini";
in
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    # ../../home/mini.nix
  ];
  # ++
  # (builtins.attrValues outputs.darwinModules);

  home-manager = {
    # useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = {
      inherit inputs outputs;
    };
  };

  home-manager.users."${user}" = import ../../home/${hostName}.nix;

  users.users."${user}" = {
    name = "${user}";
    home = "/Users/${user}";
  };

  # The platform the configuration will be used on.
  # Remove allowBroken
  nixpkgs = {
    hostPlatform = lib.mkDefault "aarch64-darwin";
    config.allowBroken = lib.mkDefault true;
    config.allowUnfree = true;
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    neovim
    alacritty
    mkalias
    tmux
    git
  ];

  # homebrew = {
  #   enable = true;
  #   brews = [
  #     "mas"
  #   ];
  #   casks = [
  #     "hammerspoon"
  #     "firefox"
  #     "iina"
  #     "the-unarchiver"
  #   ];
  #   # masApps = {
  #   #   "Yoink" = 457622435;
  #   # };
  #   onActivation.cleanup = "zap";
  # };

  # programs.home-manager.enable = true;
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

  system.activationScripts.applications.text = let
    env = pkgs.buildEnv {
      name = "system-applications";
      paths = config.environment.systemPackages;
      pathsToLink = "/Applications";
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
      autohide  = true;
      persistent-apps = [
        "${pkgs.alacritty}/Applications/Alacritty.app"
        # "/Applications/Firefox.app"
        "/System/Applications/Calendar.app"
      ];
    };

    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "clmv";
    };

    # loginwindow.GuestEnabled  = false;
    NSGlobalDomain = {
      AppleICUForce24HourTime = true;
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
    };
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  nix = {
    package = lib.mkDefault pkgs.nixVersions.latest;
    settings = {
      # Necessary for using flakes on this system.
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };
  # nix.package = pkgs.nix;

  # Enable alternative shell support in nix-darwin.
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
}
