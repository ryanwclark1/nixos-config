{
  pkgs,
  ...
}:

{
  programs.obs-studio = {
    enable = true;
    programs = pkgs.obs-studio;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-pipewire-audio-capture
    ];
  };
}
