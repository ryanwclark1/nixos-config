---
name: troubleshoot
description: "Diagnose and resolve issues in code, builds, and deployments"
category: utility
---

# /troubleshoot - Issue Diagnosis and Resolution

## Usage
```
/troubleshoot [issue-description] [--type bug|build|performance|deployment] [--fix]
```

## Description
Systematically diagnoses issues through root cause analysis, providing validated solutions and optionally applying safe fixes. Covers code bugs, build failures, performance problems, and deployment issues.

## Examples

### Bug Investigation
```
/troubleshoot "Null pointer exception in user service" --type bug
```
Analyzes error context, examines stack traces, and provides targeted fix recommendations.

### Build Failure
```
/troubleshoot "TypeScript compilation errors" --type build --fix
```
Analyzes build logs and automatically applies safe fixes for common compilation issues.

### Performance Issues
```
/troubleshoot "API response times degraded" --type performance
```
Identifies performance bottlenecks and provides optimization recommendations.

## Workflow
1. **Analyze** - Examine issue description and gather context
2. **Investigate** - Identify potential root causes
3. **Debug** - Execute systematic debugging procedures
4. **Propose** - Validate solution approaches
5. **Resolve** - Apply fixes and verify resolution

## Key Features
- Systematic root cause analysis
- Multi-domain troubleshooting
- Structured debugging methodologies
- Safe fix application with verification
- Comprehensive problem documentation