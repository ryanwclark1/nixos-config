---
description: Comprehensive code review with security and quality focus
argument-hint: [FILES=<paths>] [FOCUS="security|performance|quality|all"]
---

Review the specified files ($FILES) or all modified files if none are specified.

Focus areas based on $FOCUS:
- **security**: OWASP Top 10, injection vulnerabilities, authentication flaws, sensitive data exposure
- **performance**: N+1 queries, memory leaks, async bottlenecks, caching strategies
- **quality**: Maintainability, testability, code complexity, best practices
- **all**: Comprehensive review across all dimensions

For each finding, provide:
1. **Severity**: Critical, High, Medium, Low
2. **Location**: Specific file and line numbers
3. **Issue**: Clear description of the problem
4. **Recommendation**: Specific fix with code examples
5. **Impact**: Business/technical impact assessment

Organize findings by:
- Critical issues (must fix)
- Warnings (should fix)
- Suggestions (consider improving)

Include an executive summary with overall quality score (1-10) and risk assessment.

