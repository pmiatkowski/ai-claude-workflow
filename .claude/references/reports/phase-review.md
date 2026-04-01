# Phase Review Report Template

Written to `.temp/tasks/<task_name>/reviews/phase-N-review.md`.

```markdown
# Phase Review: Phase N - <phase-name>

**Date:** <date>
**Reviewer:** phase-reviewer agent
**Verdict:** APPROVED | CHANGES_REQUESTED

## Summary
[Brief overall assessment]

## Checklist Results
| Category | Item | Status | Notes |
|----------|------|--------|-------|
| Completeness | All tasks complete | PASS | - |
| Correctness | Matches plan | PASS | - |
| Quality | No duplication | FAIL | Duplicated validation logic |

## Issues Found
| # | Severity | File | Issue | Required Fix |
|---|----------|------|-------|--------------|
| 1 | HIGH | auth.ts | Missing error handling | Add try-catch around API call |
| 2 | MEDIUM | users.ts | Duplicated validation | Extract to shared utility |

## Verdict Reasoning
[Explain why APPROVED or CHANGES_REQUESTED]

## If CHANGES_REQUESTED
The task-executor must address these issues:
1. [Specific fix needed]
2. [Specific fix needed]

After fixes, re-run this review.
```
