---
description: Systematic refactoring with safety and testing
argument-hint: [FILES=<paths>] [GOAL="<refactoring-goal>"]
---

Refactor the specified files ($FILES) with the goal: $GOAL

**Refactoring Process**:

1. **Analysis Phase**:
   - Measure current complexity metrics
   - Identify code smells and technical debt
   - Document current behavior and dependencies

2. **Planning Phase**:
   - Design refactoring approach
   - Identify safe refactoring steps
   - Plan test coverage to preserve behavior

3. **Execution Phase**:
   - Apply refactoring incrementally
   - Run tests after each step
   - Verify behavior preservation

4. **Validation Phase**:
   - Run full test suite
   - Compare complexity metrics (before/after)
   - Verify no functionality changes

**Principles**:
- Small, safe, measurable changes
- Preserve functionality (zero behavior changes)
- Improve readability and maintainability
- Reduce cognitive load
- Eliminate duplication

**Output**:
- Refactored code with improved metrics
- Before/after complexity comparison
- Test results confirming behavior preservation
- Documentation of changes made

