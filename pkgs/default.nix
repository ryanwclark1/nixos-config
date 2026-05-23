{ pkgs, ... }:

{
  # Note: code-cursor, cursor-cli, antigravity, antigravity-cli, antigravity-ide,
  # claude-code, claude-code-bin, claude-code-npm, codex, kiro, and
  # vscode-generic are available via the overlay in overlays/custom-packages.nix
  # This exposes them here for direct building/testing if needed
  code-cursor = pkgs.code-cursor;
  cursor-cli = pkgs.cursor-cli;
  antigravity = pkgs.antigravity;
  antigravity-cli = pkgs.antigravity-cli;
  antigravity-ide = pkgs.antigravity-ide;
  claude-code = pkgs.claude-code;
  claude-code-bin = pkgs.claude-code-bin;
  claude-code-npm = pkgs.claude-code-npm;
  codex = pkgs.codex;
  kiro = pkgs.kiro;
}
