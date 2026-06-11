{
  pkgs,
  lib,
  inputs,
  outputs,
  ...
}:
let
  user = "administrator";
  hostName = "mini";
in
{
  imports = [
    ../common/darwin
  ];

  home-manager.users."${user}" = import ../../home/${hostName}.nix;

  users.users."${user}" = {
    name = "${user}";
    home = "/Users/${user}";
  };

  system.primaryUser = user;

  services.openssh.enable = true;

  services.github-runners.accent-macmini-01 = {
    enable = true;
    url = "https://github.com/AccentCommunications/accent-unified";
    name = "accent-macmini-01";
    tokenFile = "/var/lib/github-runners/accent-macmini-01/registration-token";
    replace = true;
    nodeRuntimes = [ "node24" ];
    extraLabels = [
      "accent-unified"
      "mac-mini"
      "apple-silicon"
      "macos-26"
      "xcode26"
      "ios-simulator"
      "manual"
      "no-docker"
    ];
    extraPackages = with pkgs; [
      bash
      coreutils
      findutils
      gawk
      gnugrep
      gnused
      git
      git-lfs
      gnutar
      gzip
      jq
      nodejs_22
      python313
      ripgrep
      rsync
      swiftlint
      uv
      xcbeautify
      xcodegen
    ];
    extraEnvironment = {
      DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
    };
  };

  system.activationScripts.launchd.text = lib.mkBefore ''
    mkdir -p /var/lib/github-runners
    chown root:wheel /var/lib/github-runners
    chmod 755 /var/lib/github-runners
    echo "ensuring GitHub runner can use Apple developer tools..." >&2
    if dscl . -read /Users/_github-runner >/dev/null 2>&1; then
      if ! dseditgroup -o checkmember -m _github-runner _developer 2>/dev/null | grep -q "yes"; then
        dseditgroup -o edit -a _github-runner -t user _developer
      fi
    fi
  '';

  nix = {
    package = lib.mkDefault pkgs.nixVersions.latest;
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 3;
        Minute = 15;
      };
      options = "--delete-older-than 14d";
    };
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

  system.stateVersion = 5;
}
