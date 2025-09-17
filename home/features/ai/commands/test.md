---
name: test
description: "Execute tests with coverage analysis and quality reporting"
category: utility
---

# /test - Testing and Quality Assurance

## Usage
```
/test [path] [--type unit|integration|e2e|all] [--coverage] [--watch]
```

## Description
Executes test suites with automatic framework detection, coverage analysis, and comprehensive reporting. Supports unit, integration, and end-to-end testing with intelligent failure analysis.

## Examples

### Run All Tests
```
/test
```
Discovers and runs all tests with standard configuration.

### Unit Tests with Coverage
```
/test src/components --type unit --coverage
```
Runs unit tests for specific directory with detailed coverage metrics.

### End-to-End Testing
```
/test --type e2e
```
Executes browser-based end-to-end tests with cross-browser validation.

### Watch Mode
```
/test --watch
```
Continuous testing with real-time feedback during development.

## Workflow
1. **Discover** - Find and categorize available tests
2. **Configure** - Set up test environment
3. **Execute** - Run tests with progress tracking
4. **Analyze** - Generate coverage and failure reports
5. **Report** - Provide actionable recommendations

## Key Features
- Automatic test framework detection
- Comprehensive coverage reporting
- Intelligent failure analysis
- Watch mode for continuous testing
- Cross-browser e2e testing support