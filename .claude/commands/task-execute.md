# /task-execute

Execute the implementation plan by spawning task-executor agents.

## Steps

1. **Load task context:**
   a. Read `.temp/tasks/state.yml` — extract `active_task`, `task_path`, `status`, `phase_files`, `verification_mode`, and `constraints`.
   b. Read `prd.md` (at `task_path/prd.md`) for requirements and constraints.
   c. Read `plan.md` (at `task_path/plan.md`) for progress and implementation approach.
   d. If `phase_files` is populated, read each `plan-phase-N.md` listed there.
   e. If `context.md` exists, read it for additional context.
   f. If `active_task` is `none` or missing: report "No active task" and stop.
2. **Pre-Execution Verification Gate:**
   Spawn the plan-verifier agent (see `.claude/agents/plan-verifier.md`) in **quick** mode with `task_name`, `plan_path`, and `prd_path`.
   - **PASS** → proceed to step 3.
   - **PARTIAL** → warn the user with the issues found, then proceed to step 3.
   - **FAIL** → BLOCK execution and suggest `/task-verify plan deep`.
3. Ask the user:

   > **What would you like to execute?**
   > - `all` — all phases
   > - `phase <N>` — a specific phase
   > - `phases <N,M>` — specific phases

4. **Determine orchestration strategy** (see Orchestration Strategy below).
5. Spawn task-executor agents using the Task tool based on the strategy.
5.5. **Validate executor exit contracts (MANDATORY):**
   After each task-executor completes:

   a. **Check for exit summary line.** Parse the agent's last response line for `EXIT: Phase N <status>`.
      If not found: report warning, fall back to file-based validation.

   b. **Read exit file.** Read `.temp/tasks/<task_name>/exit-phase-<N>.yml`.
      If file missing: report warning, fall back to TODO count validation.
      Parse YAML. Validate all required fields present.

   c. **Check status.** If `status: PARTIAL` or `status: FAILED`:
      - Report error, ask user: retry / skip / stop.

   d. **Check handoff.** If `handoff_written: true`, verify file exists on disk.

   e. **Check TODO consistency.** Compare `todos_done` against actual `- [x]` count in `plan-phase-N.md`.

5.6. **Update plan.md Overall Progress:**
   For each phase where validation passed (all TODOs marked `- [x]`), update the corresponding line in `plan.md` Overall Progress from `- [ ]` to `- [x]`.
6. After all task-executors complete and pass validation, automatically spawn the **task-verifier agent** (unless `verification_mode=none`).
7. Run auto-remediation loop (see Auto-Remediation Loop section below).
8. Report final status to user.

## Orchestration Strategy

| Phase Relationship | Files | Strategy | Notes |
|-------------------|-------|----------|-------|
| Independent | Different | **Parallel** | Safe to run simultaneously |
| Sequential Dep | Any | **Sequential** | One after another with handoffs |
| Shared Files | Overlapping | **Sequential + handoff** | Must coordinate via handoffs |
| Complex + Risky | Core files | **Builder → Reviewer** | Task-Executor then reviewer agent |

**How to determine:**

1. Read each phase's `**Dependencies:**` header in each `plan-phase-N.md`
2. Check if phases modify the same files (read file paths in each phase)
3. Apply the strategy from the table above
4. For shared-file phases, always use sequential with handoffs

## task-executor Agent Instructions

Spawn task-executor with: `task_name`, `phase_number`, `plan_path`, `phase_file_path`, `prd_path`, `handoff_path` (if sequential). The agent file (`.claude/agents/task-executor.md`) contains full instructions.

**Note:** When `verification_mode=final`, the last phase will be "Phase Final: Verification". This phase has no files to modify — it only runs quality checks. The executor should handle this gracefully by skipping file operations and running only the TODO checks (type-check, lint, test, verify against plan).

When `verification_mode=none`, no quality checks run during execution.

## Parallel vs Sequential

- **Parallel**: Use multiple simultaneous Task tool calls. Only safe when phases have no dependencies and touch different files.
- **Sequential**: Await each Task tool call before starting the next. Pass handoff path from previous task-executor to next.

## task-verifier

After all task-executors finish, spawn the Task-Verifier agent (see `.claude/agents/task-verifier.md`).
Pass it: task name, plan.md path, list of phase summaries, and the `phase_files` list.

- When `verification_mode=per_phase`: The verifier re-runs quality checks to confirm they still pass, plus completeness and PRD compliance.
- When `verification_mode=final`: The verifier confirms the Final Verification phase passed and checks completeness and PRD compliance.
- When `verification_mode=none`: Skip spawning the verifier entirely. Report completion status to the user based on executor results.

## Builder-Reviewer Pattern (for complex phases)

For high-risk phases: spawn task-executor, then phase-reviewer. If rejected, re-spawn executor with feedback (max 2 retries).

## Auto-Remediation Loop

After the task-verifier completes:

1. Read `verify-report.md` result (`PASS | PARTIAL | FAIL`).
2. If **PASS** → done.
3. If **FAIL/PARTIAL** → ask user to auto-fix.
4. If yes: spawn executors for affected phases with the Issues Found table from verify-report as remediation context (fix ONLY those issues). Re-verify. Max 2 iterations. Report remaining issues if still failing.
