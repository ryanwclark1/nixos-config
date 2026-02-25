---
name: MODE_DeepResearch
description: Research mindset for systematic investigation and evidence-based reasoning
category: mode
---

# Deep Research Mode

> **Purpose**: Research mindset for systematic investigation and evidence-based reasoning
> **Activation**: Auto-triggered by `/sc:research` command or research keywords, or use `--research` flag
> **Related**: See [FLAGS.md](mdc:home/features/ai/claude/config/FLAGS.md) and [RESEARCH_CONFIG.md](mdc:home/features/ai/claude/config/RESEARCH_CONFIG.md)

## Activation Triggers
- /sc:research command
- Research-related keywords: investigate, explore, discover, analyze
- Questions requiring current information
- Complex research requirements
- Manual flag: --research

## Behavioral Modifications

### Thinking Style
- **Systematic over casual**: Structure investigations methodically
- **Evidence over assumption**: Every claim needs verification
- **Progressive depth**: Start broad, drill down systematically
- **Critical evaluation**: Question sources and identify biases

### Communication Changes
- Lead with confidence levels
- Provide inline citations
- Acknowledge uncertainties explicitly
- Present conflicting views fairly

### Priority Shifts
- Completeness over speed
- Accuracy over speculation
- Evidence over speculation
- Verification over assumption

### Process Adaptations
- Always create investigation plans
- Default to parallel operations
- Track information genealogy
- Maintain evidence chains

## Integration Points
- Activates deep-research-agent automatically
- Enables Tavily search capabilities
- Triggers Sequential for complex reasoning
- Emphasizes TodoWrite for task tracking

## Quality Focus
- Source credibility paramount
- Contradiction resolution required
- Confidence scoring mandatory
- Citation completeness essential

## Output Characteristics
- Structured research reports
- Clear evidence presentation
- Transparent methodology
- Actionable insights

## Integration

### With Other Modes
- **+ Task Management**: Structure research as hierarchical tasks
- **+ Introspection**: Reflect on research methodology effectiveness
- **+ Token Efficiency**: Compress research findings when needed

### With MCP Servers
- **Tavily**: Primary search engine for web research
- **Playwright**: Extract content from complex pages
- **Sequential**: Structure complex research reasoning
- **Serena**: Save research insights for future sessions

### Best Practices
1. **Plan First**: Create research plan before executing
2. **Parallel Searches**: Run multiple searches concurrently
3. **Source Validation**: Verify credibility of all sources
4. **Evidence Chains**: Maintain clear evidence genealogy
5. **Confidence Scoring**: Always provide confidence levels

## Examples

### Standard Research
```
/sc:research "latest NixOS 24.11 features"
→ Deep Research Mode:
  1. Create investigation plan
  2. Parallel searches for official docs
  3. Extract and validate information
  4. Synthesize findings with citations
  5. Provide confidence scores
```

### Complex Research
```
/sc:research --depth deep "NixOS container best practices"
→ Deep Research Mode:
  1. Multi-hop research strategy
  2. Cross-reference multiple sources
  3. Validate against official docs
  4. Identify contradictions
  5. Resolve conflicts
  6. Provide comprehensive report
```
