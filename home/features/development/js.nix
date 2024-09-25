{
  pkgs,
  ...
}:

{
  home.packages = (with pkgs; [
    bun
    nodejs
    yarn
    deno
    tailwindcss
  ])
  ++ (with pkgs.nodePackages; [
    npm
    pnpm
    ts-node
  ]);
  programs = {
    bun = {
      enable = true;
      package = pkgs.bun;
      enableGitIntegration = true;

    };
  };
}
