{ config
, pkgs
, lib
, ...
}:
with lib;

{
  imports = [
    ./waybar.nix
  ];

  home = {
    file.".config/stinger.mov".source = ./media/stinger.mov;
    file.".config/pipewire/pipewire.conf".source = ./config/pipewire/pipewire.conf;
    file.".vimrc".source = ./config/vimrc;
    file.".emoji".source = ./config/emoji;
    file.".face".source = ./config/face.jpg;
    file."Pictures/Wallpapers" = {
      source = ./media/wallpapers;
      recursive = true;
    };
    file.".local/share/fonts" = {
      source = ./fonts;
      recursive = true;
    };
    file.".config/rofi" = {
      source = ./config/rofi;
      recursive = true;
    };
    file.".config/swaync" = {
      source = ./config/swaync;
      recursive = true;
    };
    file.".config/hypr" = {
      source = ./config/hyprland;
      recursive = true;
    };
  };

  xresources.properties = {
    "Xcursor.size" = 24;
  };


  home.packages = with pkgs; [
    lolcat
    cmatrix
    discord
    btop
    libvirt
    swww
    polkit_gnome
    grim
    slurp
    lm_sensors
    gnome.file-roller
    libnotify
    swaynotificationcenter
    rofi-wayland
    imv
    v4l-utils
    ydotool
    wl-clipboard
    socat
    cowsay
    lsd
    pkg-config
    transmission-gtk
    kdenlive
    meson
    glibc
    hugo
    gnumake
    ninja
    godot_4
    rustup
    pavucontrol
    audacity
    zeroad
    xonotic
    openra
    font-awesome
    symbola
    noto-fonts-color-emoji
    material-icons
    spotify
    # Import Scripts
    (import ./scripts/emopicker9000.nix { inherit pkgs; })
    (import ./scripts/task-waybar.nix { inherit pkgs; })
    (import ./scripts/squirtle.nix { inherit pkgs; })
    (import ./scripts/wallsetter.nix { inherit pkgs; })
  ];

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };
  qt.enable = true;
  qt.platformTheme = "gtk";
  qt.style.name = "adwaita-dark";
  qt.style.package = pkgs.adwaita-qt;
  gtk = {
    enable = true;
    font = {
      name = "Ubuntu";
      size = 12;
      package = pkgs.ubuntu_font_family;
    };
    theme = {
      name = "Tokyonight-Storm-BL";
      package = pkgs.tokyo-night-gtk;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
    };
    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };
  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    bashrcExtra = ''
      neofetch
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
    '';
    profileExtra = ''
      #if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
      #  exec Hyprland
      #fi
    '';
  };
  programs.starship.enableBashIntegration = true;
  programs.fzf.enableBashIntegration = mkIf config.fzf.enable true;
  programs.zoxide.enableBashIntegration = true;
  # programs.nix-index.enableBashIntegration = true;
  # services.gpg-agent.enableBashIntegration = true;

  # sessionVariables = {

  # };
  # shellAliases = {
  # sv="sudo vim";
  # flake-rebuild="sudo nixos-rebuild switch --flake ~/xxxxxxx/#workstation";
  # laptop-rebuild="sudo nixos-rebuild switch --flake ~/xxxxxxxx/#laptop";
  # v="vim";
  # ls="lsd";
  # ll="lsd -l";
  # la="lsd -a";
  # lal="lsd -al";
  # ".."="cd ..";
  # };
  # };


}
