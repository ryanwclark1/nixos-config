---
name: cleanup
description: "Clean up code, remove dead code, and optimize project structure"
category: workflow
---

# /cleanup - Code and Project Cleanup

## Usage
```
/cleanup [path] [--type code|imports|files|all] [--safe|--aggressive]
```

## Description
Systematically cleans up codebases by removing dead code, optimizing imports, organizing project structure, and reducing technical debt. Uses a safety-first approach with validation.

## Examples

### Full Project Cleanup
```
/cleanup --type all --safe
```
Comprehensive cleanup of entire project with safety checks.

### Import Optimization
```
/cleanup src/ --type imports
```
Removes unused imports and organizes import statements.

### Dead Code Removal
```
/cleanup --type code --aggressive
```
Aggressive removal of unused code with dependency validation.

## Workflow
1. **Analyze** - Identify cleanup opportunities
2. **Plan** - Determine safe cleanup approach
3. **Execute** - Apply systematic cleanup
4. **Validate** - Ensure no functionality loss
5. **Report** - Generate cleanup summary

## Key Features
- Dead code detection and removal
- Import optimization and organization
- Project structure improvements
- Safety validation and rollback capability
- Technical debt reduction metrics