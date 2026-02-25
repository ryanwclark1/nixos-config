# Serena MCP Server

> **Purpose**: Semantic code understanding with project memory and session persistence
> **Activation**: Auto-selected for symbol operations, or use `--serena` flag
> **Related**: See [FLAGS.md](mdc:home/features/ai/claude/config/FLAGS.md) for flag usage

## When to Use Serena

**Use Serena when**:
- Symbol operations: rename, extract, move functions/classes
- Project-wide code navigation and exploration
- Multi-language projects requiring LSP integration
- Session lifecycle: `/sc:load`, `/sc:save`, project activation
- Memory-driven development workflows
- Large codebase analysis (>50 files, complex architecture)

**Choose Serena over**:
- **Manual search**: For dependency tracking and cross-file references
- **Basic tools**: For large codebases requiring architectural understanding
- **Simple grep**: For semantic understanding, not just text matching

**Not for**:
- Simple text replacements or style enforcement (use grep + search_replace)
- Bulk operations without semantic understanding (use MultiEdit)
- Pattern-based edits without symbol context (use grep + search_replace)

## Works Best With
- **Morphllm**: Serena analyzes semantic context → Morphllm executes precise edits
- **Sequential**: Serena provides project context → Sequential performs architectural analysis

## Decision Tree

```
Symbol operations needed? → Serena
Need project memory? → Serena
Large codebase navigation? → Serena
Pattern-based edits? → grep + search_replace or MultiEdit
UI component generation? → (Not available - use manual coding)
```

## Examples

### Symbol Operations
```
Request: "rename getUserData function everywhere"
→ Serena:
  - Find all symbol references
  - Update function definition
  - Update all call sites
  - Maintain type safety
  - Preserve dependencies
```

### Project Context
```
Request: "load my project context"
→ Serena (/sc:load):
  - Activate project
  - Load session memories
  - Restore context
  - Resume previous work
```

### Session Persistence
```
Request: "save my current work session"
→ Serena (/sc:save):
  - Save current state
  - Store memories
  - Create checkpoint
  - Enable cross-session continuity
```

### Semantic Search
```
Request: "find all references to this class"
→ Serena:
  - Semantic code search
  - Dependency tracking
  - Cross-file references
  - Type relationships
```

### When NOT to Use
```
Request: "update all console.log to logger"
→ grep + search_replace: Pattern-based replacement, no semantic understanding needed

Request: "create a login form"
→ Manual coding: UI component generation, no symbol operations needed
```

## Integration

### With Other MCP Servers
- **+ Sequential**: Serena provides project context → Sequential performs architectural analysis
- **+ Context7**: Serena understands codebase → Context7 provides library patterns
- **+ grep/search_replace**: Serena identifies symbols → grep finds all occurrences → search_replace updates them

### Best Practices
1. **Session Lifecycle**: Use `/sc:load` at start, `/sc:save` at end
2. **Memory Management**: Store important insights for future sessions
3. **Symbol Safety**: Always use Serena for refactoring to maintain dependencies
4. **Context Preservation**: Save checkpoints before major changes
