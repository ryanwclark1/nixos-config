{
  pkgs,
  ...
}:

{
  programs = {
    ripgrep = {
      enable = true;
      arguments = [
        "--hidden"
        "--glob=!.git/*"
        "--glob=!node_modules/*"
        "--glob=!.venv/*"
        "--glob=!/proc/*"
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
