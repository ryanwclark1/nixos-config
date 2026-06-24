{ pkgs, ... }:

{
  # Note: code-cursor, cursor-cli, antigravity, antigravity-cli, antigravity-ide,
  # claude-code, claude-code-bin, codex, kiro, vscode-generic, and the
  # llm-agents ecosystem packages are available
  # via the overlay in overlays/custom-packages.nix
  # This exposes them here for direct building/testing if needed
  code-cursor = pkgs.code-cursor;
  cursor-cli = pkgs.cursor-cli;
  antigravity = pkgs.antigravity;
  antigravity-cli = pkgs.antigravity-cli;
  antigravity-ide = pkgs.antigravity-ide;
  claude-code = pkgs.claude-code;
  claude-code-bin = pkgs.claude-code-bin;
  codex = pkgs.codex;
  kiro = pkgs.kiro;
  beads = pkgs.beads;
  beads-viewer = pkgs.beads-viewer;
  gastown = pkgs.gastown;
  gascity = pkgs.gascity;
  bernstein = pkgs.bernstein;
  workmux = pkgs.workmux;
  gitbutler = pkgs.gitbutler;
  but = pkgs.but;
  cli-proxy-api = pkgs.cli-proxy-api;
  skills = pkgs.skills;
  skills-installer = pkgs.skills-installer;
  openskills = pkgs.openskills;
  apm = pkgs.apm;
  mcporter = pkgs.mcporter;
  context7-mcp = pkgs.context7-mcp;
  mcp-server-fetch = pkgs.mcp-server-fetch;
  mcp-server-filesystem = pkgs.mcp-server-filesystem;
  mcp-server-git = pkgs.mcp-server-git;
  mcp-server-memory = pkgs.mcp-server-memory;
  mcp-server-sequential-thinking = pkgs.mcp-server-sequential-thinking;
  mcp-server-time = pkgs.mcp-server-time;
  serena = pkgs.serena;
}
