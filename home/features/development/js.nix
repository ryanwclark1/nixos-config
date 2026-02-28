{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    nodePackages.nodejs
    pnpm
    yarn
    biome
  ];
  programs = {
    bun = {
      enable = true;
      package = pkgs.bun;
      enableGitIntegration = true;
    };
  };
}
