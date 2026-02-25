# Sequential MCP Server

> **Purpose**: Multi-step reasoning engine for complex analysis and systematic problem solving
> **Activation**: Auto-selected for complex problems, or use `--seq` / `--sequential` flag
> **Related**: See [FLAGS.md](mdc:home/features/ai/claude/config/FLAGS.md) for flag usage

## When to Use Sequential

**Use Sequential when**:
- Complex debugging scenarios with multiple layers
- Architectural analysis and system design questions
- `--think`, `--think-hard`, `--ultrathink` flags are used
- Problems requiring hypothesis testing and validation
- Multi-component failure investigation
- Performance bottleneck identification requiring methodical approach

**Choose Sequential over**:
- **Native reasoning**: When problems have 3+ interconnected components
- **Simple analysis**: For systematic analysis requiring decomposition
- **Quick fixes**: When structure and evidence gathering matter

**Not for**:
- Basic explanations or single-file changes
- Straightforward fixes without complex dependencies
- Simple questions requiring direct answers

## Works Best With
- **Context7**: Sequential coordinates analysis → Context7 provides official patterns
- **Manual Implementation**: Sequential analyzes UI logic → Manual coding implements structured components
- **Playwright**: Sequential identifies testing strategy → Playwright executes validation

## Decision Tree

```
3+ components involved? → Sequential
Need hypothesis testing? → Sequential
Systematic analysis needed? → Sequential
Simple explanation? → Native Claude
Single-file change? → Native Claude
```

## Examples

### Complex Debugging
```
Request: "why is this API slow?"
→ Sequential:
  1. Analyze request flow
  2. Identify bottlenecks
  3. Test hypotheses
  4. Validate solutions
```

### Architecture Design
```
Request: "design a microservices architecture"
→ Sequential:
  1. Analyze requirements
  2. Identify service boundaries
  3. Design communication patterns
  4. Validate scalability
```

### Multi-Component Investigation
```
Request: "debug this authentication flow"
→ Sequential:
  1. Trace request path
  2. Identify failure points
  3. Test each component
  4. Isolate root cause
```

### When NOT to Use
```
Request: "explain this function"
→ Native Claude: Simple explanation, no complex reasoning needed

Request: "fix this typo"
→ Native Claude: Straightforward change, no analysis required
```

## Integration

### With Other MCP Servers
- **+ Context7**: Sequential coordinates analysis → Context7 provides official patterns
- **+ Manual Coding**: Sequential analyzes UI logic → Manual implementation creates structured components
- **+ Playwright**: Sequential identifies testing strategy → Playwright executes validation
- **+ Serena**: Sequential uses project context → Serena provides semantic understanding

### Best Practices
1. **Structure First**: Break down complex problems into steps
2. **Hypothesis-Driven**: Form hypotheses and test systematically
3. **Evidence-Based**: Gather evidence at each step
4. **Iterative**: Refine understanding through analysis cycles
