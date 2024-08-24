{
  inputs,
  ...
}:

{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];

  nixvim.enable = true;
}