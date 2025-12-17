{ pkgs, ... }:

{
  # Note: code-cursor, cursor-cli, gemini-cli, claude-code, codex, antigravity, kiro, and vscode-generic are available via the overlay in overlays/custom-packages.nix
  # This exposes them here for direct building/testing if needed
  code-cursor = pkgs.code-cursor;
  cursor-cli = pkgs.cursor-cli;
  gemini-cli = pkgs.gemini-cli;
  claude-code = pkgs.claude-code;
  codex = pkgs.codex;
  antigravity = pkgs.antigravity;
  kiro = pkgs.kiro;
}
