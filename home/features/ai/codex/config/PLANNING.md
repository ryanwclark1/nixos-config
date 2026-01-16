# Planning & Architecture for Codex Usage

> **Purpose**: Architecture principles, design decisions, and best practices for using Codex effectively.
> **Read**: At session start, before implementation

## Codex Philosophy

Codex is a coding agent that can read, edit, and run code. It helps you:
- **Write code**: Generate code that matches your intent, adapting to existing project structure
- **Understand codebases**: Read and explain complex or legacy code
- **Review code**: Analyze code to identify bugs, logic errors, and edge cases
- **Debug problems**: Trace failures, diagnose root causes, and suggest fixes
- **Automate tasks**: Run repetitive workflows like refactoring, testing, migrations

## Core Principles

### 1. Evidence-Based Development
- Verify with official sources (use Context7 MCP for documentation)
- Check existing code patterns before implementing
- Show test results, not just "tests pass"
- Provide specific line references and examples
- Never guess - always verify

### 2. Confidence-First Approach
Before starting work, assess confidence:
- **≥90%**: Proceed with implementation
- **70-89%**: Present approach options and trade-offs, continue investigation
- **<70%**: STOP - ask clarifying questions, research more, investigate root cause first

### 3. Incremental and Safe
- Make small, safe, measurable changes
- Run tests after each step
- Preserve functionality (zero behavior changes when refactoring)
- Create git checkpoints before and after tasks

### 4. Tool Selection
- **Context7**: Official library documentation and framework patterns
- **Sequential Thinking**: Complex problem-solving and architecture decisions
- **Playwright**: Web automation, testing, and scraping
- **GitHub**: Repository operations and workflow management
- **Serena**: Code directory access and semantic search
- **Git**: Version control operations

## Workflow Patterns

### Development Workflow
1. **Understand**: Read existing code, understand patterns
2. **Plan**: Design approach with confidence assessment
3. **Implement**: Code incrementally with tests
4. **Validate**: Run tests, verify behavior
5. **Review**: Self-check before completion

### Debugging Workflow
1. **Gather Evidence**: Collect logs, error messages, system state
2. **Form Hypotheses**: Develop multiple theories
3. **Test Systematically**: Validate each hypothesis
4. **Identify Root Cause**: Find underlying cause, not just symptoms
5. **Implement Fix**: Minimal fix with verification

### Refactoring Workflow
1. **Measure**: Current complexity metrics
2. **Plan**: Safe refactoring steps
3. **Execute**: Incremental changes with tests
4. **Validate**: Verify behavior preservation
5. **Document**: Record improvements made

## Rules System

Codex supports a Rules system to control command execution outside the sandbox.

### Rule Locations
- Rules are stored in `~/.codex/rules/*.rules` files
- Codex loads all `*.rules` files at startup
- Rules use Starlark syntax (Python-like but safe)

### Rule Decisions
- **`allow`**: Run command without prompting
- **`prompt`**: Prompt before each matching invocation
- **`forbidden`**: Block the request without prompting

### Testing Rules
```bash
codex execpolicy check --pretty \
  --rules ~/.codex/rules/default.rules \
  -- git status
```

## Custom Prompts

Custom prompts are reusable Markdown files in `~/.codex/prompts/` that behave like slash commands.

### Invoking Prompts
- Use `/prompts:name` in Codex to invoke
- Example: `/prompts:draftpr FILES=src/main.ts PR_TITLE="Add feature"`

### Available Prompts
- `/prompts:draftpr` - Create draft PR workflow
- `/prompts:review` - Comprehensive code review
- `/prompts:refactor` - Systematic refactoring
- `/prompts:debug` - Evidence-based debugging
- `/prompts:test` - Create comprehensive test suite

## Skills System

Codex has a Skills system for sharing prompts and workflows across teams.

### Installing Skills
```
$skill-installer install create-plan
$skill-installer install linear
$skill-installer install notion-spec-to-implementation
```

### Available Skills
- **create-plan**: Create structured project plans
- **linear**: Integrate with Linear for issue tracking
- **notion-spec-to-implementation**: Convert Notion specs to code

## Configuration Profiles

Codex supports profiles for different use cases (CLI only):

- **development**: Medium reasoning, on-request approval, workspace-write
- **deep-review**: High reasoning, never approval, full access
- **lightweight**: Lower model, untrusted approval, read-only

Switch profiles: `codex --profile <name>`

## Best Practices

1. **Always assess confidence** before starting work
2. **Verify with sources** - use Context7 for official documentation
3. **Check existing patterns** - use Grep/Glob before implementing
4. **Show evidence** - provide test results, code examples, metrics
5. **Self-check before completion** - validate all requirements met
6. **Use appropriate agents** - match agent to task complexity
7. **Leverage MCP servers** - use the right tool for the job
8. **Follow Rules system** - respect command execution policies
9. **Use Custom Prompts** - create reusable workflows
10. **Create git checkpoints** - before and after each task

## Safety Guidelines

- Codex can modify your codebase - create git checkpoints
- Review commands before execution
- Use appropriate approval policies
- Respect sandbox boundaries
- Test in safe environments first
- Never skip validation steps


