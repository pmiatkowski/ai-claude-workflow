# Plan Verification Report Template

Written to `.temp/tasks/<task_name>/plan-verify-report.md`.

```markdown
# Plan Verification Report: <task-name>

**Date:** <date>
**Mode:** quick | deep
**Result:** PASS | PARTIAL | FAIL

## Coverage Check
| PRD Requirement | Mapped Tasks | Status |
|-----------------|--------------|--------|
| FR-1: ... | Task 1.1, Task 2.3 | COVERED |
| FR-2: ... | - | MISSING |

## Dependency Check
| Phase | Depends On | Cycle Risk |
|-------|------------|------------|
| 1 | None | OK |
| 2 | Phase 1 | OK |

## Quality Command Check
| Phase | Commands Defined | Status |
|-------|-----------------|--------|
| 1 | npm run lint, npm test | OK |
| 2 | - | MISSING |

## Guideline Consistency Check
| Guideline (from CLAUDE.md) | Phase(s) Affected | Status | Notes |
|----------------------------|-------------------|--------|-------|
| Naming convention: ... | Phase 1, Phase 2 | OK | - |
| Structure rule: ... | Phase 3 | VIOLATION | Plan creates file outside allowed dirs |

## Issues Found
| # | Severity | Issue | Recommendation |
|---|----------|-------|----------------|
| 1 | HIGH | FR-2 has no tasks | Add tasks to Phase 2 |
| 2 | MEDIUM | Phase 2 missing quality commands | Add quality check section |

## Recommendation
[BLOCK / PROCEED / PROCEED WITH CAUTION]

[If BLOCK: clear steps to fix]
```
