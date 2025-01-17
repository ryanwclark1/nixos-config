{
  pkgs,
  ...
}:

{
  programs.obs-studio = {
    enable = false;
    package = pkgs.obs-studio;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-pipewire-audio-capture
    ];
  };
}
