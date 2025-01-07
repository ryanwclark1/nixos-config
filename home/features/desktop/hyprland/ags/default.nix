{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.ags.homeManagerModules.default
  ];

  programs.ags = {
    enable = true;
    extraPackages = with pkgs; [
      inputs.ags.packages.x86_64-linux.battery
      inputs.ags.packages.x86_64-linux.hyprland
      inputs.ags.packages.x86_64-linux.tray
      inputs.ags.packages.x86_64-linux.apps
      inputs.ags.packages.x86_64-linux.battery
      inputs.ags.packages.x86_64-linux.bluetooth
      inputs.ags.packages.x86_64-linux.mpris
      inputs.ags.packages.x86_64-linux.network
      inputs.ags.packages.x86_64-linux.notifd
      inputs.ags.packages.x86_64-linux.powerprofiles
      inputs.ags.packages.x86_64-linux.wireplumber
      inputs.ags.packages.x86_64-linux.io # Astal cli
    ] ++ (with pkgs; [
      typescript
      dart-sass
      gobject-introspection
      libgtop
      (python3.withPackages (ps:
        with ps; [
          gpustat
          dbus-python
          pygobject3
        ]))
    ]);
  };
  # programs.matugen = {
  #   enable = true;
  #   variant = "dark";
  #   jsonFormat = "hex";
  # };
}