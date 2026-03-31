# Shared Patterns Reference

Centralized protocols used across commands and agents. Reference these by section anchor (e.g., `.claude/references/shared-patterns.md#task-context-loading`).

---

## Task Context Loading

Load the full task context from state and task files.

1. Read `.temp/tasks/state.yml` — extract `active_task`, `task_path`, `status`, `phase_files`, `verification_mode`, and `constraints`.
2. Read `prd.md` (at `task_path/prd.md`) for requirements, intent, and constraints.
3. Read `plan.md` (at `task_path/plan.md`) for progress and implementation approach.
4. If `phase_files` is populated, read each `plan-phase-N.md` listed there for phase details.
5. If `context.md` exists, read it for additional context gathered during the task.

**Validation:**
- If `active_task` is `none` or missing: report "No active task" and stop.
- If any referenced file does not exist: note it but continue (files are created progressively).

---

## Quality Command Discovery

Discover and run quality commands from the project. Use when `verification_mode` is `per_phase` or when running quality checks.

**Discovery sources (check in order):**

1. `package.json` → `scripts`: look for `lint`, `type-check`, `test`, `build`.
2. `Makefile` targets: look for lint, test, type-check, build targets.
3. `CLAUDE.md`: look for specified quality/lint/test commands.
4. Phase file's "Quality Checks" section (if present in `plan-phase-N.md`).

**Execution:**

- Run all discovered commands.
- If any command fails: report the failure with full output.
- When `verification_mode` is `final` or `none`: skip quality command execution entirely.

---

## Constraint Check Protocol

Verify that implementation respects all constraints defined for the task.

**Load constraints from three sources:**

1. `state.yml` → `constraints.invariants`: rules that must NEVER be violated.
2. `state.yml` → `constraints.decisions`: constraints derived from PRD decisions.
3. `state.yml` → `constraints.discovered`: constraints found during implementation (may be empty).
4. `prd.md` Section 10: human-readable constraint descriptions.

**For each constraint:**

1. Read the relevant implementation files.
2. Verify the code respects the constraint.
3. If a violation is found, classify by severity:

| Severity | When Used | Action |
|----------|-----------|--------|
| CRITICAL | Invariant violated | BLOCK — Must fix immediately, stop all work |
| HIGH | Decision constraint violated | BLOCK — Must fix before proceeding |
| MEDIUM | Constraint partially met | WARN — Should address |
| LOW | Minor concern | INFO — Consider addressing |

**On violation:**

- Report: severity, constraint ID, file, specific issue, required fix.
- CRITICAL/HIGH violations: STOP and report to user before proceeding.
- MEDIUM/LOW violations: note for the report, continue.

---

## Severity Levels

Standard severity classification used across verification domains.

**Common structure:**

| Level | Description | Action |
|-------|-------------|--------|
| CRITICAL | [domain-specific] | BLOCK — Fix immediately |
| HIGH | [domain-specific] | BLOCK — Fix before merge |
| MEDIUM | [domain-specific] | WARN — Fix in current sprint |
| LOW | [domain-specific] | INFO — Address when possible |

**Domain-specific descriptions:**

| Level | Quality | Security | Performance | Constraints |
|-------|---------|----------|-------------|-------------|
| CRITICAL | Blocks release | Active exploitation possible | System unusable | Invariant violated |
| HIGH | Significant quality issue | Significant vulnerability | Significant degradation | Decision constraint violated |
| MEDIUM | Quality concern | Moderate risk | Noticeable impact | Constraint partially met |
| LOW | Minor improvement | Minor issue | Minor optimization | Minor concern |
