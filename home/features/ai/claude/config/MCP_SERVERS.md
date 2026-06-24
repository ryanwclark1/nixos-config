# Available MCP Servers

> **Purpose**: Reference guide for configured MCP servers in this NixOS configuration
> **Location**: Generated from `home/features/ai/shared/mcp-config.nix` through `mcp-servers-nix`

## Currently Configured Servers

### ✅ Available MCP Servers

| Server | Purpose | Flag | Documentation |
|--------|---------|------|---------------|
| **context7** | Official library documentation | `--c7`, `--context7` | [MCP_Context7.md](mdc:home/features/ai/claude/config/MCP_Context7.md) |
| **sequential-thinking** | Multi-step reasoning | `--seq`, `--sequential` | [MCP_Sequential.md](mdc:home/features/ai/claude/config/MCP_Sequential.md) |
| **playwright** | Browser automation & E2E testing | `--play`, `--playwright` | [MCP_Playwright.md](mdc:home/features/ai/claude/config/MCP_Playwright.md) |
| **github** | GitHub repository operations | N/A | (No dedicated docs) |
| **git** | Git operations | N/A | (No dedicated docs) |
| **fetch** | Web content fetching | N/A | (No dedicated docs) |
| **time** | Date and time operations | N/A | (No dedicated docs) |

### ❌ Not Configured (References Removed)

| Server | Status | Alternative |
|--------|--------|-------------|
| **morphllm** | Not available | Use `MultiEdit` or `grep` + `search_replace` for bulk edits |
| **magic** | Not available | Use `Context7` for patterns + manual coding for UI components |

## Quick Reference

### For Library Documentation
```
--c7 or --context7
→ Use Context7 MCP server
```

### For Complex Reasoning
```
--seq or --sequential
→ Use Sequential Thinking MCP server
```

### For Browser Testing
```
--play or --playwright
→ Use Playwright MCP server
```

### For Bulk Edits (No MCP Available)
```
Use MultiEdit tool or grep + search_replace
→ No MCP server needed
```

### For UI Components (No MCP Available)
```
Use --c7 for patterns, then manual coding
→ Context7 provides patterns, manual implementation
```

## Integration Patterns

### Common Combinations

**Documentation + Implementation**:
```
/sc:implement --c7 --seq "Add React hooks"
→ Context7 provides docs → Sequential plans implementation
```

**Analysis + Testing**:
```
/sc:test --seq --play "Test authentication flow"
→ Sequential plans strategy → Playwright executes tests
```

## Adding New MCP Servers

To add a new MCP server:

1. Add configuration to `home/features/ai/shared/mcp-config.nix`
2. Create documentation file: `MCP_[ServerName].md`
3. Add flag to `FLAGS.md` if applicable
4. Update this file with the new server
5. Update cross-references in other config files

## Server Status Check

To verify which MCP servers are available:
```bash
cat ~/.claude/mcp-servers.json
```

For complete flag documentation, see [FLAGS.md](mdc:home/features/ai/claude/config/FLAGS.md).
