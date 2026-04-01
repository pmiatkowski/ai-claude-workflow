# Documentation Report Templates

Templates for docs-initializer, docs-researcher, and docs-manager output.

---

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
