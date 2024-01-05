{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  options.slack.enable = mkEnableOption "slack settings";

  config = mkIf config.slack.enable {
    home.packages = with pkgs; [
      # slack-cli #TODO: add back?
      slack
    ];
  };
}