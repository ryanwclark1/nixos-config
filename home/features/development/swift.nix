{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    swift
    swiftpm
  ];
}
