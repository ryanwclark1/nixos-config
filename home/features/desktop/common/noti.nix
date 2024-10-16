# Monitor a process and trigger a notification.
{
  pkgs,
  ...
}:

{
  programs.noti = {
    enable = true;
    settings = {
      espeak = {
        voiceName = "english-us";
      };
    };
  };

  home.packages = with pkgs; [
    espeak-classic
  ];

}