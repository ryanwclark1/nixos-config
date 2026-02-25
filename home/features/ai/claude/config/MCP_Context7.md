# Context7 MCP Server

> **Purpose**: Official library documentation lookup and framework pattern guidance
> **Activation**: Auto-selected for library/framework questions, or use `--c7` / `--context7` flag
> **Related**: See [FLAGS.md](mdc:home/features/ai/claude/config/FLAGS.md) for flag usage

## When to Use Context7

**Use Context7 when**:
- Import statements: `import`, `require`, `from`, `use`
- Framework keywords: React, Vue, Angular, Next.js, Express, etc.
- Library-specific questions about APIs or best practices
- Need for official documentation patterns vs generic solutions
- Version-specific implementation requirements

**Choose Context7 over**:
- **WebSearch**: When you need curated, version-specific documentation
- **Native knowledge**: When implementation must follow official patterns
- **For frameworks**: React hooks, Vue composition API, Angular services
- **For libraries**: Correct API usage, authentication flows, configuration
- **For compliance**: When adherence to official standards is mandatory

## Works Best With
- **Sequential**: Context7 provides docs → Sequential analyzes implementation strategy
- **Manual Implementation**: Context7 supplies patterns → Manual coding implements framework-compliant components

## Decision Tree

```
Need library docs? → Context7
Need framework patterns? → Context7
Need official examples? → Context7
Need version-specific info? → Context7
Just explaining code? → Native Claude
General knowledge? → Native Claude
```

## Examples

### Library Documentation
```
Request: "implement React useEffect"
→ Context7: Fetches official React hooks documentation
→ Provides: Official patterns, best practices, common pitfalls
```

### Framework Migration
```
Request: "migrate to Vue 3"
→ Context7: Fetches official Vue 3 migration guide
→ Provides: Breaking changes, migration steps, compatibility info
```

### API Integration
```
Request: "add authentication with Auth0"
→ Context7: Fetches official Auth0 SDK documentation
→ Provides: Correct API usage, configuration, security best practices
```

### When NOT to Use
```
Request: "just explain this function"
→ Native Claude: No external docs needed, general code explanation
```

## Integration

### With Other MCP Servers
- **+ Sequential**: Context7 provides docs → Sequential analyzes implementation strategy
- **+ Manual Coding**: Context7 supplies patterns → Manual implementation creates framework-compliant components
- **+ Playwright**: Context7 provides testing patterns → Playwright validates implementation

### Best Practices
1. **Version-Specific**: Always specify library versions when available
2. **Official First**: Prefer official docs over community examples
3. **Pattern Matching**: Use Context7 for pattern-based questions
4. **Combine**: Use with Sequential for complex implementation planning
