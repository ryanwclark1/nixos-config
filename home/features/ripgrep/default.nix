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
        "--glob=!dist/*"
        "--glob=!.venv/*"
        "--glob=!/proc"
        "--glob=!/sys"
        "--hidden"
        "--no-follow"
        "--smart-case"
      ];
    };
  };

  home.packages = with pkgs; [
    fd
    # ripgrep-all
    sd
    tree
  ];
}
