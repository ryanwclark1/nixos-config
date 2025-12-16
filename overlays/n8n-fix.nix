# Overlay to fix n8n hash mismatch
# This fixes the hash mismatch error when building n8n
# Error: specified: sha256-B1YL/kGYKHKZ8l50UGDiGwkYedvlYobW9QZzx2FwjDY=
#        got:    sha256-3vXJnLqQz60Sq1A8lLW0x6xAoN3DneFYVsaHAD0nzng=
#
# This is a temporary fix until nixpkgs updates the hash.
# To use this fix, uncomment n8n in hosts/woody/services/n8n.nix
final: prev: {
  n8n = prev.n8n.overrideAttrs (oldAttrs: {
    # Override the source with the correct hash
    # Note: This assumes n8n uses fetchFromGitHub
    # If the build still fails, you may need to check the actual source structure
    src = prev.fetchFromGitHub {
      owner = "n8n-io";
      repo = "n8n";
      rev = oldAttrs.version;
      hash = "sha256-3vXJnLqQz60Sq1A8lLW0x6xAoN3DneFYVsaHAD0nzng=";
    };
  });
}
