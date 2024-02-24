{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    amdgpu_top
  ];

}