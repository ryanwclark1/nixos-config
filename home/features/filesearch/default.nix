{
  pkgs,
  ...
}:

{
  programs = {
    ripgrep = {
      enable = true;
      arguments = [
        "--glob=!.git/*"
        "--glob=!node_modules/*"
        "--glob=!.venv/*"
        "--smart-case"
      ];
    };
  };

  home.packages = with pkgs; [
    fd
    # ripgrep-all
    sd
  ];
}
