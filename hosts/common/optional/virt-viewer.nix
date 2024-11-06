{
  pkgs,
  ...
}:

{
  programs.virt-viewer = {
    enable = true;
    package = pkgs.virt-viewer;
  };
}