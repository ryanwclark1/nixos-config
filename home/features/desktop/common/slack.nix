{
  pkgs,
  ...
}:

{
  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/slack" = "slack.desktop";
  };
  home.packages = with pkgs; [
    slack
  ];
}
