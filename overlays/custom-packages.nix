# Overlay to override packages with custom/newer versions
# This uses the custom package definitions in pkgs/
# Includes: code-cursor, cursor-cli, gemini-cli, claude-code, codex, antigravity, kiro, and vscode-generic
final: prev: {
  # Override code-cursor with our custom version
  code-cursor = final.callPackage ../pkgs/code-cursor { };

  # Override cursor-cli with our custom version
  cursor-cli = final.callPackage ../pkgs/cursor-cli { };

  # Override gemini-cli with our custom version
  gemini-cli = final.callPackage ../pkgs/gemini-cli { };

  # Override claude-code with our custom version
  claude-code = final.callPackage ../pkgs/claude-code { };

  # Override codex with our custom version
  codex = final.callPackage ../pkgs/codex { };

  # Override antigravity with our custom version
  antigravity = final.callPackage ../pkgs/antigravity { };

  # Override kiro with our custom version
  kiro = final.callPackage ../pkgs/kiro { };
}

