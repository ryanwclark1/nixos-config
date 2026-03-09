{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    fnm
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
