{
  pkgs,
  lib,
  ...
}:

{
  # Override gemini-cli package with custom version
  # Use: gemini-cli-version latest    # to get latest version info
  # Use: gemini-cli-version check X.Y.Z  # to get hash for specific version  
  # Use: gemini-cli-version update X.Y.Z # to auto-update this file
  #
  # Current nixpkgs applies: restore-missing-dependencies-fields.patch
  # If build fails with newer versions, try: patches = [];
  
  home.packages = with pkgs; [
    (gemini-cli.overrideAttrs (oldAttrs: rec {
      version = "0.3.2";  # Current nixpkgs version - update as needed
      
      src = pkgs.fetchFromGitHub {
        owner = "google-gemini";
        repo = "gemini-cli";
        tag = "v${version}";
        # Use: gemini-cli-version check 0.3.2
        hash = "sha256-0438x6kdmqvc0yglk2m5axdbc7zb9fdsvpws6625pzw3j7rms041";
      };
      
      # Update npm dependencies hash if build fails
      # Run: nix-build '<nixpkgs>' -A gemini-cli
      # Use the hash from the error message
      npmDepsHash = "sha256-gpNt581BHDA12s+3nm95UOYHjoa7Nfe46vgPwFr7ZOU=";
      
      # Keep existing patches from nixpkgs (remove if they cause issues with newer versions)
      patches = oldAttrs.patches or [];
    }))
  ];
}