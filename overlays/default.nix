# overlays/default.nix
{
  inputs,
  outputs,
  ...
}:

[
  # Your existing custom packages overlay
  (final: prev: {
    custom = import ../pkgs { pkgs = final; };
  })

  # The CMake compatibility overlay
  (import ./cmake-compat.nix)
]
