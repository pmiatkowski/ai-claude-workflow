# /task-list

List all tasks (active, completed, archived). Usage: `/task-list [--all | --active | --done]`

## Steps

1. Read `.temp/tasks/state.yml` for the active task (if any).
2. Read `.temp/tasks/registry.yml` for completed tasks (if exists).
3. Parse `$ARGUMENTS`:
   - `--all` (default): show active + completed tasks.
   - `--active`: show only the active task.
   - `--done`: show only completed tasks.

4. Display formatted output:

```
# Task Registry

## Active

| Task | Status | Created | Path |
|------|--------|---------|------|
| <name> | <status> | <date> | <path> |

## Completed

| Task | Completed | Depends On | Key Decisions | Files Modified |
|------|-----------|------------|---------------|----------------|
| <name> | <date> | <predecessor or —> | <count> | <count> |
```

5. If `--done` and a task name is specified (e.g., `/task-list --done setup-auth`):
   - Show full detail for that task including all key decisions, exported constraints, and files modified.
