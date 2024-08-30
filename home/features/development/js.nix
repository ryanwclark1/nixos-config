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
    deno
    tailwindcss
    # npm
    # pnpm
  ])
  ++ (with pkgs.nodePackages; [
    npm
    pnpm
  ]);
}
