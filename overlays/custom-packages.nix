# Overlay to override packages with custom/newer versions
# This uses the custom package definitions in pkgs/
# Includes: code-cursor, cursor-cli, gemini-cli, claude-code, codex, antigravity, kiro, and vscode-generic
# Note: github-mcp-server is now available in nixpkgs and no longer needs a custom package
final: prev: {
  # Override code-cursor with our custom version
  # Workaround: callPackage incorrectly auto-fills 'meta' from package set
  # Solution: use lib.callPackageWith to exclude meta from auto-args
  code-cursor =
    let
      # Remove meta from final to prevent callPackage from auto-filling it
      pkgsWithoutMeta = builtins.removeAttrs final [ "meta" ];
      # Create a callPackage that excludes meta
      callPackageWithoutMeta = final.lib.callPackageWith pkgsWithoutMeta;
      # Import the package definition
      codeCursorFn = import ../pkgs/code-cursor;
    in
    # Call package definition with callPackageWithoutMeta, explicitly excluding meta
    callPackageWithoutMeta codeCursorFn {
      # Pass callPackageWithoutMeta so it's used for nested callPackage calls
      callPackage = callPackageWithoutMeta;
      # Explicitly do NOT pass meta here - it will be passed in the second argument set
    };

  # Override cursor-cli with our custom version
  cursor-cli = final.callPackage ../pkgs/cursor-cli { };

  # Override gemini-cli with our custom version
  gemini-cli = final.callPackage ../pkgs/gemini-cli { };

  # Override claude-code with our custom version
  claude-code = final.callPackage ../pkgs/claude-code { };

  # Override codex with our custom version
  codex = final.callPackage ../pkgs/codex { };

  # Override antigravity with our custom version
  # Same workaround as code-cursor: exclude meta from auto-filling
  antigravity =
    let
      pkgsWithoutMeta = builtins.removeAttrs final [ "meta" ];
      callPackageWithoutMeta = final.lib.callPackageWith pkgsWithoutMeta;
    in
    callPackageWithoutMeta (import ../pkgs/antigravity) {
      callPackage = callPackageWithoutMeta;
    };

  # Override kiro with our custom version
  # Same workaround as code-cursor: exclude meta from auto-filling
  kiro =
    let
      pkgsWithoutMeta = builtins.removeAttrs final [ "meta" ];
      callPackageWithoutMeta = final.lib.callPackageWith pkgsWithoutMeta;
    in
    callPackageWithoutMeta (import ../pkgs/kiro) {
      callPackage = callPackageWithoutMeta;
    };
}
