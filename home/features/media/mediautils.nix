{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    pavucontrol
    playerctl
    pulsemixer
  ];

  programs = {
    mpv = {
      enable = true;
      defaultProfiles = [ "gpu-hq" ];
      scripts = [ pkgs.mpvScripts.mpris ];
    };
  };

  services = {
    playerctld.enable = true;
  };
}
