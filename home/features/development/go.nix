{
  pkgs,
  ...
}:

{

  programs.go = {
    enable = true;
    package = pkgs.go_1_21;
    goPath = "go";
  };

  home.packages = with pkgs; [
    richgo
    golangci-lint-langserver
    ent-go
    go-tools
    gopls
    godef
    gotools
    errcheck
  ];

  home.sessionPath = [ "$HOME/go/bin" ];

}
