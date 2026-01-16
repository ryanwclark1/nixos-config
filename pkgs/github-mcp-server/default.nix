{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "github-mcp-server";
  # Update this to a specific tag/commit for reproducible builds
  # You can find the latest release at: https://github.com/github/github-mcp-server/releases
  version = "unstable-2024-12-20";

  src = fetchFromGitHub {
    owner = "github";
    repo = "github-mcp-server";
    # Using main branch - update to a specific tag/commit for stability
    # Example: rev = "v1.0.0"; or rev = "abc123def...";
    rev = "refs/heads/main";
    hash = "sha256-fuuOKGgIXpLNJs5P5RZv+I/gFtiLmp7gcIK1RpPA7Ig=";
  };

  # Use proxyVendor to bypass vendor directory issues when tracking main branch
  # This fetches dependencies directly instead of using the vendor directory
  proxyVendor = true;
  vendorHash = "";

  subPackages = [ "cmd/github-mcp-server" ];

  meta = with lib; {
    description = "GitHub MCP Server - connects AI tools directly to GitHub's platform";
    homepage = "https://github.com/github/github-mcp-server";
    license = licenses.mit;
    mainProgram = "github-mcp-server";
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
