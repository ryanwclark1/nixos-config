{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    nodejs_22
    yarn
    # npm is included with nodejs_22
    # nodePackages may cause conflicts
    # deno
  ];
  programs = {
    bun = {
      enable = true;
      package = pkgs.bun;
      enableGitIntegration = true;
    };
  };
}
