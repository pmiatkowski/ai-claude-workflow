# /task-run

Generic task-scoped command. Loads full task context, then executes whatever the user asks.

Usage: `/task-run <anything>`

Examples:
- `/task-run update the README to reflect the new auth flow`
- `/task-run refactor the token utilities to use a class instead of standalone functions`
- `/task-run check if plan phase 2 is still consistent with the PRD after the last clarification`
- `/task-run add JSDoc to all exported functions in src/lib/jwt.ts`
- `/task-run the build is failing with TS2345 — investigate and fix`

## Steps

1. **Load task context:**
   a. Read `.temp/tasks/state.yml` — extract `active_task`, `task_path`, `status`, `phase_files`, `verification_mode`, and `constraints`.
   b. Read `prd.md` (at `task_path/prd.md`) for requirements and constraints.
   c. Read `plan.md` (at `task_path/plan.md`) for progress and implementation approach.
   d. If `phase_files` is populated, read each `plan-phase-N.md` listed there.
   e. If `context.md` exists, read it for additional context.
   f. If `active_task` is `none` or missing: report "No active task" and stop.
2. Read `$ARGUMENTS` — this is the full instruction. Execute it exactly as described.
3. Use any tools needed: read files, write files, run commands, search the codebase — whatever the instruction requires.
4. After completing, briefly summarize what was done. If any files were modified that relate to the plan or PRD, offer to update them to stay consistent.
5. If the work added or changed functionality not in the original PRD/plan:
   - Update PRD Section 13 (Ad-Hoc Changes) with a row:
     - Date: today's date
     - Type: feature|change|fix|refactor
     - Description: brief summary
     - Files Affected: list of files
     - Rationale: why this was needed

## Notes

- No assumed intent — do exactly what the instruction says, nothing more.
- Task context (PRD, plan) is loaded so actions stay coherent with the overall task, but it does not constrain what you can do.
- If `$ARGUMENTS` is empty, ask: "What would you like to do?"
