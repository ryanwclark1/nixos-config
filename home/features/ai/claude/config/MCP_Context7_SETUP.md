# Context7 MCP Server Setup & Verification

> **Purpose**: Guide for verifying Context7 MCP server configuration and token setup

## Configuration Overview

Context7 is configured in `home/features/ai/shared/mcp-config.nix` through `mcp-servers-nix` and generated to `~/.claude/mcp-servers.json` as a wrapped command.

The wrapper reads the SOPS secret at runtime, so the token is not written into Nix store files or generated MCP JSON.

## Token Source

The `CONTEXT7_TOKEN` is loaded from SOPS secrets:
- **Secret Path**: `${config.sops.secrets.context7-token.path}`
- **SOPS Config**: Defined in `home/global/sops.nix`
- **Secret Name**: `context7-token` in `secrets/secrets.yaml`

## Runtime Processing

`mcp-servers-nix` wraps the Context7 command with `passwordCommand`. When the MCP server starts, the wrapper reads `${config.sops.secrets.context7-token.path}` and exports `CONTEXT7_TOKEN` for that process only.

## Verification Steps

### 1. Check SOPS Secret Exists
```bash
# Check if secret file exists
ls -la $(nix eval --raw home-manager.config.sops.secrets.context7-token.path 2>/dev/null || echo "/run/user/$(id -u)/secrets/context7-token")

# Or check common locations
ls -la ~/.config/sops/context7-token
ls -la /run/user/$(id -u)/secrets/context7-token
```

### 2. Check Generated MCP Config
```bash
jq '.context7.command' ~/.claude/mcp-servers.json
```

### 3. Verify Token Is Not Materialized
```bash
! grep -R "CONTEXT7_TOKEN=" ~/.claude/mcp-servers.json
```

### 4. Test Context7 MCP Server Directly
```bash
jq -r '.context7.command' ~/.claude/mcp-servers.json | xargs -r -I{} {} --help
```

### 5. Verify in Claude Code

When Claude Code starts, it should:
1. Read `~/.claude/mcp-servers.json`
2. Launch the generated Context7 wrapper command
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

### Context7 Wrapper Missing
**Error**: `context7.command` does not point to a Nix store wrapper

**Solution**:
1. Rebuild Home Manager: `home-manager switch`
2. Check `home/features/ai/shared/mcp-config.nix`
3. Verify `mcp-servers-nix` is present in `flake.lock`

### Authentication Error
**Error**: Context7 MCP server fails with authentication error

**Solution**:
1. Ensure the SOPS secret file exists and is readable.
2. Rebuild Home Manager so the wrapper command is regenerated.
3. Run the generated command directly to inspect the failure.

## Testing Context7

Once configured, test Context7:

```bash
# In Claude Code, try:
/sc:implement --c7 "Add React useEffect hook"

# Or let it auto-select:
/sc:implement "Add React hooks with official patterns"
```

For complete Context7 documentation, see [MCP_Context7.md](mdc:home/features/ai/claude/config/MCP_Context7.md).
