# Report Formats Reference

Centralized templates for structured output. Agents read this file when generating reports.

---

## Task Reports

### constraint-compliance

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

---

### verification-report

Written to `.temp/tasks/<task_name>/verify-report.md`.

```markdown
# Verification Report: <task-name>

**Date:** <date>
**Mode:** standard | deep
**Task-Verificator result:** PASS | PARTIAL | FAIL

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

---

### localization-report

Written to `.temp/tasks/<task_name>/localization.md`.

```markdown
# Localization Report: <task-name>

**Date:** <date>
**Analyzed:** <number> files

## Must Modify
| File | Phase(s) | Reason |
|------|----------|--------|
| src/auth/login.ts | 1, 2 | Core authentication logic |
| src/api/users.ts | 2 | Add new endpoints |

## Might Modify
| File | Risk | Reason |
|------|------|--------|
| src/utils/validation.ts | MEDIUM | Used by auth module |
| src/config/constants.ts | LOW | May need new constants |

## Protected
| File | Reason |
|------|--------|
| package-lock.json | Lock file |
| node_modules/* | Third-party |

## Dependency Graph
```
src/auth/login.ts
├── src/utils/validation.ts (might modify)
├── src/config/constants.ts (might modify)
└── src/api/users.ts (must modify)
```

## Conflict Analysis
| File | Phases | Handoff Required |
|------|--------|-----------------|
| src/auth/login.ts | 1, 2 | YES - sequential with handoff |

## Recommendations
- Phase 1 and 2 should run sequentially (shared files)
- Consider splitting src/auth/login.ts changes to avoid conflicts
```

---

### phase-review

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

---

### plan-verification-report

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

---

### handoff-yaml

Written to `.temp/tasks/<task_name>/handoffs/phase-N-to-N+1.yml`.

```yaml
# Handoff: Phase N → Phase N+1
generated_at: <ISO timestamp>
from_phase: N
to_phase: N+1

files_modified:
  - path: path/to/file1.ts
    summary: "Brief description of what changed"
  - path: path/to/file2.ts
    summary: "Brief description of what changed"

constraints_discovered:
  - "New constraint discovered during implementation"
  - "Another constraint that next phase should know about"

warnings_for_next_phase:
  - "Important note about shared state"
  - "Potential conflict area to watch"

quality_status:
  lint: PASS | SKIPPED (final mode) | SKIPPED (none mode)
  type_check: PASS | SKIPPED (final mode) | SKIPPED (none mode)
  tests: PASS | SKIPPED (final mode) | SKIPPED (none mode)
  notes: "All quality checks passed after 2 iterations" | "Skipped per verification_mode=final" | "Skipped per verification_mode=none"

api_changes:
  - file: src/api/users.ts
    added: ["getUserById"]
    modified: ["updateUser"]
    removed: []
```

---

## Documentation Reports

### documentation-discovery

Screen output from docs-initializer Phase 1.

```markdown
# Documentation Discovery

## Existing Documentation
[List found files with brief description, or "None found"]

## Project Type
[Detected language/framework]

## Key Components
[Directories/modules identified]

## Current State
[Assessment of documentation coverage]
```

---

### documentation-initialized

Screen output from docs-initializer Phase 4.

```markdown
# Documentation Initialized

## Created Files
- README.md (project overview + feature index)
- ./docs/installation.md
- ./docs/configuration.md
- [other files]

## README Structure
- Overview
- Quick Start
- Features (with links to ./docs/)
- Architecture
- Documentation links

## Next Steps
1. Fill in [TODO] placeholders
2. Add project-specific details
3. Run `/project-docs scan` to find undocumented features
```

---

### research-results-found

Screen output from docs-researcher when results are found.

```markdown
# Research Results: "<query>"

## Summary
[Direct answer synthesized from found information ONLY - no assumptions]

## Sources

### Documentation
| File | Line | Excerpt |
|------|------|---------|
| README.md | 45 | "To configure authentication..." |
| ./docs/auth.md | 12-18 | "Authentication supports OAuth2..." |

### Codebase (if applicable)
| File | Line | Context |
|------|------|---------|
| src/auth.ts | 23 | export function authenticate() |

## Related Topics
[Links to related documentation sections if found]
```

---

### research-results-not-found

Screen output from docs-researcher when no results found.

```markdown
# Research Results: "<query>"

**Result:** NO RESULTS for "<query>"

## Locations Searched
- README.md
- ./docs/*.md (X files)
- Source files (if scope allowed)
- Configuration files (if scope allowed)

## Suggestions
1. Try different search terms: [list 2-3 alternatives]
2. The topic may not be documented yet
3. Run `/project-docs scan` to identify documentation gaps
4. Run `/project-docs add <topic>` to create this documentation
```

---

### duplicate-detected

Screen output from docs-manager when a potential duplicate is found.

```markdown
# Potential Duplicate Detected

## Existing Documentation
**File:** ./docs/authentication.md
**Section:** "OAuth 2.0 Flow"
**Size:** 45 lines

## Proposed Addition
**Topic:** OAuth authentication
**Key terms:** OAuth, authentication, token, login

## Similarity Analysis
- Title similarity: 85%
- Term overlap: 4/5 terms found in existing doc
- Scope: Same (both cover OAuth)

**Options:**
1. **Merge** - Add new content to existing ./docs/authentication.md
2. **Create separate** - Create ./docs/oauth.md with clear distinction
3. **Cancel** - Don't create duplicate

Which would you like? [merge/separate/cancel]
```

---

### documentation-added

Screen output from docs-manager after adding documentation.

```markdown
# Documentation Added

**File:** ./docs/<topic>.md
**Linked from:** README.md > Features section

## Content Summary
[Brief summary of what was added]

## Structure
- Overview
- Usage examples
- Configuration
- Related features
```

---

### found-documentation

Screen output from docs-manager when finding docs to change.

```markdown
# Found Documentation

| # | File | Section | Preview |
|---|------|---------|---------|
| 1 | ./docs/api.md | Endpoints | "GET /users - Returns user list..." |
| 2 | README.md | API | "See api.md for endpoint details..." |

Which would you like to change? [1/2/all]
```

---

### documentation-changed

Screen output from docs-manager after changing documentation.

```markdown
# Documentation Changed

**File:** ./docs/api.md
**Section:** Endpoints

## Before
[Old content excerpt]

## After
[New content excerpt]

## Cross-references Updated
- README.md link verified
```

---

### documentation-to-delete

Screen output from docs-manager before deleting documentation.

```markdown
# Documentation to Delete

**File:** ./docs/legacy-api.md
**Size:** 45 lines
**Linked from:** README.md (line 23)

## Preview
[First 10-15 lines of content]

## Impact
- README.md: 1 link will be removed
- No other files reference this document

**Confirm deletion?** [yes/no]
```

---

### documentation-deleted

Screen output from docs-manager after deleting documentation.

```markdown
# Documentation Deleted

**File:** ./docs/legacy-api.md
**References cleaned:** README.md (1 link removed)
**Features table updated:** Removed legacy-api entry
```

---

### task-based-doc-update

Screen output from docs-manager when in task context.

```markdown
# Task-Based Documentation Update

## Implementation Summary
[From PRD/plan analysis]

## Related Existing Documentation
- ./docs/authentication.md (covers basic auth)
- README.md features (missing new endpoints)

## Suggested Updates
1. Add "OAuth 2.0" section to ./docs/authentication.md
2. Add 3 new endpoints to ./docs/api-endpoints.md
3. Update README.md features table

Apply which updates? [all/selective/none]
```
