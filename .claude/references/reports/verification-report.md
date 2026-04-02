# Verification Report Template

Written to `.temp/tasks/<task_name>/verify-report.md`.

```markdown
# Verification Report: <task-name>

**Date:** <date>
**Mode:** standard | deep
**Task-Verifier result:** PASS | PARTIAL | FAIL

## Completeness
| Phase | Tasks | Complete | Issues |
|-------|-------|----------|--------|

## Quality Commands
| Command | Result | Notes |
|---------|--------|-------|

## PRD Compliance
| Requirement | Status | Notes |
|-------------|--------|-------|

## Constraint Compliance
| Constraint | Source | Status | Notes |
|------------|--------|--------|-------|
| [Invariant 1] | Invariant | PASS | - |
| [From D1: ...] | Decision D1 | PASS | - |

## Deep Mode Checks (if applicable)
### Security
| Check | Result | Notes |
|-------|--------|-------|

### Performance
| Check | Result | Notes |
|-------|--------|-------|

### Handoffs
| Phase | Warnings | Addressed |
|-------|----------|-----------|

## Issues Found
| # | Severity | File | Issue | Recommendation |
|---|----------|------|-------|----------------|

## Summary
[Overall assessment. If FAIL or PARTIAL — clear next steps for the user.]
```
