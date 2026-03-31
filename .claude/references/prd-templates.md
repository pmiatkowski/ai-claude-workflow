# PRD Templates Reference

Centralized templates for PRD generation. Commands and agents read this file when creating PRDs.

---

## Full PRD

Used by `/task-create` (full flow). Written to `.temp/tasks/<task-name>/prd.md`.

```markdown
# PRD: <task-name>

**Status:** Draft
**Created:** <today's date>
**Last Updated:** <today's date>

## 1. Overview
[Synthesize user's description into a clear problem statement]

## 2. Goals
[Primary and secondary goals inferred from the brief]

## 3. Functional Requirements
### 3.1 Core Features
[Concrete requirements inferred from the brief]
### 3.2 Edge Cases & Error Handling
[Any edge cases that are implied or obvious]

## 4. Non-Functional Requirements
[Performance, security, accessibility — infer what's relevant]

## 5. Technical Considerations
[Known patterns, dependencies, constraints — leave blank if none known yet]

## 6. Out of Scope
[Things explicitly or implicitly NOT included]

## 7. Gaps & Ambiguities
[Things the user did NOT mention but that will need decisions. Be thorough here — this is critical for the clarification step.]

## 8. Open Questions
[Questions that must be answered before implementation can start]

## 9. Decisions
| ID | Question | Options | Chosen | Rationale | Date |
|----|----------|---------|--------|-----------|------|
[Populated by /task-clarify — records all decisions made during clarification]

## 10. Constraints
### Invariants (Must Never Change)
- [Constraints that must always hold — from project requirements or architecture]

### Derived from Decisions
- From D[n]: [Constraint that follows from a decision]

## 11. Additional Context
[Reserved — populated by /task-add-context]

## 12. Ad-Hoc Changes
[Populated during implementation — tracks changes made outside the original plan]
| Date | Type | Description | Files Affected | Rationale |
|------|------|-------------|----------------|-----------|
```

---

## Quick PRD

Used by `/task-create` (quick flow). Written to `.temp/tasks/<task-name>/prd.md`.

```markdown
# PRD: <task-name>

**Status:** Ready
**Created:** <today's date>
**Last Updated:** <today's date>
**Mode:** Quick

## 1. Overview
[Synthesize user's description into a clear problem statement — 2-3 sentences max]

## 2. Functional Requirements
[Numbered list of concrete requirements inferred from the brief. Keep flat — no sub-sections unless directly implied by the description]

## 3. Out of Scope
[Things explicitly or implicitly NOT included — keep brief]

## 4. Ad-Hoc Changes
| Date | Type | Description | Files Affected | Rationale |
|------|------|-------------|----------------|-----------|
```
