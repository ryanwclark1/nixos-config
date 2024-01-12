{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  d = config.xdg.dataHome;
  c = config.xdg.configHome;
  cache = config.xdg.cacheHome;
in

{

  # TODO: Remove this in home.nix
  nixpkgs.config.allowUnfree = true;

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "administrator";
  home.homeDirectory = "/home/administrator";
  imports = [
    ../../home/shells/bash.nix
    ../../home/shells/zsh.nix
    ../../home/development
    ../../home/editors/vscode.nix
    ../../home/editors/insomnia.nix
    ../../home/media
    ../../home/terminalutils
    ../../home/terminals/alacritty.nix
    ../../home/terminals/kitty.nix
    ../../home/chromium.nix
    ../../home/colors.nix
    ../../home/compression.nix
    ../../home/download.nix
    ../../home/exercism.nix
    ../../home/filezilla.nix
    ../../home/firefox.nix
    ../../home/global-fonts.nix
    ../../home/monitor.nix
    ../../home/office.nix
    ../../home/ollama.nix
    ../../home/pandoc.nix
    ../../home/slack.nix
    ../../home/starship.nix
    ../../home/steam.nix
    ../../home/watson.nix
    ../../home/networking_utils.nix
    ../../home/common_desktop.nix
  ];
  bash.enable = true;
  zsh.enable = true;
  alacritty.enable = true;
  development.enable = true;
  media.enable = true;
  terminalutils.enable = true;
  compression.enable = true;
  download.enable = true;
  exercism.enable = true;
  filezilla.enable = true;
  insomnia.enable = true;
  kitty.enable = true;
  monitor.enable = true;
  office.enable = true;
  ollama.enable = true;
  pandoc.enable = true;
  # pdf.enable = false;
  slack.enable = true;
  steam.enable = true;
  watson.enable = true;
  # xdg.enable = false;
  networking_utils.enable = true;
  common_desktop.enable = true;

  chromium.enable = true;
  firefox.enable = true;

  starship.enable = true;
  vscode.enable = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.

  # Moved to ../home/common_desktop.nix, use if different by machine
  # home.packages = with pkgs; []


  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/administrator/etc/profile.d/hm-session-vars.sh

  # shell.user = "${pkgs.bash}/bin/bash";
  # editor = {
  #   terminal = "${config.editor.helix.package}/bin/hx";
  #   helix.package = inputs.helix.packages.${pkgs.system}.default;
  # };
  # terminal = "${pkgs.alacritty}/bin/alacritty";

  home.sessionVariables = {
    # EDITOR = "emacs";
    # clean up ~
    LESSHISTFILE = cache + "/less/history";
    LESSKEY = c + "/less/lesskey";
    WINEPREFIX = d + "/wine";

    # set default applications
    # EDITOR = "nvim";
    # BROWSER = "firefox";
    TERMINAL = "alacritty";

    # enable scrolling in git diff
    DELTA_PAGER = "less -R";

    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
