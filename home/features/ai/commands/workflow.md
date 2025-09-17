---
name: workflow
description: "Generate structured implementation workflows from requirements"
category: orchestration
---

# /workflow - Implementation Workflow Generator

## Usage
```
/workflow [prd-file|feature-description] [--strategy systematic|agile] [--depth shallow|normal|deep]
```

## Description
Generates comprehensive implementation workflows from PRDs and feature specifications. Creates structured task breakdowns with dependency mapping and multi-domain coordination for complete implementation strategies.

## Examples

### PRD-Based Workflow
```
/workflow requirements.md --strategy systematic --depth deep
```
Comprehensive PRD analysis with systematic workflow generation and task dependencies.

### Agile Feature Planning
```
/workflow "user authentication system" --strategy agile
```
Generates agile workflow with user stories and sprint-based task organization.

### Quick Implementation Plan
```
/workflow feature-brief.txt --depth shallow
```
Rapid workflow generation for quick implementation planning.

## Workflow
1. **Analyze** - Parse requirements and specifications
2. **Plan** - Generate workflow structure with dependencies
3. **Coordinate** - Organize tasks by domain and expertise
4. **Execute** - Create step-by-step implementation plan
5. **Validate** - Ensure workflow completeness

## Key Features
- PRD and specification analysis
- Dependency mapping and task orchestration
- Multi-domain task coordination
- Progressive workflow enhancement
- Implementation strategy generation