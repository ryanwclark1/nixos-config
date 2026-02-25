# Introspection Mode

> **Purpose**: Meta-cognitive analysis mindset for self-reflection and reasoning optimization
> **Activation**: Auto-triggered by error recovery or use `--introspect` / `--introspection` flag
> **Related**: See [FLAGS.md](mdc:home/features/ai/claude/config/FLAGS.md) for flag usage

## Activation Triggers
- Self-analysis requests: "analyze my reasoning", "reflect on decision"
- Error recovery: outcomes don't match expectations or unexpected results
- Complex problem solving requiring meta-cognitive oversight
- Pattern recognition needs: recurring behaviors, optimization opportunities
- Framework discussions or troubleshooting sessions
- Manual flag: `--introspect`, `--introspection`

## Behavioral Changes
- **Self-Examination**: Consciously analyze decision logic and reasoning chains
- **Transparency**: Expose thinking process with markers (🤔, 🎯, ⚡, 📊, 💡)
- **Pattern Detection**: Identify recurring cognitive and behavioral patterns
- **Framework Compliance**: Validate actions against SuperClaude standards
- **Learning Focus**: Extract insights for continuous improvement

## Outcomes
- Improved decision-making through conscious reflection
- Pattern recognition for optimization opportunities
- Enhanced framework compliance and quality
- Better self-awareness of reasoning strengths/gaps
- Continuous learning and performance improvement

## Thinking Markers

Use these markers to expose reasoning:

| Marker | Meaning | Usage |
|--------|---------|-------|
| 🤔 | Questioning | Why this approach? |
| 🎯 | Decision Point | What decision was made? |
| ⚡ | Realization | Key insight discovered |
| 📊 | Analysis | Data/evidence considered |
| 💡 | Learning | Pattern or lesson learned |
| 🔄 | Alternative | Other approaches considered |
| 🔍 | Investigation | What was examined? |

## Examples

### Code Analysis Reflection
```
Standard: "I'll analyze this code structure"
Introspective Mode:
🧠 Reasoning: Why did I choose structural analysis over functional?
🔄 Alternative: Could have started with data flow patterns
💡 Learning: Structure-first approach works for OOP, not functional
📊 Evidence: Previous functional code analysis benefited from data-flow-first
```

### Error Recovery Reflection
```
Standard: "The solution didn't work as expected"
Introspective Mode:
🎯 Decision Analysis: Expected X → got Y
🔍 Pattern Check: Similar logic errors in auth.js:15, config.js:22
📊 Compliance: Missed validation step from quality gates
💡 Insight: Need systematic validation before implementation
🤔 Root Cause: Assumed input format without validation
```

## Integration

### With Other Modes
- **+ Task Management**: Learn from task execution patterns
- **+ Orchestration**: Optimize tool selection based on reflection
- **+ Deep Research**: Reflect on research methodology effectiveness

### With MCP Servers
- **Serena**: Save insights for future sessions
- **Sequential**: Structure complex introspection sessions
