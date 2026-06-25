{
  inputs ? { },
}:

# Overlay to override packages with custom/newer versions.
# This uses the custom package definitions in pkgs/ and Qumulo's llm-agents
# flake for fast-moving AI agent ecosystem packages.
# Includes: code-cursor, cursor-cli, antigravity-cli, antigravity-ide,
# claude-code, claude-code-bin, codex, antigravity, kiro, vscode-generic,
# plus Beads/Gastown/WorkMux/GitButler/skills/proxy tooling from llm-agents.
# Note: github-mcp-server is now available in nixpkgs and no longer needs a custom package
final: prev:
let
  system = final.stdenv.hostPlatform.system;
  llmAgents =
    if
      inputs ? llm-agents
      && inputs.llm-agents ? packages
      && builtins.hasAttr system inputs.llm-agents.packages
    then
      inputs.llm-agents.packages.${system}
    else
      { };
  mcpServersNix =
    if
      inputs ? mcp-servers-nix
      && inputs.mcp-servers-nix ? packages
      && builtins.hasAttr system inputs.mcp-servers-nix.packages
    then
      inputs.mcp-servers-nix.packages.${system}
    else
      { };

  fromLlmAgents =
    name: fallback:
    if builtins.hasAttr name llmAgents then builtins.getAttr name llmAgents else fallback;
  fromMcpServersNix =
    name: fallback:
    if builtins.hasAttr name mcpServersNix then builtins.getAttr name mcpServersNix else fallback;
in
{
  llm-agents = llmAgents;
  mcp-servers-nix = mcpServersNix;

  # Agent Desk platform layers from Qumulo/llm-agents.
  beads = fromLlmAgents "beads" prev.beads;
  beads-rust = fromLlmAgents "beads-rust" null;
  beads-viewer = fromLlmAgents "beads-viewer" null;
  mardi-gras = fromLlmAgents "mardi-gras" null;
  # gastown: deploy a local reaper/compact fix (real wisp_dependencies depends-on
  # columns) on top of the llm-agents v1.2.1 build. The fix is a single commit on
  # the v1.2.1 base with NO go.mod/go.sum change, so we reuse the upstream
  # buildGoModule vendor derivation and only swap in the patched source.
  # Source: local fork branch fix/wisp-depends-col @ a2699f79 (ryanwclark1/gastown).
  # TODO(reproducibility): once the fix lands upstream in llm-agents, drop this
  # override. To make it portable beyond this machine, push the branch and switch
  # src to fetchFromGitHub.
  gastown =
    let
      base = fromLlmAgents "gastown" null;
    in
    if base == null then
      null
    else
      base.overrideAttrs (_old: {
        src = builtins.fetchGit {
          url = "/home/administrator/Code/gastown-wisp-fix";
          ref = "fix/wisp-depends-col";
          rev = "a2699f79874fa69e03cbd8d1a19bb3f1f564b148";
        };
      });
  gascity = fromLlmAgents "gascity" null;
  bernstein = fromLlmAgents "bernstein" null;
  workmux = fromLlmAgents "workmux" null;
  gitbutler = fromLlmAgents "gitbutler" prev.gitbutler;
  but = fromLlmAgents "but" null;
  cli-proxy-api = fromLlmAgents "cli-proxy-api" null;
  claude-code-router = fromLlmAgents "claude-code-router" null;
  rtk = fromLlmAgents "rtk" null;
  skills = fromLlmAgents "skills" null;
  skills-installer = fromLlmAgents "skills-installer" null;
  openskills = fromLlmAgents "openskills" null;
  apm = fromLlmAgents "apm" null;
  context-hub = fromLlmAgents "context-hub" null;
  mcporter = fromLlmAgents "mcporter" null;
  opencode = fromLlmAgents "opencode" prev.opencode;
  git-surgeon = fromLlmAgents "git-surgeon" null;
  hunk = fromLlmAgents "hunk" null;
  tuicr = fromLlmAgents "tuicr" null;
  codex-acp = fromLlmAgents "codex-acp" null;
  claude-agent-acp = fromLlmAgents "claude-agent-acp" null;
  codex-auth = fromLlmAgents "codex-auth" null;
  jules = fromLlmAgents "jules" null;

  # Packaged MCP servers from natsukium/mcp-servers-nix.
  context7-mcp = fromMcpServersNix "context7-mcp" null;
  mcp-server-fetch = fromMcpServersNix "mcp-server-fetch" null;
  mcp-server-filesystem = fromMcpServersNix "mcp-server-filesystem" null;
  mcp-server-git = fromMcpServersNix "mcp-server-git" null;
  mcp-server-memory = fromMcpServersNix "mcp-server-memory" null;
  mcp-server-sequential-thinking = fromMcpServersNix "mcp-server-sequential-thinking" null;
  mcp-server-time = fromMcpServersNix "mcp-server-time" null;
  serena = fromMcpServersNix "serena" null;

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

  # Override antigravity-cli with our custom version
  antigravity-cli = final.callPackage ../pkgs/antigravity-cli { };

  # Override Claude Code with our custom native binary package by default.
  claude-code-bin = final.callPackage ../pkgs/claude-code-bin { };
  claude-code = final.claude-code-bin;

  # Override codex with our custom version
  codex = final.callPackage ../pkgs/codex { };

  # Override antigravity with our custom version
  # Same workaround as code-cursor: exclude meta from auto-filling
  # Add playwright.browsers to FHS environment for browser automation support
  antigravity =
    let
      pkgsWithoutMeta = builtins.removeAttrs final [ "meta" ];
      callPackageWithoutMeta = final.lib.callPackageWith pkgsWithoutMeta;
      # Safely get playwright.browsers if available
      playwrightBrowsers =
        if final ? playwright && final.playwright ? browsers then final.playwright.browsers else null;
    in
    callPackageWithoutMeta (import ../pkgs/antigravity) {
      callPackage = callPackageWithoutMeta;
      # Add playwright.browsers to FHS environment so browsers are available for Playwright
      # This coordinates with home-manager playwright settings
      # Falls back to null if playwright.browsers is not available
      playwright-browsers = playwrightBrowsers;
    };

  # Override antigravity-ide with our custom version
  # Same workaround as code-cursor: exclude meta from auto-filling
  antigravity-ide =
    let
      pkgsWithoutMeta = builtins.removeAttrs final [ "meta" ];
      callPackageWithoutMeta = final.lib.callPackageWith pkgsWithoutMeta;
      playwrightBrowsers =
        if final ? playwright && final.playwright ? browsers then final.playwright.browsers else null;
    in
    callPackageWithoutMeta (import ../pkgs/antigravity-ide) {
      callPackage = callPackageWithoutMeta;
      playwright-browsers = playwrightBrowsers;
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

  # Fix Wireshark hash mismatch for version 4.6.5
  # The upstream hash changed or was incorrectly specified in nixpkgs
  wireshark = prev.wireshark.overrideAttrs (oldAttrs: {
    src = prev.fetchFromGitLab {
      repo = "wireshark";
      owner = "wireshark";
      tag = "v4.6.5";
      hash = "sha256-Zvrwxjp4LK2J3QnxmPxKKrU01YHQvPyp54UWzeGNCjA=";
    };
  });
  wireshark-cli = prev.wireshark-cli.overrideAttrs (oldAttrs: {
    src = prev.fetchFromGitLab {
      repo = "wireshark";
      owner = "wireshark";
      tag = "v4.6.5";
      hash = "sha256-Zvrwxjp4LK2J3QnxmPxKKrU01YHQvPyp54UWzeGNCjA=";
    };
  });
  # Disable failing tests in pipx 1.8.0 due to python 3.13 test incompatibilities
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (python-final: python-prev: {
      pipx = python-prev.pipx.overrideAttrs (oldAttrs: {
        doCheck = false;
        pytestFlagsArray = [ ];
        checkPhase = "";
      });
    })
  ];
}
