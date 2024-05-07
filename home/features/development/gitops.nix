{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    weave-gitops
  ];
}
