# /task-plan

Create a detailed implementation plan. NO code is implemented at this stage.

## Steps

1. Read `.temp/tasks/state.yml`.
2. Read `prd.md` and `context.md` (if exists).
3. Scan the repository for coding patterns, file structure, naming conventions.
4. Read `CLAUDE.md` for project-specific guidelines.
5. Analyze complexity, then present TWO questions simultaneously:

   > **Plan Configuration**
   >
   > I've analyzed the task. Here's my assessment:
   >
   > **Complexity signals:**
   > - [e.g., "Touches 8+ files across 3 layers — high integration surface"]
   > - [e.g., "Mostly CRUD scaffolding — mechanical and low-risk"]
   >
   > **Phase split:**
   > - **A) Single phase** — All TODOs in one `plan-phase-1.md` file. Best for small, focused tasks.
   > - **B) Split into phases** — Separate `plan-phase-N.md` files per phase with dependency tracking. Best for larger tasks or when phases can run in parallel.
   >
   > My recommendation: [A or B, with 1-2 sentences explaining why]
   >
   > **Verification timing:**
   > - **1) After each phase** — Each phase executor runs quality checks before marking complete (catches issues early)
   > - **2) After all phases** — Adds a Final Verification phase with all quality checks at the end (faster, issues may compound)
   > - **3) None** — No quality checks during execution. Useful for config-only tasks or when you plan to verify manually later.
   >
   > Please answer both: Phase split (A or B) and Verification (1, 2, or 3).

6. Wait for the user's answers.
7. Ask:
   > "Any notes before I write the plan? (e.g., TDD approach, specific patterns to follow, phases to prioritize)"
   Wait for response (user can say "none" to skip).
8. Generate the plan (see Plan Format Spec below).
   - Always generate an index `plan.md` plus individual `plan-phase-N.md` files.
   - For "single phase" (A): generate exactly one `plan-phase-1.md` with all TODOs.
   - For "split into phases" (B): generate multiple phase files with dependency graph.
   - For verification "none": no Quality Checks section in phase files, no Final Verification phase.
   - For verification "after each phase": include Quality Checks section in each phase file.
   - For verification "after all phases": no Quality Checks in phase files, generate `plan-phase-final.md`.
9. Write to `state.yml`: `phase_files` list and `verification_mode: per_phase | final | none`.
   Do NOT write `plan_format` (always multi-file, redundant).
10. Update `state.yml` status to `planned`.
11. **Auto-verify plan** — spawn the `plan-verificator` agent in quick mode:
    - Pass: `task_name`, `plan_path` (to `plan.md`), `prd_path` (to `prd.md`), `mode: "quick"`
    - Wait for the agent to produce `plan-verify-report.md`.
    - If result is `PASS`: report success and continue to step 12.
    - If result is `PARTIAL` or `FAIL`: read the Issues Found table. Attempt automatic fixes (max 3 iterations):
      - For each issue, apply the Recommendation to the affected `plan-phase-N.md` or `plan.md`.
      - Re-spawn `plan-verificator` in quick mode to re-check.
      - If any iteration produces `PASS`: stop and continue.
      - If after 3 iterations issues remain: report them and ask whether to proceed or fix manually.
    - Report the verification result to the user:
      > **Plan Verification: PASS** — All checks passed. Plan is ready for execution.
      or
      > **Plan Verification: PARTIAL** — <N> issues auto-fixed, <M> remaining. See `plan-verify-report.md`.
      or
      > **Plan Verification: FAIL** — <N> issues could not be auto-fixed. Review `plan-verify-report.md`.
12. **Optional: Run localization analysis**
    > "Would you like me to analyze file impact before execution? This helps identify potential conflicts. [yes/no]"
    If yes, spawn the localization-agent to generate `localization.md`.
13. Suggest `/task-execute` next.

---

## Plan Format Spec

Plans always use a multi-file structure: an index `plan.md` plus individual `plan-phase-N.md` files.

### Verification Modes

- `per_phase`: Quality Checks section appears in each phase file. Task-executors run checks after completing their phase.
- `final`: No quality checks in phase files. A **Final Verification phase** (`plan-phase-final.md`) is generated as the last phase containing all quality check TODOs.
- `none`: No quality checks in phase files and no Final Verification phase. No automated quality checks during execution.

### When to use single phase vs. split

- **Single phase**: Small tasks (3-10 TODOs), no natural phase boundaries, files are closely coupled
- **Split into phases**: Larger tasks, natural boundaries exist (e.g., "models first, then API, then UI"), parallel execution opportunity

### Main `plan.md` (index — no phase details)

```markdown
# Implementation Plan: <task-name>

**Status:** Ready
**Created:** <date>
**Based on PRD:** <prd path>
**Verification:** per_phase | final | none

## Overall Progress
- [ ] Phase 1: <name>
- [ ] Phase 2: <name>
- [ ] Phase N: <name>
- [ ] Phase Final: Verification *(only when verification_mode=final)*

## Dependency Graph
Phase 1: (none)
Phase 2: Phase 1
Phase 3: Phase 1, Phase 2
Phase Final: All previous phases *(only when verification_mode=final)*

## Phase Files
- `plan-phase-1.md` — <one-line description>
- `plan-phase-2.md` — <one-line description>
- `plan-phase-N.md` — <one-line description>
- `plan-phase-final.md` — Final verification with quality checks *(only when verification_mode=final)*
```

### Per-phase file (`plan-phase-N.md` in the task directory)

```markdown
# Phase N: <Phase Name>

**Goal:** <1-2 sentence description of what this phase achieves>
**Dependencies:** Phase 1, Phase 2 | None
**Files:**
- `path/to/file.ext` (create | modify | delete)
- `path/to/another-file.ext` (create | modify | delete)

## TODO
- [ ] <verb-first actionable item, e.g., "Create the UserService class with CRUD methods">
- [ ] <verb-first actionable item, e.g., "Add input validation for email and password fields">
- [ ] <verb-first actionable item, e.g., "Write unit tests for UserService.create and UserService.update">

## Quality Checks
<!-- Include this section ONLY if verification_mode is "per_phase" -->
- [ ] <quality command, e.g., npm run lint>
- [ ] <quality command, e.g., npm test>
```

### Final Verification Phase File (`plan-phase-final.md`)

Generated ONLY when `verification_mode=final`:

```markdown
# Phase Final: Verification

**Goal:** Run all quality checks and verify implementation matches the plan
**Dependencies:** All previous phases
**Files:**
- *(none — this phase runs checks only)*

## TODO
- [ ] Run static type checks (discover from project: `npm run type-check`, `tsc --noEmit`, etc.)
- [ ] Run linting (discover from project: `npm run lint`, `eslint .`, etc.)
- [ ] Run tests (discover from project: `npm test`, `pytest`, etc.)
- [ ] Verify all TODO items in all phase files are marked complete
- [ ] Verify implementation matches plan specifications (read key files, compare to plan)
```

### Rules

- TODO items must be **single-line, verb-first** — no nested sub-fields.
- Each TODO is one logical unit of work. Typically 3–10 items per phase.
- Generate one `plan-phase-N.md` per phase in the task directory alongside `plan.md`.
- Write a `phase_files` list to `state.yml` so agents can discover phase files without globbing.
- Write `verification_mode` to `state.yml` so task-executors know whether to run checks per-phase.
- The main `plan.md` contains **no phase details** — only progress tracking, dependency graph, and file list.
- Quality Checks section in phase files is only included when `verification_mode: per_phase`.
- When `verification_mode=final`: generate `plan-phase-final.md` as the last phase.
- When `verification_mode=none`: no Quality Checks section in phase files, no Final Verification phase.

---

## Key Rules

- Every task must specify exact file path and action (create / modify / delete).
- Quality checks must list commands actually discovered from the project.
- If TDD was requested: each phase lists failing test signatures/stubs first, then implementation tasks.
- Always write `phase_files` and `verification_mode` to `state.yml`.
- Generate separate `plan-phase-N.md` files. The main `plan.md` is an index only.
- Include Quality Checks section in phase files only when `verification_mode: per_phase`.
- When `verification_mode=final`, also generate `plan-phase-final.md` with all quality check TODOs.
- When `verification_mode=none`, omit quality checks entirely from phase files and do not generate a final verification phase.
