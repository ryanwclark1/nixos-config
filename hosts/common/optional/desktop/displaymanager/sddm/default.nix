{
  inputs,
  lib,
  pkgs,
  ...
}:
# let
#   # sddmTheme = "breeze";
#   sddmTheme = import ./sddm-theme.nix { inherit pkgs; };
# in
let
   # an exhaustive example can be found in flake.nix
   sddm-theme = inputs.silentSDDM.packages.${pkgs.system}.default.override {
      theme = "default"; # select the config of your choice
   };
in
{

  # environment.systemPackages = with pkgs; [
  #   sddm-astronaut
  #   (catppuccin-sddm.override {
  #     flavor = "frappe";
  #     font = "Fira Sans";
  #     fontSize = "10";
  #     # background = "/path/to/your/wallpaper.jpg";
  #     loginBackground = false;
  #   })
  # ];
  environment.systemPackages = with pkgs; [
    sddm-theme
  ];
  qt.enable = true;
  services = {
    xserver.enable = lib.mkDefault true;
    displayManager = {
      defaultSession = lib.mkDefault "hyprland-uwsm";
      sddm = {
        enable = true;
        # wayland = {
        #   enable = true;
        #   compositor = "weston";
        # };
        # autoNumlock = true;
        # enableHidpi = true;
        package = pkgs.kdePackages.sddm;
        # theme "= "${sddmTheme}";
        # theme = "catppuccin-frappe";
        theme = sddm-theme.pname;
        # settings.Theme.CursorTheme = "Bibata-Modern-Classic";
        # extraPackages = with pkgs; [
        #   kdePackages.qtmultimedia
        #   kdePackages.qtsvg
        #   kdePackages.qtvirtualkeyboard
        # ];
        extraPackages = sddm-theme.propagatedBuildInputs;
        settings = {
          # required for styling the virtual keyboard
          General = {
            GreeterEnvironment = "QML2_IMPORT_PATH=${sddm-theme}/share/sddm/themes/${sddm-theme.pname}/components/,QT_IM_MODULE=qtvirtualkeyboard";
            InputMethod = "qtvirtualkeyboard";
          };
        };
      };
    };
  };
}
