{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    historyControl = [ "ignoredups" ];
    bashrcExtra = ''
      neofetch
    '';
  };
  programs.fzf.enableBashIntegration = mkIf config.programs.starship.enable true;
  programs.nix-index.enableBashIntegration = mkIf config.programs.starship.enable true;
  programs.starship.enableBashIntegration = mkIf config.programs.starship.enable true;
  programs.zoxide.enableBashIntegration = mkIf config.programs.starship.enable true;
}
