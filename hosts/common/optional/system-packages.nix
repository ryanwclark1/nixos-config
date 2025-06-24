{
  pkgs,
  ...
}:

# Optional system packages that may not be needed on all systems
# Universal packages are now in hosts/common/global/performance/performance.nix
{
  environment.systemPackages = with pkgs; [
    # Optional development tools
    # Add any truly optional packages here that aren't universally needed
    # Examples:
    # - Language-specific tools
    # - Specialized hardware tools
    # - Development frameworks
  ];
}
