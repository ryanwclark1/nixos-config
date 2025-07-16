# This file defines overlays
{
  ...
}:

{
  # Custom packages overlay
  custom = final: prev: {
    custom = import ../pkgs { pkgs = final; };
  };
}

