{
  ...
}:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    historyControl = [ "ignoredups" ];
    bashrcExtra = ''
    neofetch
    export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
  '';
  };
  programs.starship.enableBashIntegration = true;
  programs.fzf.enableBashIntegration = true;
  programs.zoxide.enableBashIntegration = true;
  programs.nix-index.enableBashIntegration = true;
  # services.gpg-agent.enableBashIntegration = mkIf config.gpg-agent.enable true;
}