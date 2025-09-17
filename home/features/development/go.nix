{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.go = {
    enable = true;
    package = pkgs.go_1_23; # Use latest stable Go version
    goPath = "go";
    goBin = "go/bin";
    
    # Environment variables for Go
    env = {
      # Go development settings
      GO111MODULE = "on";
      GOPROXY = "https://proxy.golang.org,direct";
      GOSUMDB = "sum.golang.org";
      GOPRIVATE = "github.com/accent-ai/*,gitlab.com/*";
      
      # Build and compile settings
      CGO_ENABLED = "1";
      GOARCH = "amd64";
      GOOS = "linux";
      
      # Module cache and workspace
      GOMODCACHE = "${config.home.homeDirectory}/go/pkg/mod";
      GOCACHE = "${config.home.homeDirectory}/.cache/go-build";
      
      # Development tools
      GOFLAGS = "-buildvcs=true";
      
      # Testing
      GOTESTSUM_FORMAT = "testname";
      GOTEST_PALETTE = "cyan:yellow:green:magenta:red:gray";
    };
    
    # Telemetry configuration
    telemetry = "off"; # Options: "on", "off", "local"
    
    # Go packages to install
    packages = {
      # Core tools
      "golang.org/x/tools/gopls" = builtins.fetchGit {
        url = "https://go.googlesource.com/tools";
        ref = "master";
      };
      
      "golang.org/x/tools/cmd/goimports" = builtins.fetchGit {
        url = "https://go.googlesource.com/tools";
        ref = "master";
      };
      
      # Development tools
      "github.com/air-verse/air" = builtins.fetchGit { 
        url = "https://github.com/air-verse/air"; 
        ref = "master"; 
      };
      
      "github.com/mvdan/gofumpt" = builtins.fetchGit {
        url = "https://github.com/mvdan/gofumpt";
        ref = "master";
      };
      
      "github.com/a-h/templ/cmd/templ" = builtins.fetchGit {
        url = "https://github.com/a-h/templ";
        ref = "main";
      };
      
      # Debugging
      "github.com/go-delve/delve/cmd/dlv" = builtins.fetchGit {
        url = "https://github.com/go-delve/delve";
        ref = "master";
      };
      
      # Testing
      "gotest.tools/gotestsum" = builtins.fetchGit {
        url = "https://github.com/gotestyourself/gotestsum";
        ref = "main";
      };
      
      # Code analysis
      "github.com/golangci/golangci-lint/cmd/golangci-lint" = builtins.fetchGit {
        url = "https://github.com/golangci/golangci-lint";
        ref = "master";
      };
      
      "honnef.co/go/tools/cmd/staticcheck" = builtins.fetchGit {
        url = "https://github.com/dominikh/go-tools";
        ref = "master";
      };
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

  # Additional session environment variables for Go
  home.sessionVariables = {
    # Go telemetry settings
    GOTELEMETRY = "off"; # Disable telemetry completely
    GOTELEMETRYDIR = "${config.home.homeDirectory}/.cache/go-telemetry"; # Telemetry data directory if enabled
    
    # Go workspace
    GOPATH = "${config.home.homeDirectory}/go";
    GOBIN = "${config.home.homeDirectory}/go/bin";
    
    # Go module settings
    GOPROXY = "https://proxy.golang.org,direct";
    GOSUMDB = "sum.golang.org";
    GOPRIVATE = "github.com/accent-ai/*,gitlab.com/*";
    GO111MODULE = "on";
    
    # Build performance
    GOMAXPROCS = "0"; # Use all available CPU cores (0 = auto)
    
    # Testing
    GORACE = "halt_on_error=1";
  };

  home.file."${config.home.homeDirectory}/go/bin/gopls".source = "${pkgs.gopls}/bin/gopls";
  home.file."${config.home.homeDirectory}/go/bin/staticcheck".source = "${pkgs.go-tools}/bin/staticcheck";

  # Create Go workspace directories
  home.file."${config.home.homeDirectory}/go/src/.keep".text = "";
  home.file."${config.home.homeDirectory}/go/pkg/.keep".text = "";
  home.file."${config.home.homeDirectory}/go/bin/.keep".text = "";
  
  # Go configuration file for default module proxy and sumdb
  home.file."${config.home.homeDirectory}/.config/go/env" = {
    text = ''
      GOTELEMETRY=off
      GOTELEMETRYDIR=${config.home.homeDirectory}/.cache/go-telemetry
      GO111MODULE=on
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
