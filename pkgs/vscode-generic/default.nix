# This file re-exports the generic.nix builder for VS Code-based applications
# Packages use: callPackage ../vscode-generic/generic.nix { } directly
# This default.nix exists for completeness and potential future use

{
  callPackage,
  ...
}@args:

callPackage ./generic.nix args
