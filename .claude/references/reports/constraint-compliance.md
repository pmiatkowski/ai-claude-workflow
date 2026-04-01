# Constraint Compliance Report Template

Written to `.temp/tasks/<task_name>/constraint-report.md`.

```markdown
# Constraint Compliance Report: <task-name>

**Date:** <date>
**Stage:** pre-plan | post-plan | post-phase | final
**Phase:** (if applicable)

## Summary
| Category | Total | Pass | Fail | Unchecked |
|----------|-------|------|------|-----------|
| Invariants | 5 | 4 | 0 | 1 |
| Decision-Derived | 3 | 3 | 0 | 0 |
| **Total** | 8 | 7 | 0 | 1 |

## Invariant Compliance
| ID | Constraint | Status | Evidence | Notes |
|----|------------|--------|----------|-------|
| I1 | All API calls authenticated | PASS | authMiddleware on all routes | - |
| I2 | No plaintext passwords | PASS | bcrypt used in auth.ts | - |

## Decision-Derived Compliance
| ID | From | Constraint | Status | Evidence |
|----|------|------------|--------|----------|
| D1-1 | D1 | Use OAuth2 | PASS | OAuth2Strategy imported |
| D2-1 | D2 | REST API | PASS | Express routes defined |

## Violations Found
| # | Severity | Constraint | File | Issue | Required Fix |
|---|----------|------------|------|-------|--------------|
| 1 | HIGH | I5 | api/public.ts | Missing auth | Add authMiddleware |

## Recommendations
1. [Specific recommendation]
2. [Specific recommendation]

## Verdict
PASS | FAIL | NEEDS_ATTENTION
```
