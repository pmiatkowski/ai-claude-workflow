# /task-execute

Execute the implementation plan by spawning task-executor agents.

## Steps

1. Read `.temp/tasks/state.yml`.
2. Read `plan.md` and `state.yml` — identify all phases, their status, and `verification_mode`.
   `plan.md` is an index. Read each `plan-phase-N.md` listed in `phase_files` from `state.yml` to get phase details.
3. **Pre-Execution Verification Gate:**
   Spawn the plan-verificator agent (see `.claude/agents/plan-verificator.md`) in **quick** mode with `task_name`, `plan_path`, and `prd_path`.
   - **PASS** → proceed to step 4.
   - **PARTIAL** → warn the user with the issues found, then proceed to step 4.
   - **FAIL** → BLOCK execution and suggest `/task-verify plan deep`.
4. Ask the user:

   > **What would you like to execute?**
   > - `all` — all phases
   > - `phase <N>` — a specific phase
   > - `phases <N,M>` — specific phases

5. **Determine orchestration strategy** (see Orchestration Strategy below).
6. Spawn task-executor agents using the Task tool based on the strategy.
6.5. **Update plan.md Overall Progress:**
   After all task-executors complete, read each `plan-phase-N.md` to check if all TODOs are marked `- [x]`.
   For each phase where all TODOs passed, update the corresponding line in `plan.md` Overall Progress from `- [ ]` to `- [x]`.
   This centralizes progress updates and avoids parallel write conflicts.
7. After all task-executors complete, automatically spawn the **task-verificator agent** (unless `verification_mode=none`).
8. Run auto-remediation loop (see Auto-Remediation Loop section below).
9. Report final status to user.

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

## task-verificator

After all task-executors finish, spawn the Task-Verificator agent (see `.claude/agents/task-verificator.md`).
Pass it: task name, plan.md path, list of phase summaries, and the `phase_files` list.

- When `verification_mode=per_phase`: The verificator re-runs quality checks to confirm they still pass, plus completeness and PRD compliance.
- When `verification_mode=final`: The verificator confirms the Final Verification phase passed and checks completeness and PRD compliance.
- When `verification_mode=none`: Skip spawning the verificator entirely. Report completion status to the user based on executor results.

## Builder-Reviewer Pattern (for complex phases)

For high-risk phases: spawn task-executor, then phase-reviewer. If rejected, re-spawn executor with feedback (max 2 retries).

## Auto-Remediation Loop

After the task-verificator completes:

1. Read `verify-report.md` result (`PASS | PARTIAL | FAIL`).
2. If **PASS** → done.
3. If **FAIL/PARTIAL** → ask user to auto-fix.
4. If yes: spawn executors for affected phases with the Issues Found table from verify-report as remediation context (fix ONLY those issues). Re-verify. Max 2 iterations. Report remaining issues if still failing.
