{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.go = {
    enable = true;
    package = pkgs.go;
  };

  home.packages = with pkgs; [
    # Language server and tooling
    gopls
    golangci-lint
    golangci-lint-langserver
    go-tools

    # Development tools
    air
    delve
    errcheck
    go-callvis
    gofumpt
    gotestsum
    templ
  ];

  home.sessionPath = [
    "${config.home.homeDirectory}/go/bin"
  ];

  home.sessionVariables = {
    GOPATH = "${config.home.homeDirectory}/go";
    GOBIN = "${config.home.homeDirectory}/go/bin";
    GORACE = "halt_on_error=1";
  };

  home.file."${config.home.homeDirectory}/go/bin/.keep".text = "";

  xdg.configFile."go/env" = {
    text = ''
      GOTELEMETRY=off
      GOPROXY=https://proxy.golang.org,direct
      GOSUMDB=sum.golang.org
      GOPRIVATE=github.com/accent-ai/*,gitlab.com/*
      GOMODCACHE=${config.home.homeDirectory}/go/pkg/mod
      GOCACHE=${config.home.homeDirectory}/.cache/go-build
      CGO_ENABLED=1
      GOFLAGS=-buildvcs=true
    '';
  };
}
