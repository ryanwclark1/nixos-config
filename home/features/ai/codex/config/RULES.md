# Codex Behavioral Rules

Actionable rules for enhanced Codex framework operation.

## Rule Priority System

**🔴 CRITICAL**: Security, data safety, production breaks - Never compromise
**🟡 IMPORTANT**: Quality, maintainability, professionalism - Strong preference
**🟢 RECOMMENDED**: Optimization, style, best practices - Apply when practical

### Conflict Resolution Hierarchy
1. **Safety First**: Security/data rules always win
2. **Scope > Features**: Build only what's asked > complete everything
3. **Quality > Speed**: Except in genuine emergencies
4. **Context Matters**: Prototype vs Production requirements differ

## Workflow Rules
**Priority**: 🟡 **Triggers**: All development tasks

- **Task Pattern**: Understand → Plan (with parallelization analysis) → Execute → Track → Validate
- **Batch Operations**: ALWAYS parallel tool calls by default, sequential ONLY for dependencies
- **Validation Gates**: Always validate before execution, verify after completion
- **Quality Checks**: Run lint/typecheck before marking tasks complete
- **Context Retention**: Maintain ≥90% understanding across operations
- **Evidence-Based**: All claims must be verifiable through testing or documentation
- **Discovery First**: Complete project-wide analysis before systematic changes

✅ **Right**: Plan → Execute → Validate
❌ **Wrong**: Jump directly to implementation without planning

## Planning Efficiency
**Priority**: 🔴 **Triggers**: All planning phases, multi-step tasks

- **Parallelization Analysis**: During planning, explicitly identify operations that can run concurrently
- **Tool Optimization Planning**: Plan for optimal MCP server combinations and batch operations
- **Dependency Mapping**: Clearly separate sequential dependencies from parallelizable tasks
- **Resource Estimation**: Consider token usage and execution time during planning phase
- **Efficiency Metrics**: Plan should specify expected parallelization gains (e.g., "3 parallel ops = 60% time saving")

✅ **Right**: "Plan: 1) Parallel: [Read 5 files] 2) Sequential: analyze → 3) Parallel: [Edit all files]"
❌ **Wrong**: "Plan: Read file1 → Read file2 → Read file3 → analyze → edit file1 → edit file2"

## Implementation Completeness
**Priority**: 🟡 **Triggers**: Creating features, writing functions, code generation

- **No Partial Features**: If you start implementing, you MUST complete to working state
- **No TODO Comments**: Never leave TODO for core functionality or implementations
- **Error Handling**: Always include appropriate error handling for user-facing code
- **Testing**: Include tests for critical paths and edge cases
- **Documentation**: Document public APIs and complex logic

✅ **Right**: Complete feature with tests and error handling
❌ **Wrong**: Partial implementation with TODO comments

## Code Quality Standards
**Priority**: 🟡 **Triggers**: All code generation and modification

- **DRY Principle**: Don't repeat yourself - extract common patterns
- **Single Responsibility**: Each function/class should have one clear purpose
- **Naming Conventions**: Use descriptive, intention-revealing names
- **Formatting**: Follow project-specific style guides
- **Type Safety**: Prefer typed code when possible (TypeScript, etc.)

✅ **Right**: `calculateTotalPrice(items: Item[]): number`
❌ **Wrong**: `calc(items: any): any`

## Security Rules
**Priority**: 🔴 **Triggers**: All code that handles data, authentication, or system access

- **Never Hardcode Secrets**: Use environment variables or secure vaults
- **Input Validation**: Always validate and sanitize user input
- **SQL Injection Prevention**: Use parameterized queries, never string concatenation
- **XSS Prevention**: Sanitize output, use proper escaping
- **Principle of Least Privilege**: Request minimum necessary permissions

✅ **Right**: Use parameterized queries, environment variables for secrets
❌ **Wrong**: String concatenation for SQL, hardcoded API keys

## MCP Server Usage
**Priority**: 🟢 **Triggers**: When selecting tools for tasks

- **Context7**: Use for official documentation and framework patterns
- **Sequential**: Use for complex problem-solving requiring step-by-step reasoning
- **Playwright**: Use for web automation, testing, and scraping
- **GitHub**: Use for repository operations and workflow management
- **Serena**: Use for code directory access and file operations

✅ **Right**: Use Context7 for React documentation, Sequential for architecture decisions
❌ **Wrong**: Use web search when Context7 has the official docs

## Sandbox and Safety
**Priority**: 🔴 **Triggers**: All command execution

- **Review Before Execute**: Understand what commands will do before running
- **Workspace Scope**: Stay within project workspace unless explicitly requested
- **Backup Critical Data**: Create backups before destructive operations
- **Test in Safe Environment**: Test risky operations in isolated environments first
- **Approval Workflow**: Respect approval policies for sensitive operations

✅ **Right**: Review git commands before execution, test in branch
❌ **Wrong**: Execute destructive commands without review

## Performance Optimization
**Priority**: 🟢 **Triggers**: When performance is a concern

- **Measure First**: Profile before optimizing
- **Batch Operations**: Group similar operations together
- **Lazy Loading**: Load data only when needed
- **Caching**: Cache expensive computations and API calls
- **Parallel Processing**: Use parallel execution where possible

✅ **Right**: Profile → Identify bottleneck → Optimize → Measure improvement
❌ **Wrong**: Optimize without measuring impact

## Documentation Standards
**Priority**: 🟢 **Triggers**: Creating or modifying code

- **Public APIs**: Always document public functions and classes
- **Complex Logic**: Explain non-obvious algorithms and business logic
- **Examples**: Include usage examples for public APIs
- **Changelog**: Document breaking changes and major updates
- **README**: Keep README up to date with setup and usage instructions

✅ **Right**: Clear docstrings with examples for public APIs
❌ **Wrong**: Undocumented public functions with complex logic

## Error Handling
**Priority**: 🟡 **Triggers**: All code that can fail

- **Graceful Degradation**: Handle errors gracefully, don't crash
- **User-Friendly Messages**: Provide clear, actionable error messages
- **Logging**: Log errors with sufficient context for debugging
- **Error Recovery**: Attempt recovery when possible
- **Validation**: Validate inputs early to prevent downstream errors

✅ **Right**: Try-catch with specific error handling and user-friendly messages
❌ **Wrong**: Silent failures or generic error messages

## Testing Requirements
**Priority**: 🟡 **Triggers**: Implementing features or fixing bugs

- **Unit Tests**: Test individual functions and components
- **Integration Tests**: Test component interactions
- **Edge Cases**: Test boundary conditions and error cases
- **Regression Tests**: Add tests when fixing bugs
- **Test Coverage**: Aim for meaningful coverage, not just numbers

✅ **Right**: Tests for happy path, edge cases, and error conditions
❌ **Wrong**: Only testing the happy path


