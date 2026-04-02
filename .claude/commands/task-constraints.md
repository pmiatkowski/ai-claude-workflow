# /task-constraints

Manage constraints for the active task. Usage: `/task-constraints <add|list|check|remove> [args]`

## Purpose

Constraints are rules that must never be violated during implementation. They come from two sources:
1. **Invariants** - Fixed rules from project requirements
2. **Decision-derived** - Constraints that follow from decisions made in clarification

## Commands

### `add invariant "<constraint>"`

Add a new invariant constraint.

```bash
/task-constraints add invariant "All API calls must be authenticated"
```

### `add decision <D-id> "<constraint>"`

Add a constraint derived from a specific decision.

```bash
/task-constraints add decision D1 "Must use OAuth2, not custom auth"
```

### `list`

List all constraints for the active task.

```bash
/task-constraints list
```

Output: Header with task name. Two sections: "Invariants" table (ID, Constraint, Added) and "Decision-Derived" table (ID, From decision, Constraint, Added).

### `check`

Verify that current implementation respects all constraints.

```bash
/task-constraints check
```

This reads the implemented files and checks for constraint violations.

### `remove <constraint-id>`

Remove a constraint by ID (use with caution).

```bash
/task-constraints remove I1
```

## Steps

1. Read `.temp/tasks/state.yml` to identify active task.
2. Parse `$ARGUMENTS` to determine command.
3. Execute the appropriate action.

### Add Invariant

1. Read current `.temp/tasks/state.yml`
2. Add to `constraints.invariants` array:
   ```yaml
   constraints:
     invariants:
       - id: I<n>
         constraint: "<constraint text>"
         added_at: <ISO timestamp>
   ```
3. Also update PRD Section 10
4. Confirm to user

### Add Decision Constraint

1. Read current `.temp/tasks/state.yml`
2. Verify decision D-id exists in PRD Section 9
3. Add to `constraints.decisions` array:
   ```yaml
   constraints:
     decisions:
       - id: D<n>-<m>
         from_decision: D<n>
         constraint: "<constraint text>"
         added_at: <ISO timestamp>
   ```
4. Also update PRD Section 10
5. Confirm to user

### List Constraints

1. Read `.temp/tasks/state.yml` constraints section
2. Read PRD Section 10
3. Display formatted output

### Check Constraints

**Load constraints from:**
1. `.temp/tasks/state.yml` -> `constraints.invariants`: rules that must NEVER be violated.
2. `.temp/tasks/state.yml` -> `constraints.decisions`: constraints derived from PRD decisions.
3. `.temp/tasks/state.yml` -> `constraints.discovered`: constraints found during implementation.
4. `prd.md` Section 10: human-readable constraint descriptions.

**For each constraint:**
1. Read the relevant implementation files.
2. Verify the code respects the constraint.
3. Classify violations: CRITICAL (invariant violated -- BLOCK), HIGH (decision violated -- BLOCK), MEDIUM (partially met -- WARN), LOW (minor -- INFO).
4. CRITICAL/HIGH: STOP and report. MEDIUM/LOW: note for report, continue.

Output the report using the format from `.claude/references/reports/constraint-compliance.md`.

### Remove Constraint

1. Verify constraint exists
2. Ask for confirmation (constraints should rarely be removed)
3. Remove from `.temp/tasks/state.yml` and PRD Section 10
4. Confirm to user

## Integration

Constraints are automatically:
- Checked by task-executor before implementation
- Verified by task-verifier after implementation
- Injected into context by inject-task-context.sh hook
- Updated when decisions are made in /task-clarify
