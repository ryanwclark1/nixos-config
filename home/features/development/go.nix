{
  pkgs,
  ...
}:

{
  programs.go = {
    enable = true;
    package = pkgs.go_1_22;
    goPath = "go";
  };

  home.packages = with pkgs; [
    golangci-lint-langserver
    gopls
    errcheck
    templ
  ];
  home.sessionPath = [ "$HOME/go/bin" ];
}
