# Handoff Template

Written to `.temp/tasks/<task_name>/handoffs/phase-N-to-N+1.yml`.

```yaml
# Handoff: Phase N → Phase N+1
generated_at: <ISO timestamp>
from_phase: N
to_phase: N+1

files_modified:
  - path: path/to/file1.ts
    summary: "Brief description of what changed"
  - path: path/to/file2.ts
    summary: "Brief description of what changed"

constraints_discovered:
  - "New constraint discovered during implementation"
  - "Another constraint that next phase should know about"

warnings_for_next_phase:
  - "Important note about shared state"
  - "Potential conflict area to watch"

quality_status:
  lint: PASS | SKIPPED (final mode) | SKIPPED (none mode)
  type_check: PASS | SKIPPED (final mode) | SKIPPED (none mode)
  tests: PASS | SKIPPED (final mode) | SKIPPED (none mode)
  notes: "All quality checks passed after 2 iterations" | "Skipped per verification_mode=final" | "Skipped per verification_mode=none"

api_changes:
  - file: src/api/users.ts
    added: ["getUserById"]
    modified: ["updateUser"]
    removed: []
```
