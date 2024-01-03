{
  lib,
  config,
  ...
}:
with lib; {
  options.bash.enable = mkEnableOption "bash settings";

  config = mkIf config.bash.enable {
    programs.bash = {
      enable = true;
      enableCompletion = true;
      enableVteIntegration = true;
      bashrcExtra = ''
      neofetch
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
    '';
    };
    programs.starship.enableBashIntegration = true;
    programs.fzf.enableBashIntegration = mkIf config.fzf.enable true;
    programs.zoxide.enableBashIntegration = true;
    # programs.nix-index.enableBashIntegration = true;
    # services.gpg-agent.enableBashIntegration = true;
  };
}