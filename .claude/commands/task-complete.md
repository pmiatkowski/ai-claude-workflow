# /task-complete

Close out a finished task. Usage: `/task-complete [--archive]`

## Purpose

Marks the active task as done, clears the active task pointer, and optionally archives task artifacts. This is the final step after execution and verification succeed.

## Steps

1. Read `.temp/tasks/state.yml`.
2. **Validate state:**
   - If `active_task` is `none` or missing → report "No active task" and stop.
   - If `status` is already `done` → report "Task already completed" and stop.
3. **Completeness check:**
   - Read `plan.md` Overall Progress section.
   - Count phases marked `- [x]` vs `- [ ]`.
   - If any phase is incomplete (`- [ ]`):

     > **Warning:** N of M phases are incomplete. Mark task as done anyway? [yes/no]

     If **no** → stop. Suggest `/task-execute` or `/task-verify` first.
4. **Update `state.yml`:**
   ```yaml
   active_task: none
   status: done
   completed_at: <ISO timestamp>
   updated_at: <ISO timestamp>
   ```
4.5. **Write to task registry:**
   a. Read or create `.temp/tasks/registry.yml`.
   b. Extract from the task's PRD:
      - Key decisions from Section 9 (Decision Matrix) — take the `Chosen` column value for each row.
      - Exported constraints from Section 10 — take all invariants and decision-derived constraints.
   c. Extract from handoff files: full list of `files_modified`.
   d. Append a new entry to `tasks` array:
      ```yaml
      - name: <task-name>
        status: done
        created_at: <from state.yml>
        completed_at: <ISO timestamp>
        prd_path: <path to prd.md, updated if archived>
        depends_on: <from state.yml if set, otherwise null>
        key_decisions:
          - "<D1 summary>"
          - "<D2 summary>"
        constraints_exported:
          - "<constraint text>"
        files_modified:
          - <file paths from handoffs>
      ```
5. **Determine archiving:**
   - If `--archive` flag was passed → archive without asking.
   - Otherwise ask:

     > Archive task artifacts to `.temp/tasks/archive/<task-name>/`? [yes/no]

6. **If archiving:**
   - Create `.temp/tasks/archive/` directory if it doesn't exist.
   - Move `.temp/tasks/<task-name>/` to `.temp/tasks/archive/<task-name>/`.
   - Remove `task_path`, `prd`, `plan`, `context`, `phase_files`, `verification_mode` fields from `state.yml` (they now point to a moved location).
7. **Print summary:**

   Summary: Header "Task Complete: <task-name>". Table with rows: Status, Phases (N/N completed), Duration (created_at → completed_at), Archived (yes/no). Then "Files modified:" list with each file path and source phase.

   For the files list, read each `plan-phase-N.md` and extract file paths from the `**Files:**` section. If handoff files exist in `.temp/tasks/<task-name>/handoffs/`, use those for the most accurate list.

8. **Suggest next steps:** `/task-create` to start a new task.

## Archive Behavior

Archived tasks are moved to `.temp/tasks/archive/<task-name>/` and retain all their artifacts (PRD, plan, phases, handoffs, reviews, checkpoints). They can be reviewed later but are no longer active.

If you need to reference an archived task, read its files directly from the archive directory. There is no built-in restore — create a new task if you need to redo the work.
