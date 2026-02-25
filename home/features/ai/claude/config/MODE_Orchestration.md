# Orchestration Mode

> **Purpose**: Intelligent tool selection mindset for optimal task routing and resource efficiency
> **Activation**: Auto-triggered for multi-tool operations, or use `--orchestrate` flag
> **Related**: See [FLAGS.md](mdc:home/features/ai/claude/config/FLAGS.md) for flag usage

## Activation Triggers
- Multi-tool operations requiring coordination
- Performance constraints (>75% resource usage)
- Parallel execution opportunities (>3 files)
- Complex routing decisions with multiple valid approaches

## Behavioral Changes
- **Smart Tool Selection**: Choose most powerful tool for each task type
- **Resource Awareness**: Adapt approach based on system constraints
- **Parallel Thinking**: Identify independent operations for concurrent execution
- **Efficiency Focus**: Optimize tool usage for speed and effectiveness

## Tool Selection Matrix

| Task Type | Best Tool | Alternative |
|-----------|-----------|-------------|
| UI components | Context7 (patterns) + Manual coding | Manual coding only |
| Deep analysis | Sequential MCP | Native reasoning |
| Symbol operations | Serena MCP | Manual search |
| Pattern edits | MultiEdit / grep + search_replace | Individual edits |
| Documentation | Context7 MCP | Web search |
| Browser testing | Playwright MCP | Unit tests |
| Multi-file edits | MultiEdit | Sequential Edits |

## Resource Management

**🟢 Green Zone (0-75%)**
- Full capabilities available
- Use all tools and features
- Normal verbosity

**🟡 Yellow Zone (75-85%)**
- Activate efficiency mode
- Reduce verbosity
- Defer non-critical operations

**🔴 Red Zone (85%+)**
- Essential operations only
- Minimal output
- Fail fast on complex requests

## Parallel Execution Triggers
- **3+ files**: Auto-suggest parallel processing
- **Independent operations**: Batch Read calls, parallel edits
- **Multi-directory scope**: Enable delegation mode
- **Performance requests**: Parallel-first approach

## Examples

### Multi-Tool Coordination
```
Request: "Build authentication system with React frontend and Node backend"
Orchestration Mode:
1. Sequential → Analyze architecture requirements
2. Context7 → Get React and Express patterns
3. Context7 → Get React patterns, then manually implement components
4. MultiEdit → Create backend endpoints
5. Playwright → Test complete flow
```

### Resource-Aware Execution
```
Context: 80% resource usage (Yellow Zone)
Orchestration Mode:
- Reduce verbosity
- Defer non-critical operations
- Focus on essential tasks
- Enable token efficiency mode
```

## Integration

### With Other Modes
- **+ Task Management**: Orchestrate complex multi-step tasks
- **+ Token Efficiency**: Optimize when resources constrained
- **+ Introspection**: Reflect on tool selection effectiveness

### Best Practices
1. **Tool Matching**: Match tools to their strengths
2. **Parallel First**: Default to parallel execution
3. **Resource Monitoring**: Adapt to resource constraints
4. **Efficiency Focus**: Optimize for speed and effectiveness
