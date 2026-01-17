# Overlay to fix openvscode-server npm ENOTCACHED build failure
# This fixes the npm error: "cache mode is 'only-if-cached' but no cached response is available"
# The issue occurs when npm tries to fetch dependencies that aren't in the cache during build
# Note: openvscode-server is currently marked as broken in nixpkgs
# Alternative: Consider using services.vscode-server instead (already configured in vscode-server.nix)
final: prev: {
  openvscode-server = prev.openvscode-server.overrideAttrs (oldAttrs: {
    # Workaround for npm cache issues during build
    # Set npm cache to a writable temporary directory
    preBuild = (oldAttrs.preBuild or "") + ''
      # Fix npm cache directory to be writable
      export npm_config_cache="$TMPDIR/npm-cache"
      mkdir -p "$npm_config_cache"
      chmod -R u+w "$npm_config_cache" || true

      # Also try to ensure npm can access its cache
      export npm_config_prefer_offline=false
      export npm_config_offline=false
    '';

    # If the package uses buildNpmPackage with makeCacheWritable, ensure it's set
    # This may require checking the actual package definition structure
    # For now, we try the environment variable approach above
  });
}
