#!/usr/bin/env bash
# Cleanup script to remove manually installed VS Code extensions
# so home-manager can manage them declaratively

set -euo pipefail

EXTENSIONS_DIR="$HOME/.vscode/extensions"

if [ ! -d "$EXTENSIONS_DIR" ]; then
  echo "Extensions directory not found: $EXTENSIONS_DIR"
  exit 0
fi

echo "Checking for manually installed extensions to remove..."
echo "This will remove extensions that are managed by home-manager."
echo ""

# List of extensions managed by home-manager (from default.nix)
MANAGED_EXTENSIONS=(
  "DavidAnson.vscode-markdownlint"
  "GitHub.remotehub"
  "Google.gemini-cli-vscode-ide-companion"
  "Gruntfuggly.todo-tree"
  "MS-python.vscode-pylance"
  "SureshNettur.pwc"
  "aaron-bond.better-comments"
  "alefragnani.bookmarks"
  "anthropic.claude-code"
  "astral-sh.ty"
  "bierner.markdown-mermaid"
  "biomejs.biome"
  "bradlc.vscode-tailwindcss"
  "charliermarsh.ruff"
  "christian-kohler.path-intellisense"
  "custom.theme"
  "dbaeumer.vscode-eslint"
  "donjayamanne.githistory"
  "eamodio.gitlens"
  "github.codespaces"
  "github.copilot"
  "github.copilot-chat"
  "github.vscode-github-actions"
  "github.vscode-pull-request-github"
  "golang.Go"
  "grafana.grafana-alloy"
  "grafana.grafana-vscode"
  "grafana.vscode-jsonnet"
  "hashicorp.terraform"
  "jnoortheen.nix-ide"
  "jock.svg"
  "littlefoxteam.vscode-python-test-adapter"
  "marp-team.marp-vscode"
  "meta.pyrefly"
  "mikestead.dotenv"
  "ms-azuretools.vscode-containers"
  "ms-kubernetes-tools.vscode-kubernetes-tools"
  "ms-ossdata.vscode-pgsql"
  "ms-playwright.playwright"
  "ms-python.debugpy"
  "ms-python.mypy-type-checker"
  "ms-toolsai.jupyter"
  "ms-vscode-remote.remote-containers"
  "ms-vscode-remote.remote-ssh"
  "ms-vscode-remote.remote-ssh-edit"
  "ms-vscode.hexeditor"
  "openai.chatgpt"
  "rangav.vscode-thunder-client"
  "redhat.ansible"
  "redhat.vscode-xml"
  "redhat.vscode-yaml"
  "rust-lang.rust-analyzer"
  "samuelcolvin.jinjahtml"
  "streetsidesoftware.code-spell-checker"
  "tailscale.vscode-tailscale"
  "tamasfe.even-better-toml"
  "tomoki1207.pdf"
  "usernamehw.errorlens"
  "ventura.prom"
  "vitest.explorer"
  "weaveworks.vscode-gitops-tools"
  "yzhang.markdown-all-in-one"
)

removed_count=0
skipped_count=0

for ext in "${MANAGED_EXTENSIONS[@]}"; do
  ext_path="$EXTENSIONS_DIR/$ext"
  if [ -e "$ext_path" ]; then
    # Check if it's a symlink (managed by nix) or a directory (manually installed)
    if [ -L "$ext_path" ]; then
      echo "Skipping $ext (already a symlink - managed by nix)"
      ((skipped_count++))
    elif [ -d "$ext_path" ]; then
      echo "Removing manually installed: $ext"
      rm -rf "$ext_path"
      ((removed_count++))
    fi
  fi
done

echo ""
echo "Summary:"
echo "  Removed: $removed_count manually installed extensions"
echo "  Skipped: $skipped_count extensions (already managed by nix)"
echo ""
echo "After running this script, run 'home-manager switch' to let home-manager"
echo "install the extensions declaratively."
