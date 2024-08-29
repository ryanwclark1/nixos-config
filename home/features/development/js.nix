{
  pkgs,
  ...
}:

{
  home.packages = (with pkgs; [
    bun
    nodejs
    nodePackages.npm
    nodePackages.pnpm
    yarn
    # deno
    tailwindcss
    npm
    pnpm
  ]);
  # )
  # ++ (with pkgs.nodePackages; [

  # ])
  # ;


  home.sessionPath = [
    "$HOME/.node/bin"
    "$HOME/.deno/bin"
    "$HOME/.bun/bin"
  ];


}
