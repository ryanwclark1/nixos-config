# Man pages and info documentation configuration
{ lib, ... }:

{
  # Info reader configuration
  programs.info.enable = true;

  # Man pages configuration
  programs.man = {
    enable = true;
    generateCaches = false;  # Set to true if you want faster man page lookups
  };

  # Man page display configuration via sessionVariables in shell/common.nix:
  # - MANPAGER for colored man pages using bat
  # - MANROFFOPT for proper formatting
  # - LESS_TERMCAP_* variables for colored output when using standard less
}