---
name: task
description: "Execute complex tasks with intelligent workflow management and delegation"
category: special
complexity: advanced
mcp-servers: [sequential, context7, playwright]
personas: [architect, analyzer, frontend, backend, security, devops, project-manager]
---

# /sc:task - Enhanced Task Management

## Triggers
- Complex tasks requiring multi-agent coordination and delegation
- Projects needing structured workflow management and durable task artifacts
- Operations requiring intelligent MCP server routing and domain expertise
- Tasks benefiting from systematic execution and progressive enhancement

## Usage
```
/sc:task [action] [target] [--strategy systematic|agile|enterprise] [--parallel] [--delegate]
```

## Behavioral Flow
1. **Analyze**: Parse task requirements and determine optimal execution strategy
2. **Delegate**: Route to appropriate MCP servers and activate relevant personas
3. **Coordinate**: Execute tasks with intelligent workflow management and parallel processing
4. **Validate**: Apply quality gates and comprehensive task completion verification
5. **Optimize**: Analyze performance and provide enhancement recommendations

Key behaviors:
- Multi-persona coordination across architect, frontend, backend, security, devops domains
- Intelligent MCP server routing (Sequential, Context7, Playwright)
- Systematic execution with progressive task enhancement and explicit task artifacts
- Advanced task delegation with hierarchical breakdown and dependency management

## MCP Integration
- **Sequential MCP**: Complex multi-step task analysis and systematic execution planning
- **Context7 MCP**: Framework-specific patterns and implementation best practices
- **Playwright MCP**: Testing workflow integration and validation automation

## Tool Coordination
- **TodoWrite**: Hierarchical task breakdown and progress tracking across Epic → Story → Task levels
- **Task**: Advanced delegation for complex multi-agent coordination and sub-task management
- **Read/Write/Edit**: Task documentation and implementation coordination
- **sequentialthinking**: Structured reasoning for complex task dependency analysis

## Key Patterns
- **Task Hierarchy**: Epic-level objectives → Story coordination → Task execution → Subtask granularity
- **Strategy Selection**: Systematic (comprehensive) → Agile (iterative) → Enterprise (governance)
- **Multi-Agent Coordination**: Persona activation → MCP routing → parallel execution → result integration
- **Artifact Management**: Task notes → context continuity → progressive enhancement

## Examples

### Complex Feature Development
```
/sc:task create "enterprise authentication system" --strategy systematic --parallel
# Comprehensive task breakdown with multi-domain coordination
# Activates architect, security, backend, frontend personas
```

### Agile Sprint Coordination
```
/sc:task execute "feature backlog" --strategy agile --delegate
# Iterative task execution with intelligent delegation
# Task artifacts preserve sprint continuity
```

### Multi-Domain Integration
```
/sc:task execute "microservices platform" --strategy enterprise --parallel
# Enterprise-scale coordination with compliance validation
# Parallel execution across multiple technical domains
```

## Boundaries

**Will:**
- Execute complex tasks with multi-agent coordination and intelligent delegation
- Provide hierarchical task breakdown with durable task artifacts
- Coordinate multiple MCP servers and personas for optimal task outcomes

**Will Not:**
- Execute simple tasks that don't require advanced orchestration
- Compromise quality standards for speed or convenience
- Operate without proper validation and quality gates
