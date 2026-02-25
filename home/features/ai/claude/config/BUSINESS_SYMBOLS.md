# Business Analysis Symbol System

> **Purpose**: Enhanced symbol system for business panel analysis with strategic focus and efficiency optimization
> **Usage**: Used with `/sc:business-panel` command and [MODE_Business_Panel.md](mdc:home/features/ai/claude/config/MODE_Business_Panel.md)
> **Integration**: Symbols reduce token usage by 30-50% while maintaining clarity

## Quick Reference

Use symbols to communicate business concepts efficiently:
- **Strategic**: 🎯 📈 📉 💰 ⚖️ 🏆
- **Frameworks**: 🔨 ⚔️ 🎪 🌊 🚀 🛡️ 🕸️ 💬 🧭
- **Process**: 🔍 💡 🤝 ⚡ 🎭 ❓ 🧩 📋
- **Logic**: → ⇒ ← ⇄ ∴ ∵ ≡ ≠

## Business-Specific Symbols

### Strategic Analysis
| Symbol | Meaning | Usage Context |
|--------|---------|---------------|
| 🎯 | strategic target, objective | Key goals and outcomes |
| 📈 | growth opportunity, positive trend | Market growth, revenue increase |
| 📉 | decline, risk, negative trend | Market decline, threats |
| 💰 | financial impact, revenue | Economic drivers, profit centers |
| ⚖️ | trade-offs, balance | Strategic decisions, resource allocation |
| 🏆 | competitive advantage | Unique value propositions, strengths |
| 🔄 | business cycle, feedback loop | Recurring patterns, system dynamics |
| 🌊 | blue ocean, new market | Uncontested market space |
| 🏭 | industry, market structure | Competitive landscape |
| 🎪 | remarkable, purple cow | Standout products, viral potential |

### Framework Integration
| Symbol | Expert | Framework Element |
|--------|--------|-------------------|
| 🔨 | Christensen | Jobs-to-be-Done |
| ⚔️ | Porter | Five Forces |
| 🎪 | Godin | Purple Cow/Remarkable |
| 🌊 | Kim/Mauborgne | Blue Ocean |
| 🚀 | Collins | Flywheel Effect |
| 🛡️ | Taleb | Antifragile/Robustness |
| 🕸️ | Meadows | System Structure |
| 💬 | Doumont | Clear Communication |
| 🧭 | Drucker | Management Fundamentals |

### Analysis Process
| Symbol | Process Stage | Description |
|--------|---------------|-------------|
| 🔍 | investigation | Initial analysis and discovery |
| 💡 | insight | Key realizations and breakthroughs |
| 🤝 | consensus | Expert agreement areas |
| ⚡ | tension | Productive disagreement |
| 🎭 | debate | Adversarial analysis mode |
| ❓ | socratic | Question-driven exploration |
| 🧩 | synthesis | Cross-framework integration |
| 📋 | conclusion | Final recommendations |

### Business Logic Flow
| Symbol | Meaning | Business Context |
|--------|---------|------------------|
| → | causes, leads to | Market trends → opportunities |
| ⇒ | strategic transformation | Current state ⇒ desired future |
| ← | constraint, limitation | Resource limits ← budget |
| ⇄ | mutual influence | Customer needs ⇄ product development |
| ∴ | strategic conclusion | Market analysis ∴ go-to-market strategy |
| ∵ | business rationale | Expand ∵ market opportunity |
| ≡ | strategic equivalence | Strategy A ≡ Strategy B outcomes |
| ≠ | competitive differentiation | Our approach ≠ competitors |

## Expert Voice Symbols

### Communication Styles
| Expert | Symbol | Voice Characteristic |
|--------|--------|---------------------|
| Christensen | 📚 | Academic, methodical |
| Porter | 📊 | Analytical, data-driven |
| Drucker | 🧠 | Wise, fundamental |
| Godin | 💬 | Conversational, provocative |
| Kim/Mauborgne | 🎨 | Strategic, value-focused |
| Collins | 📖 | Research-driven, disciplined |
| Taleb | 🎲 | Contrarian, risk-aware |
| Meadows | 🌐 | Holistic, systems-focused |
| Doumont | ✏️ | Precise, clarity-focused |

## Synthesis Output Templates

### Discussion Mode Synthesis
```markdown
## 🧩 SYNTHESIS ACROSS FRAMEWORKS

**🤝 Convergent Insights**: [Where multiple experts agree]
- 🎯 Strategic alignment on [key area]
- 💰 Economic consensus around [financial drivers]
- 🏆 Shared view of competitive advantage

**⚖️ Productive Tensions**: [Strategic trade-offs revealed]
- 📈 Growth vs 🛡️ Risk management (Taleb ⚡ Collins)
- 🌊 Innovation vs 📊 Market positioning (Kim/Mauborgne ⚡ Porter)

**🕸️ System Patterns** (Meadows analysis):
- Leverage points: [key intervention opportunities]
- Feedback loops: [reinforcing/balancing dynamics]

**💬 Communication Clarity** (Doumont optimization):
- Core message: [essential strategic insight]
- Action priorities: [implementation sequence]

**⚠️ Blind Spots**: [Gaps requiring additional analysis]

**🤔 Strategic Questions**: [Next exploration priorities]
```

### Debate Mode Synthesis
```markdown
## ⚡ PRODUCTIVE TENSIONS RESOLVED

**Initial Conflict**: [Primary disagreement area]
- 📚 **CHRISTENSEN position**: [Innovation framework perspective]
- 📊 **PORTER counter**: [Competitive strategy challenge]

**🔄 Resolution Process**:
[How experts found common ground or maintained productive tension]

**🧩 Higher-Order Solution**:
[Strategy that honors multiple frameworks]

**🕸️ Systems Insight** (Meadows):
[How the debate reveals deeper system dynamics]
```

### Socratic Mode Synthesis
```markdown
## 🎓 STRATEGIC THINKING DEVELOPMENT

**🤔 Question Themes Explored**:
- Framework lens: [Which expert frameworks were applied]
- Strategic depth: [Level of analysis achieved]

**💡 Learning Insights**:
- Pattern recognition: [Strategic thinking patterns developed]
- Framework integration: [How to combine expert perspectives]

**🧭 Next Development Areas**:
[Strategic thinking capabilities to develop further]
```

## Token Efficiency Integration

### Compression Strategies
- **Expert Voice Compression**: Maintain authenticity while reducing verbosity
- **Framework Symbol Substitution**: Use symbols for common framework concepts
- **Structured Output**: Organized templates reducing repetitive text
- **Smart Abbreviation**: Business-specific abbreviations with context preservation

### Business Abbreviations

**Common Terms**:
- `comp advantage` → competitive advantage
- `value prop` → value proposition
- `GTM` → go-to-market
- `TAM` → total addressable market
- `CAC` → customer acquisition cost
- `LTV` → lifetime value
- `KPI` → key performance indicator
- `ROI` → return on investment
- `MVP` → minimum viable product
- `PMF` → product-market fit

**Frameworks**:
- `JTBD` → jobs-to-be-done
- `BOS` → blue ocean strategy
- `G2G` → good to great
- `5F` → five forces
- `VC` → value chain
- `ERRC` → four actions framework (Eliminate, Reduce, Raise, Create)

## Mode Configuration

### Default Settings
```yaml
business_panel_config:
  # Expert Selection
  max_experts: 5
  min_experts: 3
  auto_select: true
  diversity_optimization: true

  # Analysis Depth
  phase_progression: adaptive
  synthesis_required: true
  cross_framework_validation: true

  # Output Control
  symbol_compression: true
  structured_templates: true
  expert_voice_preservation: 0.85

  # Integration
  mcp_sequential_primary: true
  mcp_context7_patterns: true
  persona_coordination: true
```

### Performance Optimization
- **Token Budget**: 15-30K tokens for comprehensive analysis
- **Expert Caching**: Store expert personas for session reuse
- **Framework Reuse**: Cache framework applications for similar content
- **Synthesis Templates**: Pre-structured output formats for efficiency
- **Parallel Analysis**: Where possible, run expert analysis in parallel

## Quality Assurance

### Authenticity Validation
- **Voice Consistency**: Each expert maintains characteristic communication style
- **Framework Fidelity**: Analysis follows authentic framework methodology
- **Interaction Realism**: Expert interactions reflect realistic professional dynamics
- **Synthesis Integrity**: Combined insights maintain individual framework value

### Business Analysis Standards
- **Strategic Relevance**: Analysis addresses real business strategic concerns
- **Implementation Feasibility**: Recommendations are actionable and realistic
- **Evidence Base**: Conclusions supported by framework logic and business evidence
- **Professional Quality**: Analysis meets executive-level business communication standards

## Usage Examples

### Symbol-Enhanced Communication
```
Standard: "The market analysis shows growth opportunities in the blue ocean space,
          but we need to balance this with competitive positioning risks."

Symbol-Enhanced: "📈 🌊 BOS opportunities ⚖️ ⚔️ 5F positioning risks"
Token Savings: ~60% reduction
```

### Framework Integration
```
Standard: "Christensen's Jobs-to-be-Done framework suggests we focus on customer jobs,
          while Porter's Five Forces analysis indicates competitive threats."

Symbol-Enhanced: "🔨 JTBD → customer jobs ⚔️ 5F → competitive threats"
Token Savings: ~55% reduction
```

## Integration

### With Business Panel Mode
- **Discussion Mode**: Use symbols for expert synthesis
- **Debate Mode**: Use symbols to highlight tensions (⚡)
- **Socratic Mode**: Use symbols in question formulation

### With Token Efficiency Mode
- Symbols work seamlessly with `--token-efficient` flag
- Combine with business abbreviations for maximum compression
- Maintain clarity while reducing token usage

For complete business panel methodology, see [MODE_Business_Panel.md](mdc:home/features/ai/claude/config/MODE_Business_Panel.md).
