# TODO: update with shell enables
# skim nushell integration?
{
  lib,
  pkgs,
  ...
}:
with lib; {
  programs.skim = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    defaultCommand = "rg --files --hidden";
    changeDirWidgetOptions = [
      "--preview 'eza --icons --git --color always -T -L 3 {} | head -200'"
      "--exact"
    ];
  };
  home.packages = with pkgs; [fd];
}
