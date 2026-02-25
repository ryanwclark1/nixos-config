# SuperClaude Framework Flags

> **Purpose**: Behavioral flags for Claude Code to enable specific execution modes and tool selection patterns.
> **Usage**: Append flags to `/sc:` commands or use standalone. Flags can be combined.
> **Reference**: See [MODE_*.md](mdc:home/features/ai/claude/config/MODE_Brainstorming.md) files for detailed mode documentation.

## Quick Reference

| Flag | Category | Purpose |
|------|----------|---------|
| `--brainstorm` | Mode | Collaborative discovery for vague requests |
| `--introspect` | Mode | Self-reflection and error recovery |
| `--task-manage` | Mode | Multi-step task coordination |
| `--orchestrate` | Mode | Multi-tool optimization |
| `--token-efficient` | Mode | Symbol-enhanced compression |
| `--c7`, `--seq`, `--magic`, etc. | MCP | Enable specific MCP servers |
| `--think`, `--think-hard`, `--ultrathink` | Analysis | Control analysis depth |
| `--delegate`, `--concurrency` | Execution | Control parallelization |
| `--uc`, `--scope`, `--focus` | Output | Optimize output format |

## Mode Activation Flags

**--brainstorm** / **--bs**
- **Trigger**: Vague project requests, exploration keywords ("maybe", "thinking about", "not sure")
- **Behavior**: Activate collaborative discovery mindset, ask probing questions, guide requirement elicitation
- **Reference**: See [MODE_Brainstorming.md](mdc:home/features/ai/claude/config/MODE_Brainstorming.md)
- **Example**: `/sc:design --brainstorm "I want to build something for task management"`

**--introspect** / **--introspection**
- **Trigger**: Self-analysis requests, error recovery, complex problem solving requiring meta-cognition
- **Behavior**: Expose thinking process with transparency markers (🤔, 🎯, ⚡, 📊, 💡)
- **Reference**: See [MODE_Introspection.md](mdc:home/features/ai/claude/config/MODE_Introspection.md)
- **Example**: `/sc:analyze --introspect "Why did this approach fail?"`

**--task-manage**
- **Trigger**: Multi-step operations (>3 steps), complex scope (>2 directories OR >3 files)
- **Behavior**: Orchestrate through delegation, progressive enhancement, systematic organization
- **Reference**: See [MODE_Task_Management.md](mdc:home/features/ai/claude/config/MODE_Task_Management.md)
- **Example**: `/sc:task --task-manage "Refactor authentication system"`

**--orchestrate**
- **Trigger**: Multi-tool operations, performance constraints, parallel execution opportunities
- **Behavior**: Optimize tool selection matrix, enable parallel thinking, adapt to resource constraints
- **Reference**: See [MODE_Orchestration.md](mdc:home/features/ai/claude/config/MODE_Orchestration.md)
- **Example**: `/sc:implement --orchestrate "Build full-stack feature"`

**--token-efficient**
- **Trigger**: Context usage >75%, large-scale operations, `--uc` flag
- **Behavior**: Symbol-enhanced communication, 30-50% token reduction while preserving clarity
- **Reference**: See [MODE_Token_Efficiency.md](mdc:home/features/ai/claude/config/MODE_Token_Efficiency.md)
- **Example**: `/sc:analyze --token-efficient "Review entire codebase"`

## MCP Server Flags

> **Note**: MCP servers are automatically selected based on context. Use flags to force enable specific servers.

**--c7** / **--context7**
- **Trigger**: Library imports, framework questions, official documentation needs
- **Behavior**: Enable Context7 for curated documentation lookup and pattern guidance
- **Reference**: See [MCP_Context7.md](mdc:home/features/ai/claude/config/MCP_Context7.md)
- **Example**: `/sc:implement --c7 "Add React hooks"`

**--seq** / **--sequential**
- **Trigger**: Complex debugging, system design, multi-component analysis
- **Behavior**: Enable Sequential for structured multi-step reasoning and hypothesis testing
- **Reference**: See [MCP_Sequential.md](mdc:home/features/ai/claude/config/MCP_Sequential.md)
- **Example**: `/sc:debug --seq "Why is the API slow?"`

**--magic**
- **Note**: Magic MCP server not currently configured. Use manual coding or component libraries instead.
- **Alternative**: Use Context7 for framework patterns, then manually implement UI components
- **Example**: `/sc:implement --c7 "Create login form"` (uses Context7 for patterns, manual implementation)

**--morph** / **--morphllm**
- **Note**: Morphllm MCP server not currently configured. Use MultiEdit or manual pattern-based edits instead.
- **Alternative**: Use `MultiEdit` tool for bulk file changes, or `grep` + `search_replace` for pattern-based edits
- **Example**: `/sc:refactor "Update all console.log to logger"` (uses MultiEdit)

**--serena**
- **Trigger**: Symbol operations, project memory needs, large codebase navigation
- **Behavior**: Enable Serena for semantic understanding and session persistence
- **Reference**: See [MCP_Serena.md](mdc:home/features/ai/claude/config/MCP_Serena.md)
- **Example**: `/sc:refactor --serena "Rename getUserData function"`

**--play** / **--playwright**
- **Trigger**: Browser testing, E2E scenarios, visual validation, accessibility testing
- **Behavior**: Enable Playwright for real browser automation and testing
- **Reference**: See [MCP_Playwright.md](mdc:home/features/ai/claude/config/MCP_Playwright.md)
- **Example**: `/sc:test --play "Test login flow"`

**--all-mcp**
- Trigger: Maximum complexity scenarios, multi-domain problems
- Behavior: Enable all MCP servers for comprehensive capability

**--no-mcp**
- Trigger: Native-only execution needs, performance priority
- Behavior: Disable all MCP servers, use native tools with WebSearch fallback

## Analysis Depth Flags

**--think**
- **Trigger**: Multi-component analysis needs, moderate complexity
- **Behavior**: Standard structured analysis (~4K tokens), enables Sequential
- **Example**: `/sc:analyze --think "Review authentication system"`

**--think-hard**
- **Trigger**: Architectural analysis, system-wide dependencies
- **Behavior**: Deep analysis (~10K tokens), enables Sequential + Context7
- **Example**: `/sc:design --think-hard "Microservices architecture"`

**--ultrathink**
- **Trigger**: Critical system redesign, legacy modernization, complex debugging
- **Behavior**: Maximum depth analysis (~32K tokens), enables all MCP servers
- **Example**: `/sc:analyze --ultrathink "Complete system audit"`

## Execution Control Flags

**--delegate [auto|files|folders]**
- Trigger: >7 directories OR >50 files OR complexity >0.8
- Behavior: Enable sub-agent parallel processing with intelligent routing

**--concurrency [n]**
- Trigger: Resource optimization needs, parallel operation control
- Behavior: Control max concurrent operations (range: 1-15)

**--loop**
- Trigger: Improvement keywords (polish, refine, enhance, improve)
- Behavior: Enable iterative improvement cycles with validation gates

**--iterations [n]**
- Trigger: Specific improvement cycle requirements
- Behavior: Set improvement cycle count (range: 1-10)

**--validate**
- Trigger: Risk score >0.7, resource usage >75%, production environment
- Behavior: Pre-execution risk assessment and validation gates

**--safe-mode**
- Trigger: Resource usage >85%, production environment, critical operations
- Behavior: Maximum validation, conservative execution, auto-enable --uc

## Output Optimization Flags

**--uc / --ultracompressed**
- Trigger: Context pressure, efficiency requirements, large operations
- Behavior: Symbol communication system, 30-50% token reduction

**--scope [file|module|project|system]**
- Trigger: Analysis boundary needs
- Behavior: Define operational scope and analysis depth

**--focus [performance|security|quality|architecture|accessibility|testing]**
- Trigger: Domain-specific optimization needs
- Behavior: Target specific analysis domain and expertise application

## Flag Priority Rules

### Execution Order
1. **Safety First**: `--safe-mode` > `--validate` > optimization flags
2. **Explicit Override**: User flags > auto-detection
3. **Depth Hierarchy**: `--ultrathink` > `--think-hard` > `--think`
4. **MCP Control**: `--no-mcp` overrides all individual MCP flags
5. **Scope Precedence**: `system` > `project` > `module` > `file`

### Flag Combinations

**Common Patterns**:
- `/sc:implement --think-hard --c7` - Deep analysis with docs (manual UI implementation)
- `/sc:refactor --task-manage --serena` - Complex refactoring with memory
- `/sc:analyze --ultrathink --token-efficient` - Comprehensive analysis with compression
- `/sc:test --play --validate` - Browser testing with validation gates

**Conflicting Flags**:
- `--no-mcp` + any MCP flag → `--no-mcp` wins
- `--ultrathink` + `--think` → `--ultrathink` wins
- `--safe-mode` + `--token-efficient` → Both apply (safe mode may reduce compression)

## Decision Tree

```
Need documentation? → --c7
Need reasoning? → --seq
Need UI components? → Use Context7 for patterns + manual implementation
Need bulk edits? → Use MultiEdit tool or grep + search_replace
Need symbol ops? → --serena
Need browser testing? → --play
Complex analysis? → --think-hard or --ultrathink
Multi-step task? → --task-manage
Context pressure? → --token-efficient or --uc
```

For complete flag documentation and examples, see individual MODE_*.md and MCP_*.md files.
