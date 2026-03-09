{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
    code-cursor
    cursor-cli
    # jq is needed for merging settings
    jq
  ];

  # Configure Cursor SSH settings via activation script
  # This merges SSH settings into existing Cursor settings.json
  home.activation.configureCursorSsh = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CURSOR_SETTINGS="${config.home.homeDirectory}/.config/Cursor/User/settings.json"
    SSH_SETTINGS='{
      "remote.SSH.path": "/run/current-system/sw/bin/ssh",
      "remote.SSH.configFile": "${config.home.homeDirectory}/.ssh/config",
      "remote.SSH.useLocalServer": false,
      "remote.SSH.showLoginTerminal": true,
      "remote.SSH.enableDynamicForwarding": true,
      "remote.SSH.enableX11Forwarding": false,
      "remote.SSH.serverInstallTimeout": 120,
      "remote.SSH.connectTimeout": 60,
      "remote.SSH.remoteServerListenOnSocket": true,
      "remote.SSH.useFlock": true,
      "remote.SSH.lockfilesInTmp": false,
      "remote.SSH.allowLocalServerDownload": true
    }'

    # Ensure Cursor User directory exists
    mkdir -p "$(dirname "$CURSOR_SETTINGS")"

    if [ -f "$CURSOR_SETTINGS" ]; then
      # Merge SSH settings into existing settings using jq
      if command -v ${pkgs.jq}/bin/jq >/dev/null 2>&1; then
        tmp_settings=$(mktemp)
        ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$CURSOR_SETTINGS" <(echo "$SSH_SETTINGS") > "$tmp_settings" && \
        mv "$tmp_settings" "$CURSOR_SETTINGS"
        echo "✅ Merged SSH settings into Cursor configuration"
      else
        echo "⚠️  Warning: jq not found, cannot merge SSH settings automatically"
        echo "   Please manually add SSH settings to $CURSOR_SETTINGS"
      fi
    else
      # Create new settings file with SSH configuration
      echo "$SSH_SETTINGS" > "$CURSOR_SETTINGS"
      echo "✅ Created Cursor settings with SSH configuration"
    fi
  '';

  # Note: Remote SSH extension must be installed manually in Cursor
  # Extension ID: ms-vscode-remote.remote-ssh
  # Install via: Cursor > Extensions > Search "Remote - SSH"
}

