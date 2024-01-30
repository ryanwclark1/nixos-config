# Terminal history search
# https://atuin.sh/docs/
# Updated when enter is pressed select not execute.

{
  ...
}:

{
  programs.atuin = {
    enable = true;
    flags = ["--disable-up-arrow"];
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };
}