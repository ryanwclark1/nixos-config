---
name: improve
description: "Apply systematic improvements to code quality, performance, maintainability, and cleanup"
category: workflow
complexity: standard
mcp-servers: [sequential, context7]
personas: [architect, performance, quality, security]
---

# /sc:improve - Code Improvement

## Triggers
- Code quality enhancement and refactoring requests
- Performance optimization and bottleneck resolution needs
- Maintainability improvements and technical debt reduction
- Best practices application and coding standards enforcement
- Code maintenance and technical debt reduction requests
- Dead code removal and import optimization needs
- Project structure improvement and organization requirements
- Codebase hygiene and cleanup initiatives

**Note:** Consider using `/sc:analyze` first to assess current code quality and identify improvement opportunities before applying systematic improvements.

## Usage
```
/sc:improve [target] [--type quality|performance|maintainability|style|cleanup] [--safe] [--interactive] [--aggressive]
```

**Cleanup-specific options:**
- `--type cleanup` with `--subtype code|imports|files|all` for cleanup operations
- `--aggressive` flag for thorough cleanup (use with caution)

## Behavioral Flow
1. **Analyze**: Examine codebase for improvement opportunities and quality issues
2. **Plan**: Choose improvement approach and activate relevant personas for expertise
3. **Execute**: Apply systematic improvements with domain-specific best practices
4. **Validate**: Ensure improvements preserve functionality and meet quality standards
5. **Document**: Generate improvement summary and recommendations for future work

Key behaviors:
- Multi-persona coordination (architect, performance, quality, security) based on improvement type
- Framework-specific optimization via Context7 integration for best practices
- Systematic analysis via Sequential MCP for complex multi-component improvements
- Safe refactoring with comprehensive validation and rollback capabilities

## MCP Integration
- **Sequential MCP**: Auto-activated for complex multi-step improvement analysis and planning
- **Context7 MCP**: Framework-specific best practices and optimization patterns
- **Persona Coordination**: Architect (structure), Performance (speed), Quality (maintainability), Security (safety)

## Tool Coordination
- **Read/Grep/Glob**: Code analysis and improvement opportunity identification
- **Edit/MultiEdit**: Safe code modification and systematic refactoring
- **TodoWrite**: Progress tracking for complex multi-file improvement operations
- **Task**: Delegation for large-scale improvement workflows requiring systematic coordination

## Key Patterns
- **Quality Improvement**: Code analysis → technical debt identification → refactoring application
- **Performance Optimization**: Profiling analysis → bottleneck identification → optimization implementation
- **Maintainability Enhancement**: Structure analysis → complexity reduction → documentation improvement
- **Security Hardening**: Vulnerability analysis → security pattern application → validation verification
- **Code Cleanup**: Usage analysis → dead code detection → safe removal with dependency validation
- **Import Optimization**: Dependency analysis → unused import removal and organization
- **Structure Cleanup**: Architectural analysis → file organization and modular improvements

## Examples

### Code Quality Enhancement
```
/sc:improve src/ --type quality --safe
# Systematic quality analysis with safe refactoring application
# Improves code structure, reduces technical debt, enhances readability
```

### Performance Optimization
```
/sc:improve api-endpoints --type performance --interactive
# Performance persona analyzes bottlenecks and optimization opportunities
# Interactive guidance for complex performance improvement decisions
```

### Maintainability Improvements
```
/sc:improve legacy-modules --type maintainability --preview
# Architect persona analyzes structure and suggests maintainability improvements
# Preview mode shows changes before application for review
```

### Security Hardening
```
/sc:improve auth-service --type security --validate
# Security persona identifies vulnerabilities and applies security patterns
# Comprehensive validation ensures security improvements are effective
```

### Code Cleanup (Dead Code Removal)
```
/sc:improve src/ --type cleanup --subtype code --safe
# Conservative cleanup with automatic safety validation
# Removes dead code while preserving all functionality
# Architect and quality personas coordinate for safe removal
```

### Import Optimization
```
/sc:improve --type cleanup --subtype imports --preview
# Analyzes and shows unused import cleanup without execution
# Framework-aware optimization via Context7 patterns
# Quality persona ensures no breaking changes
```

### Comprehensive Project Cleanup
```
/sc:improve --type cleanup --subtype all --interactive
# Multi-domain cleanup with user guidance for complex decisions
# Activates architect, quality, and security personas for comprehensive analysis
# Sequential MCP provides systematic cleanup workflow
```

### Aggressive Cleanup
```
/sc:improve components/ --type cleanup --aggressive
# Thorough cleanup with Context7 framework patterns
# Sequential analysis for complex dependency management
# Use with caution - validates thoroughly before removal
```

## Boundaries

**Will:**
- Apply systematic improvements with domain-specific expertise and validation
- Provide comprehensive analysis with multi-persona coordination and best practices
- Execute safe refactoring with rollback capabilities and quality preservation

**Will Not:**
- Apply risky improvements without proper analysis and user confirmation
- Make architectural changes without understanding full system impact
- Override established coding standards or project-specific conventions
- Remove code without thorough safety analysis and dependency validation (cleanup operations)
- Override project-specific cleanup exclusions or architectural constraints
- Apply cleanup operations that compromise functionality or introduce bugs

