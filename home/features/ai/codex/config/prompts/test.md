---
description: Create comprehensive test suite with edge case coverage
argument-hint: [FILES=<paths>] [TYPE="unit|integration|e2e"]
---

Create comprehensive tests for: $FILES

Test type: $TYPE (default: unit)

**Test Strategy**:

1. **Test Planning**:
   - Identify test scenarios and edge cases
   - Prioritize high-impact, high-probability areas
   - Plan coverage for critical paths

2. **Test Implementation**:
   - Happy path tests
   - Edge case tests (boundary conditions, null values, empty inputs)
   - Error condition tests
   - Integration tests (if applicable)

3. **Test Quality**:
   - Clear, descriptive test names
   - Arrange-Act-Assert pattern
   - Isolated tests (no dependencies)
   - Fast execution

4. **Coverage Validation**:
   - Verify test coverage
   - Identify gaps
   - Add missing test cases

**Output**:
- Comprehensive test suite
- Test coverage report
- Test execution results
- Recommendations for additional tests

