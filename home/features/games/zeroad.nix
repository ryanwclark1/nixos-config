{
  pkgs,
  ...
}:

{
  home = {
    packages = with pkgs; [
      zeroad
    ];
  };
}
