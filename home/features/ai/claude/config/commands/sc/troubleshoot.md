---
name: troubleshoot
description: "Diagnose and resolve issues in code, builds, and deployments"
category: utility
complexity: standard
mcp-servers: [sequential, context7]
personas: [qa-specialist, security]
---

# /sc:troubleshoot - Issue Diagnosis and Resolution

## Triggers
- Issue diagnosis requests for code bugs, build failures, and deployment problems
- Error debugging needs requiring systematic root cause analysis
- Build failure resolution and compilation error fixing requirements
- Performance problem investigation and bottleneck identification needs
- Deployment issue troubleshooting and environment configuration problems

## Usage
```
/sc:troubleshoot [issue-description] [--type bug|build|performance|deployment] [--fix] [--interactive]
```

## Behavioral Flow
1. **Analyze**: Examine issue description, gather context, and identify problem domain
2. **Investigate**: Execute systematic root cause analysis with diagnostic procedures
3. **Debug**: Apply structured debugging methodologies and error pattern recognition
4. **Propose**: Validate solution approaches with safety checks and impact assessment
5. **Resolve**: Apply fixes with verification and comprehensive problem documentation

Key behaviors:
- Systematic root cause analysis with multi-domain troubleshooting capabilities
- Intelligent error pattern recognition using Sequential MCP for complex debugging
- Framework-specific troubleshooting via Context7 integration for common issues
- Safe fix application with comprehensive validation and rollback capabilities

## MCP Integration
- **Sequential MCP**: Auto-activated for complex multi-step debugging and systematic root cause analysis
- **Context7 MCP**: Framework-specific troubleshooting patterns and common issue resolution strategies
- **Persona Coordination**: QA Specialist (testing/debugging), Security (vulnerability analysis)

## Tool Coordination
- **Read/Grep**: Log analysis, error parsing, and code inspection for issue identification
- **Edit/MultiEdit**: Safe fix application with validation and rollback capabilities
- **Bash**: Execution of diagnostic commands and validation of fixes
- **Glob**: File discovery and pattern matching for issue scope assessment

## Key Patterns
- **Root Cause Analysis**: Issue description → diagnostic procedures → root cause identification → solution validation
- **Error Pattern Recognition**: Error logs → pattern matching → framework-specific resolution → fix application
- **Safe Fix Application**: Solution validation → impact assessment → fix application → verification → documentation
- **Multi-Domain Troubleshooting**: Bug analysis → Build debugging → Performance investigation → Deployment resolution

## Examples

### Bug Investigation
```
/sc:troubleshoot "Null pointer exception in user service" --type bug
# Analyzes error context, examines stack traces, and provides targeted fix recommendations
# QA Specialist persona coordinates systematic debugging procedures
```

### Build Failure Resolution
```
/sc:troubleshoot "TypeScript compilation errors" --type build --fix
# Analyzes build logs and automatically applies safe fixes for common compilation issues
# Context7 MCP provides framework-specific error resolution patterns
```

### Performance Problem Diagnosis
```
/sc:troubleshoot "API response times degraded" --type performance
# Identifies performance bottlenecks through systematic analysis
# Provides optimization recommendations with impact assessment
```

### Deployment Issue Troubleshooting
```
/sc:troubleshoot "deployment failing in staging environment" --type deployment --interactive
# Interactive debugging with guided diagnostic procedures
# Sequential MCP coordinates multi-step investigation and resolution
```

## Boundaries

**Will:**
- Systematically diagnose issues through root cause analysis with validated solutions
- Apply safe fixes with comprehensive validation and verification procedures
- Provide multi-domain troubleshooting across code bugs, build failures, performance, and deployments
- Use framework-specific patterns via Context7 for common issue resolution

**Will Not:**
- Apply fixes without proper root cause analysis and safety validation
- Execute destructive operations or modify critical system configurations without confirmation
- Replace proactive analysis tools (use `/sc:analyze` for comprehensive code assessment before issues occur)
- Handle issues requiring manual intervention or domain-specific expertise beyond automated troubleshooting

**Related Commands:**
- Use `/sc:analyze` for proactive code analysis and quality assessment before issues occur
- Use `/sc:improve` for systematic code improvements after identifying issues through troubleshooting
