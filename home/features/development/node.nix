{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    nodejs
    nodePackages.npm
    nodePackages.pnpm
    yarn
  ];
  home.sessionPath = ["$HOME/.node/bin"];

}