{
  config,
  pkgs,
  ...
}:

{
  programs.go = {
    enable = true;
    package = pkgs.go; # May need to change to a specific version like pkgs.go_1_23
    goPath = "go";
    goBin = "go/bin";
    packages = {
      # "golang.org/x/text" = builtins.fetchGit "https://go.googlesource.com/text";
      # "github.com/air-verse/air" = builtins.fetchGit { url = "https://github.com/air-verse/air"; ref = "master"; };
      # "github.com/mvdan/gofumpt" = builtins.fetchGit "https://https://github.com/mvdan/gofumpt";
      # "github.com/a-h/templ" = builtins.fetchGit "https://github.com/a-h/templ";
      # "golang.org/x/tools/gopls" = builtins.fetchGit "https://golang.org/x/tools/gopls";
      # "golang.org/x/tools/cmd/goimports" = builtins.fetchGit "https://golang.org/x/tools/cmd/goimports";
      # "github.com/go-delve/delve/cmd/dlv" = builtins.fetchGit "https://github.com/go-delve/delve";
      # "gotest.tools/gotestsum" = builtins.fetchGit "https://github.com/gotestyourself/gotestsum";
    };
  };

  home.packages = with pkgs; [
    air       # Live reload for Go apps
    templ     # A language for writing HTML user interfaces in Go.
    golangci-lint-langserver
    gopls
    errcheck
    delve # debugger for the Go programming language
    gofumpt
    gotestsum # 'go test' runner with output optimized
    golangci-lint
    go-callvis
    go-tools
  ];

  home.sessionPath = [
    "${config.home.homeDirectory}/go/bin"
  ];

  home.file."${config.home.homeDirectory}/go/bin/gopls".source = "${pkgs.gopls}/bin/gopls";
  home.file."${config.home.homeDirectory}/go/bin/staticcheck".source = "${pkgs.go-tools}/bin/staticcheck";

  # home.mkOutOfStoreSymlink = "go" "${config.home.homeDirectory}/go" {
  #   src = "${pkgs.go_1_23}";
  # };
  # home.homeDirectory. config.lib.file.mkOutOfStoreSymlink "${config.dotfiles}/config/zsh/p10k.zsh";

}
