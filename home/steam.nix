{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    steam
    steam-run
    lunar-client
    lutris
    vulkan-loader
    vulkan-tools
    # wineWowPackages.stagingFull
  ];
}


{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  options.watson.enable = mkEnableOption "watson settings";

  config = mkIf config.watson.enable {
    programs.watson = {
      enable = true;
      package = pkgs.go_1_21;
      packages = {
        # "golang.org/x/text" = builtins.fetchGit "https://go.googlesource.com/text";
      };
      goPath = "go";
    };

    home.packages = with pkgs; [
      richgo
      golangci-lint-langserver
      ent-go
      go-tools
      gocode
      gopls
      godef
      gotools
      errcheck
    ];

    home.sessionPath = ["$HOME/go/bin"];
  };
}
