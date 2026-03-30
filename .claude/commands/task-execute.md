# /task-execute

Execute the implementation plan by spawning task-executor agents.

## Steps

1. Read `.temp/tasks/state.yml`.
2. Read `plan.md` and `state.yml` — identify all phases, their status, and `verification_mode`.
   `plan.md` is an index. Read each `plan-phase-N.md` listed in `phase_files` from `state.yml` to get phase details.
3. **Pre-Execution Verification Gate:**
   - Verify every PRD requirement maps to at least one task
   - Verify phase dependencies have no cycles
   - Verify quality commands are defined for each phase (when verification_mode is `per_phase`)
   - If any fail: BLOCK and suggest `/task-verify plan deep`
4. Ask the user:

   > **What would you like to execute?**
   > - `all` — all phases
   > - `phase <N>` — a specific phase
   > - `phases <N,M>` — specific phases

5. **Determine orchestration strategy** (see Orchestration Strategy below).
6. Spawn task-executor agents using the Task tool based on the strategy.
7. After all task-executors complete, automatically spawn the **task-verificator agent** (unless `verification_mode=none`).
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

Pass this to each Task invocation:

```
You are a Task-Executor agent for task: <task-name>, Phase <N>: <phase-name>.

Read your phase file at: <task_path>/plan-phase-<N>.md
Read the plan index at: <task_path>/plan.md (for overall context only)
Implement ONLY Phase <N>. Do not touch other phases.

Handoff from previous phase (if sequential): <handoff_path or "none">

After implementation:
1. Discover quality commands from the phase file's Quality Checks section plus project config.
2. Run self-refine loop (max 3 iterations).
3. Mark TODO items complete in plan-phase-<N>.md (change `- [ ]` to `- [x]`).
4. Mark Phase <N> complete in the main plan.md Overall Progress section.
5. Generate handoff file if next phase exists.

Do NOT implement anything outside Phase <N>.
```

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

For phases marked as "high risk" or touching core architecture:

1. Spawn task-executor agent for the phase
2. After completion, spawn phase-reviewer agent
3. Reviewer checks implementation against plan, PRD, and constraints
4. If reviewer rejects: spawn task-executor again with feedback
5. Repeat until approved or max retries (2) reached
