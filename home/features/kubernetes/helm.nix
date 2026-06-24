{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    kubernetes-helm
  ];

  programs.bash.bashrcExtra = lib.mkIf config.programs.bash.enable ''
    # Helm completion
    if shopt -q progcomp 2>/dev/null; then
      if command -v helm &> /dev/null; then
        source <(helm completion bash 2>/dev/null | grep -v "shopt.*progcomp" || true)
      fi
    fi
  '';

  programs.fish.interactiveShellInit = lib.mkIf config.programs.fish.enable ''
    # Helm completion
    if command -v helm &> /dev/null
      helm completion fish | source
    end
  '';

  programs.zsh.initContent = lib.mkIf config.programs.zsh.enable ''
    # Helm completion
    if command -v helm &> /dev/null; then
      source <(helm completion zsh)
    fi
  '';
}
