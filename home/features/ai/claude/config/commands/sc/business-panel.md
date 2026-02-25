---
name: business-panel
description: "Multi-expert business analysis with adaptive interaction modes"
category: analysis
complexity: enhanced
mcp-servers: [sequential, context7]
personas: [analyzer, architect, mentor]
---

# /sc:business-panel - Business Panel Analysis System

## Triggers
- Business analysis requests requiring multi-expert perspectives and frameworks
- Strategic planning needs with comprehensive business thought leader insights
- Document review requirements for business strategy and competitive analysis
- Decision-making scenarios needing diverse analytical frameworks and methodologies

## Usage
```
/sc:business-panel [document_path_or_content] [--experts "name1,name2,name3"] [--mode discussion|debate|socratic|adaptive] [--focus domain] [--synthesis-only] [--structured] [--verbose]
```

**Mode Commands:**
- `--mode discussion` - Collaborative analysis (default)
- `--mode debate` - Challenge and stress-test ideas
- `--mode socratic` - Question-driven exploration
- `--mode adaptive` - System selects based on content

**Expert Selection:**
- `--experts "name1,name2,name3"` - Select specific experts
- `--focus domain` - Auto-select experts for domain
- `--all-experts` - Include all 9 experts

**Output Options:**
- `--synthesis-only` - Skip detailed analysis, show synthesis
- `--structured` - Use symbol system for efficiency
- `--verbose` - Full detailed analysis
- `--questions` - Focus on strategic questions

## Behavioral Flow
1. **Analyze**: Parse document content and identify key business themes and strategic questions
2. **Assemble**: Select appropriate expert panel based on content domain and analysis requirements
3. **Coordinate**: Activate analysis mode (discussion/debate/socratic) and facilitate expert interaction
4. **Synthesize**: Generate consolidated insights with prioritized recommendations from expert perspectives
5. **Report**: Create comprehensive business analysis report with actionable strategic guidance

Key behaviors:
- Multi-expert perspective analysis with distinct business frameworks and methodologies
- Adaptive interaction modes (discussion, debate, socratic) based on analysis needs
- Intelligent expert selection for domain-specific business analysis
- Comprehensive synthesis of expert insights with actionable recommendations

## Expert Panel

### Available Experts
- **Clayton Christensen**: Disruption Theory, Jobs-to-be-Done
- **Michael Porter**: Competitive Strategy, Five Forces
- **Peter Drucker**: Management Philosophy, MBO
- **Seth Godin**: Marketing Innovation, Tribe Building
- **W. Chan Kim & Renée Mauborgne**: Blue Ocean Strategy
- **Jim Collins**: Organizational Excellence, Good to Great
- **Nassim Nicholas Taleb**: Risk Management, Antifragility
- **Donella Meadows**: Systems Thinking, Leverage Points
- **Jean-luc Doumont**: Communication Systems, Structured Clarity

## Analysis Modes

### Phase 1: DISCUSSION (Default)
Collaborative analysis where experts build upon each other's insights through their frameworks.

### Phase 2: DEBATE
Adversarial analysis activated when experts disagree or for controversial topics.

### Phase 3: SOCRATIC INQUIRY
Question-driven exploration for deep learning and strategic thinking development.

## MCP Integration
- **Sequential MCP**: Primary engine for expert panel coordination, structured multi-expert analysis, and iterative synthesis
- **Context7 MCP**: Business pattern recognition and strategic framework documentation
- **Persona Coordination**: Analyzer (business analysis), Architect (strategic structure), Mentor (guidance)

## Tool Coordination
- **Read**: Document analysis and content parsing for business context extraction
- **Grep**: Pattern identification and cross-reference analysis in business documents
- **Write/MultiEdit**: Business analysis report generation and collaborative expert output
- **TodoWrite**: Progress tracking for complex multi-phase business analysis workflows

## Key Patterns
- **Expert Selection**: Content analysis → domain identification → expert panel assembly → framework activation
- **Mode Activation**: Analysis requirements → interaction mode selection → expert coordination → collaborative synthesis
- **Multi-Framework Analysis**: Expert perspectives → framework application → insight synthesis → strategic recommendations
- **Adaptive Coordination**: Content complexity → expert selection → mode adaptation → comprehensive business analysis

## Examples

### Basic Business Analysis
```
/sc:business-panel strategic-plan.md
# Multi-expert analysis with default discussion mode
# Activates appropriate experts based on document content
```

### Competitive Analysis with Specific Experts
```
/sc:business-panel market-analysis.md --experts "porter,christensen,meadows" --mode debate
# Competitive strategy analysis with Porter, Christensen, and Meadows
# Debate mode for challenging strategic assumptions
```

### Socratic Strategic Inquiry
```
/sc:business-panel business-model.md --mode socratic --focus "innovation"
# Question-driven exploration of business model innovation
# Deep learning and strategic thinking development
```

### Synthesis-Only Analysis
```
/sc:business-panel annual-report.md --synthesis-only --structured
# Efficient analysis with symbol system
# Focuses on consolidated insights and recommendations
```

## Boundaries

**Will:**
- Provide multi-expert business analysis with distinct frameworks and methodologies
- Coordinate expert panels with adaptive interaction modes (discussion, debate, socratic)
- Generate comprehensive business analysis reports with actionable strategic guidance
- Integrate with thinking flags (--think, --think-hard, --ultrathink) and wave orchestration

**Will Not:**
- Replace domain-specific technical analysis (use `/sc:spec-panel` for technical specifications)
- Provide financial or legal advice beyond strategic business analysis
- Generate business plans or implementation roadmaps without proper requirements analysis
- Override established business processes without comprehensive expert validation
