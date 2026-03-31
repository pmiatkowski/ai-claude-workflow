# /task-create

Create a new task. Usage: `/task-create <task-name> <brief description> [--quick]`

Add `--quick` to skip clarification and planning questions. Generates a minimal PRD and single-phase plan with `verification_mode: none`, then suggests `/task-execute` immediately. Best for small, well-defined tasks (fixes, renames, small additions).

## Steps

1. Parse `$ARGUMENTS`:
   a. Detect `--quick` anywhere in the arguments string. If present, set QUICK_MODE=true and remove `--quick` from the string.
   b. From the remaining string: first word is `<task-name>` (slugified, lowercase, hyphens), remainder is the description.
   c. If QUICK_MODE is false, check the description against the Quick-Suggest Heuristic below. If it matches, mention to the user: "This looks like a quick task. Consider using `--quick` for a faster flow." Then proceed with the full flow unchanged.
2. Create directory `.temp/tasks/<task-name>/`.
3. Analyze the user's description carefully.
4. **Branch on QUICK_MODE:**
   - If false → follow the **Full Flow** below.
   - If true → follow the **Quick Flow** below.

---

## Full Flow

Generate `.temp/tasks/<task-name>/prd.md` using the Full PRD Template below.

Write `.temp/tasks/state.yml` using the Full state.yml Template below.

Confirm to the user with a summary and suggest running `/task-clarify` next.

### Full PRD Template

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

### Full state.yml Template

```yaml
active_task: <task-name>
created_at: <ISO date>
updated_at: <ISO date>
status: draft
task_path: .temp/tasks/<task-name>
prd: .temp/tasks/<task-name>/prd.md
plan: .temp/tasks/<task-name>/plan.md
context: .temp/tasks/<task-name>/context.md
constraints:
  invariants: []  # Constraints that must always hold
  decisions: []   # Constraints derived from decisions made in clarification
  discovered: []  # Constraints discovered during phase implementation (propagated from handoffs)
```

---

## Quick Flow

### Step A: Generate Quick PRD

Generate `.temp/tasks/<task-name>/prd.md` using the Quick PRD Template below.

### Step B: Generate Plan Inline

Immediately generate the implementation plan without asking questions:

1. Scan the repository for coding patterns, file structure, and naming conventions.
2. Read `CLAUDE.md` for project-specific guidelines.
3. Generate a **single-phase plan** with these hardcoded defaults:
   - Phase split: single phase — one `plan-phase-1.md` with all TODOs
   - Verification mode: `none` — no Quality Checks sections, no Final Verification phase
4. Write `plan.md` (index) to `.temp/tasks/<task-name>/plan.md`:
   ```markdown
   # Implementation Plan: <task-name>

   **Status:** Ready
   **Created:** <date>
   **Based on PRD:** .temp/tasks/<task-name>/prd.md
   **Verification:** none

   ## Overall Progress
   - [ ] Phase 1: <name>

   ## Dependency Graph
   Phase 1: (none)

   ## Phase Files
   - `plan-phase-1.md` — <one-line description>
   ```
5. Write `plan-phase-1.md` to `.temp/tasks/<task-name>/plan-phase-1.md`:
   ```markdown
   # Phase 1: <Phase Name>

   **Goal:** <1-2 sentence description>
   **Dependencies:** None
   **Files:**
   - `path/to/file.ext` (create | modify | delete)

   ## TODO
   - [ ] <verb-first actionable item>
   ```
   - No Quality Checks section (verification_mode is none).
   - Keep TODOs verb-first, single-line. Typically 3-10 items.

### Step C: Write state.yml

```yaml
active_task: <task-name>
created_at: <ISO date>
updated_at: <ISO date>
status: planned
task_path: .temp/tasks/<task-name>
prd: .temp/tasks/<task-name>/prd.md
plan: .temp/tasks/<task-name>/plan.md
context: .temp/tasks/<task-name>/context.md
phase_files:
  - .temp/tasks/<task-name>/plan-phase-1.md
verification_mode: none
constraints:
  invariants: []
  decisions: []
  discovered: []
```

### Step D: Confirm

Report to the user:

> **Quick task created and planned.**
>
> PRD: `.temp/tasks/<task-name>/prd.md`
> Plan: `.temp/tasks/<task-name>/plan.md` (1 phase)
> Verification: none
>
> Run `/task-execute` to start implementation.

### Quick PRD Template

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

---

## Quick-Suggest Heuristic

When QUICK_MODE is false, check the description against these signals. If **2 or more** apply, suggest `--quick` to the user (but proceed with the full flow unless they re-run with the flag):

**Signals:**
- Description is a single sentence
- Contains small-task action verbs: fix, typo, rename, update, bump, remove, add X to Y, refactor, adjust, tweak, revert, cleanup, move
- Mentions a specific file path or function name
- Under 15 words
- Contains scope-limiting words: just, only, simply, quick, small

**Do NOT suggest --quick if:**
- Multiple distinct requirements connected by "and" or "also"
- Mentions multiple files or components
- Involves architecture, design, or multiple stakeholders
