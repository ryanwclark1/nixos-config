---
name: analyze
description: "Comprehensive code analysis for quality, security, and performance assessment"
category: utility
---

# /analyze - Code Analysis and Quality Assessment

## Usage
```
/analyze [path] [--focus quality|security|performance] [--depth quick|deep]
```

## Description
Performs comprehensive static code analysis to identify issues related to code quality, security vulnerabilities, and performance bottlenecks. Generates actionable recommendations with severity ratings.

## Examples

### Full Project Analysis
```
/analyze
```
Analyzes the entire project for quality, security, and performance issues.

### Security-Focused Analysis
```
/analyze src/auth --focus security --depth deep
```
Deep security analysis of authentication components with vulnerability assessment.

### Quick Quality Check
```
/analyze src/components --focus quality --depth quick
```
Rapid quality assessment to identify code smells and maintainability issues.

## Workflow
1. **Discover** - Identify files and detect languages
2. **Scan** - Apply appropriate analysis techniques
3. **Evaluate** - Rate findings by severity
4. **Recommend** - Provide actionable improvements
5. **Report** - Generate comprehensive analysis summary

## Key Features
- Multi-domain analysis (quality, security, performance)
- Language-specific pattern recognition
- Severity-based issue prioritization
- Actionable improvement recommendations
- Comprehensive metrics and reporting