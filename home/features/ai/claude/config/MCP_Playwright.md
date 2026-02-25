# Playwright MCP Server

> **Purpose**: Browser automation and E2E testing with real browser interaction
> **Activation**: Auto-selected for browser testing, or use `--play` / `--playwright` flag
> **Related**: See [FLAGS.md](mdc:home/features/ai/claude/config/FLAGS.md) for flag usage

## When to Use Playwright

**Use Playwright when**:
- Browser testing and E2E test scenarios
- Visual testing, screenshot, or UI validation requests
- Form submission and user interaction testing
- Cross-browser compatibility validation
- Performance testing requiring real browser rendering
- Accessibility testing with automated WCAG compliance

**Choose Playwright over**:
- **Unit tests**: For integration testing, user journeys, visual validation
- **Static analysis**: When you need actual browser rendering and interaction
- **Code review**: For real user interaction testing, not code logic review

**Not for**:
- Static code analysis or syntax checking
- Logic validation without browser interaction
- Simple code explanations or reviews

## Works Best With
- **Sequential**: Sequential plans test strategy → Playwright executes browser automation
- **Manual Implementation**: Manual coding creates UI components → Playwright validates accessibility and behavior

## Decision Tree

```
Need browser interaction? → Playwright
Need visual validation? → Playwright
Need E2E testing? → Playwright
Need accessibility testing? → Playwright
Code review only? → Native Claude
Static analysis? → Native Claude
```

## Examples

### E2E Testing
```
Request: "test the login flow"
→ Playwright:
  - Navigate to login page
  - Fill credentials
  - Submit form
  - Verify redirect
  - Check session
```

### Form Validation
```
Request: "check if form validation works"
→ Playwright:
  - Test invalid inputs
  - Verify error messages
  - Test valid submission
  - Check client-side validation
```

### Visual Testing
```
Request: "take screenshots of responsive design"
→ Playwright:
  - Capture at different viewport sizes
  - Compare visual regressions
  - Validate responsive breakpoints
```

### Accessibility Testing
```
Request: "validate accessibility compliance"
→ Playwright:
  - Run automated WCAG checks
  - Test keyboard navigation
  - Verify screen reader compatibility
```

### When NOT to Use
```
Request: "review this function's logic"
→ Native Claude: Static code analysis, no browser needed

Request: "explain the authentication code"
→ Native Claude: Code review, no interaction testing needed
```

## Integration

### With Other MCP Servers
- **+ Sequential**: Sequential plans test strategy → Playwright executes browser automation
- **+ Manual Coding**: Manual implementation creates UI components → Playwright validates accessibility and behavior
- **+ Context7**: Context7 provides testing patterns → Playwright implements them

### Best Practices
1. **Real Browsers**: Use for actual browser behavior, not unit tests
2. **User Journeys**: Test complete workflows, not isolated functions
3. **Visual Validation**: Capture screenshots for visual regression testing
4. **Accessibility**: Integrate WCAG compliance checks
5. **Performance**: Measure real-world performance, not synthetic metrics
