---
name: workflow
description: "Generate structured implementation workflows from PRDs and feature requirements"
category: orchestration
complexity: advanced
mcp-servers: [sequential, context7, playwright]
personas: [architect, analyzer, frontend, backend, security, devops, project-manager]
---

# /sc:workflow - Implementation Workflow Generator

## Triggers
- PRD and feature specification analysis for implementation planning
- Structured workflow generation for development projects
- Multi-persona coordination for complex implementation strategies
- Workflow documentation and dependency mapping

**Note:** For requirements discovery and specification development, consider using `/sc:brainstorm` first to explore and refine requirements before generating workflows.

## Usage
```
/sc:workflow [prd-file|feature-description] [--strategy systematic|agile|enterprise] [--depth shallow|normal|deep] [--parallel]
```

## Behavioral Flow
1. **Analyze**: Parse PRD and feature specifications to understand implementation requirements
2. **Plan**: Generate comprehensive workflow structure with dependency mapping and task orchestration
3. **Coordinate**: Activate multiple personas for domain expertise and implementation strategy
4. **Execute**: Create structured step-by-step workflows with automated task coordination
5. **Validate**: Apply quality gates and ensure workflow completeness across domains

Key behaviors:
- Multi-persona orchestration across architecture, frontend, backend, security, and devops domains
- MCP coordination with intelligent routing for specialized workflow analysis
- Systematic execution with progressive workflow enhancement and parallel processing
- Workflow documentation with comprehensive dependency tracking

## MCP Integration
- **Sequential MCP**: Complex multi-step workflow analysis and systematic implementation planning
- **Context7 MCP**: Framework-specific workflow patterns and implementation best practices
- **Playwright MCP**: Testing workflow integration and quality assurance automation

## Tool Coordination
- **Read/Write/Edit**: PRD analysis and workflow documentation generation
- **TodoWrite**: Progress tracking for complex multi-phase workflow execution
- **Task**: Advanced delegation for parallel workflow generation and multi-agent coordination
- **WebSearch**: Technology research, framework validation, and implementation strategy analysis
- **sequentialthinking**: Structured reasoning for complex workflow dependency analysis

## Key Patterns
- **PRD Analysis**: Document parsing → requirement extraction → implementation strategy development
- **Workflow Generation**: Task decomposition → dependency mapping → structured implementation planning
- **Multi-Domain Coordination**: Cross-functional expertise → comprehensive implementation strategies
- **Quality Integration**: Workflow validation → testing strategies → deployment planning

## Examples

### Systematic PRD Workflow
```
/sc:workflow ClaudeDocs/PRD/feature-spec.md --strategy systematic --depth deep
# Comprehensive PRD analysis with systematic workflow generation
# Multi-persona coordination for complete implementation strategy
```

### Agile Feature Workflow
```
/sc:workflow "user authentication system" --strategy agile --parallel
# Agile workflow generation with parallel task coordination
# Context7 and Playwright MCP for framework and UI workflow validation
```

### Enterprise Implementation Planning
```
/sc:workflow enterprise-prd.md --strategy enterprise --validate
# Enterprise-scale workflow with comprehensive validation
# Security, devops, and architect personas for compliance and scalability
```

### Workflow Documentation
```
/sc:workflow project-brief.md --depth normal
# Progressive workflow enhancement with durable notes and dependency mapping
```

## Boundaries

**Will:**
- Generate comprehensive implementation workflows from PRD and feature specifications
- Coordinate multiple personas and declared MCP servers for complete implementation strategies
- Provide workflow documentation and progressive enhancement capabilities

**Will Not:**
- Execute actual implementation tasks beyond workflow planning and strategy
- Override established development processes without proper analysis and validation
- Generate workflows without comprehensive requirement analysis and dependency mapping
