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
9. Write to `state.yml`: `phase_files` list, `verification_mode`, status `planned`.
10. **Auto-verify plan** — spawn the `plan-verificator` agent in quick mode:
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
11. **Optional: Run localization analysis**
    > "Would you like me to analyze file impact before execution? This helps identify potential conflicts. [yes/no]"
    If yes, spawn the localization-agent to generate `localization.md`.
12. Suggest `/task-execute` next.

---

## Plan Format Spec

Plans always use a multi-file structure: an index `plan.md` plus individual `plan-phase-N.md` files.

### When to use single phase vs. split

- **Single phase**: Small tasks (3-10 TODOs), no natural phase boundaries, files are closely coupled
- **Split into phases**: Larger tasks, natural boundaries exist (e.g., "models first, then API, then UI"), parallel execution opportunity

### Main `plan.md` (index — no phase details)

Write plan.md with: status, date, PRD path, verification mode. Overall Progress section (checkbox per phase). Dependency Graph. Phase Files list with one-line descriptions. Include Phase Final line only when verification_mode=final.

### Per-phase file (`plan-phase-N.md` in the task directory)

Each phase file contains: goal (1-2 sentences), dependencies, file list with action (create/modify/delete), TODO list (verb-first single-line items, 3-10 per phase). Include Quality Checks section ONLY when verification_mode=per_phase.

### Final Verification Phase File (`plan-phase-final.md`)

Generated ONLY when verification_mode=final. No files to modify. TODOs: run type-check, lint, test (discover commands from project), verify all TODOs marked complete, verify implementation matches plan.

### Rules

- Quality checks must list commands discovered from the project.
- If TDD requested: each phase lists failing test stubs first, then implementation tasks.
