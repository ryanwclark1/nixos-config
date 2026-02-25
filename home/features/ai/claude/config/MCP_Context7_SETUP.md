# Context7 MCP Server Setup & Verification

> **Purpose**: Guide for verifying Context7 MCP server configuration and token setup

## Configuration Overview

Context7 is configured in `home/features/ai/claude/mcp-servers.json` with:
```json
{
  "context7": {
    "command": "npx",
    "args": ["-y", "@upstash/context7-mcp"],
    "env": {
      "CONTEXT7_TOKEN": "${CONTEXT7_TOKEN}"
    }
  }
}
```

## Token Source

The `CONTEXT7_TOKEN` is loaded from SOPS secrets:
- **Secret Path**: `${config.sops.secrets.context7-token.path}`
- **SOPS Config**: Defined in `home/global/sops.nix`
- **Secret Name**: `context7-token` in `secrets/secrets.yaml`

## Runtime Processing

A systemd service (`generate-claude-config`) processes the MCP configuration at runtime:

1. **Reads token** from SOPS secret file
2. **Generates processed config** at `~/.claude/mcp-servers-processed.json` with actual token values
3. **Creates .env file** at `~/.claude/.env` with environment variables

## Verification Steps

### 1. Check SOPS Secret Exists
```bash
# Check if secret file exists
ls -la $(nix eval --raw home-manager.config.sops.secrets.context7-token.path 2>/dev/null || echo "/run/user/$(id -u)/secrets/context7-token")

# Or check common locations
ls -la ~/.config/sops/context7-token
ls -la /run/user/$(id -u)/secrets/context7-token
```

### 2. Check Systemd Service Status
```bash
systemctl --user status generate-claude-config
```

### 3. Verify Processed Config Generated
```bash
# Check if processed config exists
ls -la ~/.claude/mcp-servers-processed.json

# Verify token is injected (should show actual token, not ${CONTEXT7_TOKEN})
jq '.context7.env.CONTEXT7_TOKEN' ~/.claude/mcp-servers-processed.json
```

### 4. Check .env File
```bash
# Verify .env file exists and has token
cat ~/.claude/.env | grep CONTEXT7_TOKEN
```

### 5. Test Context7 MCP Server Directly
```bash
# Set environment variable
export CONTEXT7_TOKEN=$(cat ~/.config/sops/context7-token 2>/dev/null || cat /run/user/$(id -u)/secrets/context7-token)

# Test Context7 MCP server
npx -y @upstash/context7-mcp
```

### 6. Verify in Claude Code

When Claude Code starts, it should:
1. Load environment variables from `~/.claude/.env`
2. Use processed MCP config if available
3. Make Context7 available via `--c7` flag or auto-selection

## Troubleshooting

### Token Not Found
**Error**: `Error: context7-token secret not found`

**Solution**:
1. Ensure SOPS secrets are decrypted: `sops-nix` service should be running
2. Rebuild NixOS: `home-manager switch`
3. Check secret exists in `secrets/secrets.yaml`:
   ```bash
   sops secrets/secrets.yaml | grep context7-token
   ```

### Processed Config Not Generated
**Error**: `mcp-servers-processed.json` doesn't exist

**Solution**:
1. Manually trigger systemd service:
   ```bash
   systemctl --user start generate-claude-config
   ```
2. Check service logs:
   ```bash
   journalctl --user -u generate-claude-config
   ```

### Environment Variable Not Set
**Error**: Context7 MCP server fails with authentication error

**Solution**:
1. Use wrapper script: `~/.claude/claude-code-wrapper.sh`
2. Or manually export before starting:
   ```bash
   export CONTEXT7_TOKEN=$(cat ~/.config/sops/context7-token)
   claude-code
   ```

### Claude Code Not Using Processed Config
**Solution**:
1. Set environment variable:
   ```bash
   export MCP_SERVERS_CONFIG=~/.claude/mcp-servers-processed.json
   ```
2. Or use wrapper script which sets this automatically

## Manual Token Injection

If automatic processing fails, manually inject token:

```bash
# Read token
CONTEXT7_TOKEN=$(cat ~/.config/sops/context7-token)

# Process config manually
jq --arg token "$CONTEXT7_TOKEN" \
   '.context7.env.CONTEXT7_TOKEN = $token' \
   ~/.claude/mcp-servers.json > ~/.claude/mcp-servers-processed.json

# Export for Claude Code
export MCP_SERVERS_CONFIG=~/.claude/mcp-servers-processed.json
export CONTEXT7_TOKEN
```

## Testing Context7

Once configured, test Context7:

```bash
# In Claude Code, try:
/sc:implement --c7 "Add React useEffect hook"

# Or let it auto-select:
/sc:implement "Add React hooks with official patterns"
```

For complete Context7 documentation, see [MCP_Context7.md](mdc:home/features/ai/claude/config/MCP_Context7.md).
