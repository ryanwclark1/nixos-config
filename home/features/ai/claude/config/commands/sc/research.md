---
name: research
description: Deep web research with adaptive planning and intelligent search
category: special
complexity: advanced
mcp-servers: [sequential, playwright, serena]
personas: [deep-research-agent]
---

# /sc:research - Deep Research Command

> **Context Framework Note**: This command activates comprehensive research capabilities with adaptive planning, multi-hop reasoning, and evidence-based synthesis.

## Triggers
- Research questions beyond knowledge cutoff
- Complex research questions requiring multi-hop exploration
- Current events and real-time information needs
- Academic or technical research requirements
- Market analysis and competitive intelligence gathering

## Usage
```
/sc:research "[query]" [--depth quick|standard|deep|exhaustive] [--strategy planning|intent|unified]
```

## Behavioral Flow

### 1. Understand (5-10% effort)
- Assess query complexity and ambiguity
- Identify required information types
- Determine resource requirements
- Define success criteria

### 2. Plan (10-15% effort)
- Select planning strategy based on complexity
- Identify parallelization opportunities
- Generate research question decomposition
- Create investigation milestones

### 3. TodoWrite (5% effort)
- Create adaptive task hierarchy
- Scale tasks to query complexity (3-15 tasks)
- Establish task dependencies
- Set progress tracking

### 4. Execute (50-60% effort)
- **Parallel-first searches**: Always batch similar queries
- **Smart extraction**: Route by content complexity
- **Multi-hop exploration**: Follow entity and concept chains
- **Evidence collection**: Track sources and confidence

### 5. Track (Continuous)
- Monitor TodoWrite progress
- Update confidence scores
- Log successful patterns
- Identify information gaps

### 6. Validate (10-15% effort)
- Verify evidence chains
- Check source credibility
- Resolve contradictions
- Ensure completeness

Key behaviors:
- Adaptive planning with intelligent search strategy selection
- Multi-hop reasoning with evidence-based synthesis
- Parallel-first execution for efficient research workflows
- Comprehensive validation with source credibility assessment

## MCP Integration
- **Tavily**: Primary search and extraction engine for web research
- **Sequential**: Complex reasoning and synthesis for multi-step research analysis
- **Playwright**: JavaScript-heavy content extraction and dynamic page rendering
- **Serena**: Research session persistence and cross-session memory management

## Tool Coordination
- **WebSearch**: Primary research tool for information gathering and source discovery
- **TodoWrite**: Progress tracking for complex multi-phase research workflows
- **Read/Write**: Research report generation and documentation
- **sequentialthinking**: Structured reasoning for complex research question analysis

## Key Patterns

### Parallel Execution
- Batch all independent searches
- Run concurrent extractions
- Only sequential for dependencies

### Evidence Management
- Track search results
- Provide clear citations when available
- Note uncertainties explicitly

### Adaptive Depth
- **Quick**: Basic search, 1 hop, summary output
- **Standard**: Extended search, 2-3 hops, structured report
- **Deep**: Comprehensive search, 3-4 hops, detailed analysis
- **Exhaustive**: Maximum depth, 5 hops, complete investigation

## Output Standards
- Save reports to `claudedocs/research_[topic]_[timestamp].md`
- Include executive summary
- Provide confidence levels
- List all sources with citations

## Examples

### Basic Research Query
```
/sc:research "latest developments in quantum computing 2024"
# Standard depth research with adaptive planning
# Generates comprehensive report with citations
```

### Deep Research Analysis
```
/sc:research "competitive analysis of AI coding assistants" --depth deep
# Comprehensive multi-hop research with detailed analysis
# 3-4 hop exploration with evidence-based synthesis
```

### Strategic Research Planning
```
/sc:research "best practices for distributed systems" --strategy unified
# Unified strategy for comprehensive research planning
# Parallel-first execution with intelligent search coordination
```

### Exhaustive Investigation
```
/sc:research "enterprise microservices architecture patterns" --depth exhaustive
# Maximum depth research with 5-hop exploration
# Complete investigation with comprehensive source validation
```

## Boundaries

**Will:**
- Provide current information through intelligent web search and evidence-based analysis
- Execute multi-hop research with adaptive planning and parallel-first execution
- Generate comprehensive research reports with source citations and confidence levels

**Will Not:**
- Make claims without proper source validation and evidence chains
- Skip validation procedures or access restricted content
- Provide financial or legal advice beyond research information gathering
