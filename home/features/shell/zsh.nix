{

  pkgs,
  ...
}:

{
  programs.zsh = {
    enable = true;
    package = pkgs.zsh;
    enableCompletion = true;
    enableVteIntegration = true;
    # defaultKeymap = "vicmd";
    syntaxHighlighting = {
      enable = true;
    };
    autosuggestion = {
      enable = true;
    };
  };

}
