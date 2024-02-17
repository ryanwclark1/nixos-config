{ pkgs
, ...
}:

{
  home.packages = with pkgs; [
    nodejs
    nodePackages.npm
    nodePackages.pnpm
    yarn
    deno
    tailwindcss
  ];
  home.sessionPath = [
    "$HOME/.node/bin"
    "$HOME/.deno/bin"
  ];


}
