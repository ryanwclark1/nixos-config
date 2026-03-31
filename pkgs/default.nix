{ pkgs, ... }:

{
  # Note: code-cursor, cursor-cli, gemini-cli, claude-code, claude-code-bin,
  # claude-code-npm, codex, antigravity, kiro, and vscode-generic are available
  # via the overlay in overlays/custom-packages.nix
  # This exposes them here for direct building/testing if needed
  code-cursor = pkgs.code-cursor;
  cursor-cli = pkgs.cursor-cli;
  gemini-cli = pkgs.gemini-cli;
  claude-code = pkgs.claude-code;
  claude-code-bin = pkgs.claude-code-bin;
  claude-code-npm = pkgs.claude-code-npm;
  codex = pkgs.codex;
  antigravity = pkgs.antigravity;
  kiro = pkgs.kiro;
}
