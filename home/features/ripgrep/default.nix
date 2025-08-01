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
        "--max-columns=150"
        "--max-columns-preview"
        "--type-add=web:*.{html,css,js}*"
      ];
    };
  };

  home.packages = with pkgs; [
    ripgrep-all
    sd
    repgrep # ripgrep with replacement support
    fselect
  ];
}
