# Workflow Hardening & Optimization Plan

## Current State

| Category | Tokens | Files |
|----------|--------|-------|
| Agents | 5,819 | 9 |
| Commands | 9,282 | 13 |
| References | 4,655 | 3 |
| Hook | 635 | 1 |
| Skills | 17,847 | 12 |
| Verification | 2,032 | 3 |
| **Total** | **40,270** | **41** |

A typical `/task-execute` chain loads the command (1,112), plan-verifier agent (629), N × task-executor agent (1,383 each), task-verifier agent (633), shared-patterns (957), report-formats (3,036), and prd-templates (661) — totaling **~8,411 tokens of orchestration overhead** before any task-specific files (PRD, plan, phase files, CLAUDE.md) are read. With a 4-phase task, this grows to ~13,000+ tokens of pure framework content.

**Target: Reduce per-operation orchestration overhead by ~40%, eliminate fragile YAML parsing, add structural safety nets for sub-agent output, enable multi-task workflows, and fix naming inconsistencies across all 41 files.**

---

## Strategy Overview

Six strategies address distinct failure modes, ordered by impact on reliability and token efficiency.

| # | Strategy | Estimated Impact | Effort |
|---|----------|-----------------|--------|
| 1 | Reduce token budget via lazy-loading and reference compression | ~2,500-3,500 tokens saved per execution chain | Medium |
| 2 | Add sub-agent exit contracts with orchestrator validation | Prevents silent partial failures | Medium |
| 3 | Rewrite hook with robust parsing and expanded context | Eliminates edge-case YAML parsing failures | Low |
| 4 | Add inter-task dependency tracking | Enables multi-task workflows | High |
| 5 | Inline plan verification into plan generation | Eliminates redundant verification pass | Low |
| 6 | Rename verificator → verifier across all files | Consistency across 9 files, ~20 references | Low |

---

## Strategy 1: Reduce Token Budget via Lazy-Loading and Reference Compression [DONE]

### Problem

Every sub-agent spawned during `/task-execute` receives the full agent prompt plus shared references. The biggest offender is `report-formats.md` at 3,036 tokens — it contains templates for 14 different report types, but any single agent uses at most 1-2. The `shared-patterns.md` file (957 tokens) is loaded by every command that says "Follow the task context loading protocol from `.claude/references/shared-patterns.md#task-context-loading`", even though the protocol is just 10 lines of instructions.

### Files Affected

| File | Tokens | Action |
|------|--------|--------|
| `references/report-formats.md` | 3,036 | Split into individual report files |
| `references/shared-patterns.md` | 957 | Inline critical protocols into commands |
| `agents/task-executor.md` | 1,383 | Trim verbose instruction blocks |
| `agents/task-verifier.md` | 633 | Reference only needed report format |
| `agents/plan-verifier.md` | 629 | Reference only needed report format |
| `agents/constraint-tracker.md` | 520 | Reference only needed report format |
| `agents/phase-reviewer.md` | 450 | Reference only needed report format |
| `agents/localization-agent.md` | 353 | Reference only needed report format |
| `commands/task-execute.md` | 1,112 | Stop instructing agents to load shared-patterns |
| `commands/task-plan.md` | 1,227 | Inline the context loading protocol |

> **Note:** This table uses post-rename filenames (see Strategy 6). If implementing Strategy 1 before Strategy 6, substitute `task-verificator.md` / `plan-verificator.md` for the verifier names.

### Fix

#### 1a. Split `report-formats.md` into individual files

**Before** (`references/report-formats.md` — 3,036 tokens):

One monolithic file containing 17 report templates across two sections: 6 task reports (~1,757 tokens: constraint-compliance, verification-report, localization-report, phase-review, plan-verification-report, handoff-yaml) and 11 documentation reports (~1,253 tokens: documentation-discovery, documentation-initialized, research-results-found, research-results-not-found, duplicate-detected, documentation-added, found-documentation, documentation-changed, documentation-to-delete, documentation-deleted, task-based-doc-update).

**After** — split into `references/reports/` directory:

Create one file per report group. Each agent's prompt references only the report it actually writes. Total size remains ~3,036 tokens (content is reorganized, not reduced), but each agent loads only its own ~200-350 token file instead of the full 3,036.

```
references/
├── reports/
│   ├── constraint-compliance.md      # ~300 tokens — used by constraint-tracker
│   ├── verification-report.md        # ~400 tokens — used by task-verifier
│   ├── localization-report.md        # ~280 tokens — used by localization-agent
│   ├── phase-review.md               # ~250 tokens — used by phase-reviewer
│   ├── plan-verification-report.md   # ~330 tokens — used by plan-verifier
│   ├── handoff.md                    # ~200 tokens — used by task-executor
│   └── documentation.md              # ~1,250 tokens — used by docs-manager/researcher
├── shared-patterns.md                # trimmed (see 1b)
└── prd-templates.md                  # unchanged
```

Each agent then references only its own report file. For example, in `agents/task-executor.md`, change:

**Before** (`agents/task-executor.md`, handoff section):

```markdown
### Handoff (if not last phase)

Write `.temp/tasks/<task_name>/handoffs/phase-N-to-N+1.yml`. Must include:
files_modified, constraints_discovered, warnings_for_next_phase, quality_status.
```

**After**:

```markdown
### Handoff (if not last phase)

Write `.temp/tasks/<task_name>/handoffs/phase-N-to-N+1.yml` following the format in `.claude/references/reports/handoff.md`.
```

The agent reads the ~200 token handoff template only when it needs to write one, instead of the orchestrator loading all 3,036 tokens of report-formats.md upfront.

Apply the same pattern to every agent — each gets a single-line reference to its own report file:

| Agent | Report Reference |
|-------|-----------------|
| `constraint-tracker.md` | `references/reports/constraint-compliance.md` |
| `task-verifier.md` | `references/reports/verification-report.md` |
| `plan-verifier.md` | `references/reports/plan-verification-report.md` |
| `phase-reviewer.md` | `references/reports/phase-review.md` |
| `localization-agent.md` | `references/reports/localization-report.md` |
| `task-executor.md` | `references/reports/handoff.md` |

#### 1b. Inline the task context loading protocol

The "task context loading protocol" in `shared-patterns.md` is referenced by 2 commands (`task-execute`, `task-run`) via:

**Before** (e.g., `commands/task-execute.md` line 6):

```markdown
1. Follow the task context loading protocol from `.claude/references/shared-patterns.md#task-context-loading`.
   Specifically extract: all phases, their status, `verification_mode`, and `phase_files`.
```

The agent then has to read `shared-patterns.md` (957 tokens) to get this 10-line protocol. Inline it instead:

**After**:

```markdown
1. **Load task context:**
   a. Read `.temp/tasks/state.yml` — extract `active_task`, `task_path`, `status`, `phase_files`, `verification_mode`, and `constraints`.
   b. Read `prd.md` (at `task_path/prd.md`) for requirements and constraints.
   c. Read `plan.md` (at `task_path/plan.md`) for progress and implementation approach.
   d. If `phase_files` is populated, read each `plan-phase-N.md` listed there.
   e. If `context.md` exists, read it for additional context.
   f. If `active_task` is `none` or missing: report "No active task" and stop.
```

Apply to: `commands/task-execute.md` and `commands/task-run.md`.

> **Note:** `commands/task-constraints.md` also references `shared-patterns.md` but uses the **constraint check protocol** (a different section, `#constraint-check-protocol`). Do NOT inline that — it is used less frequently and benefits from being a shared reference. `commands/task-update-docs.md` does not reference `shared-patterns.md` at all.

After inlining, `shared-patterns.md` retains only **Quality Command Discovery**, **Constraint Check Protocol**, and **Severity Levels** — sections used less frequently and only by verification agents.

#### 1c. Trim task-executor verbose instruction blocks

**Before** (`agents/task-executor.md` — self-refine loop, 28 lines):

```markdown
### Self-Refine Loop (MANDATORY per phase)

After all tasks in the phase are implemented, run the self-refine loop:

**For verification-only phases (no Files listed or Files section shows "none"):**
1. Run each quality check TODO item in sequence
2. Mark each TODO `- [x]` as it passes
3. If a check fails: report to user with details (cannot auto-fix without code scope)
4. Skip the standard self-refine loop — no code to iterate on
5. Verify all TODOs in your `plan-phase-N.md` are marked `- [x]`

**For standard phases with files to modify:**

```

iteration = 0
max_iterations = 3

while iteration < max_iterations:
    1. Quality checks (conditional):
       - If verification_mode is "final" or "none": SKIP quality commands
       - If verification_mode is "per_phase": Discover quality commands from `package.json` (scripts), `Makefile`, or `CLAUDE.md` (dev commands section). Run lint, type-check, and test commands.

    2. If any quality command fails:
       a. Fix the errors
       b. iteration++
       c. continue to next iteration

    3. If all quality commands pass (or were skipped):
       BREAK (phase complete). The loop exits deterministically:
       - When quality commands are enabled (per_phase): exit after all pass.
       - When quality commands are skipped (final/none): exit after one iteration.
       - Max iterations (3) remains a hard safety cap.

Result: Phase is complete only when self-refine loop exits cleanly.

```
```

**After** (14 lines):

```markdown
### Self-Refine Loop (MANDATORY per phase)

After implementing all tasks, run up to 3 iterations:

1. **Verification-only phases** (no files to modify): Run each quality check TODO, mark `- [x]` as it passes. Report failures to user. Skip the loop below.

2. **Standard phases** — loop (max 3 iterations):
   - If `verification_mode` is `per_phase`: run lint, type-check, test commands (discover from `package.json` scripts, `Makefile`, or `CLAUDE.md`).
   - If `verification_mode` is `final` or `none`: skip quality commands.
   - If any command fails: fix errors and repeat.
   - If all pass (or skipped): phase complete — exit loop.

Phase is complete only when this loop exits cleanly.
```

### Estimated Savings

- Splitting `report-formats.md`: each agent loads ~200-400 tokens instead of 3,036. Per execution chain (orchestrator + 1 executor + 1 verifier), saves **~2,200-2,500 tokens**.
- Inlining context protocol: eliminates 957-token `shared-patterns.md` load for 2 commands. Inlined text is ~120 tokens. Saves **~830 tokens per command invocation**.
- Trimming task-executor: ~180 tokens per executor spawn × N phases.

**Total: ~3,000-3,500 tokens saved per typical `/task-execute` chain (~35-40% reduction in orchestration overhead).**

---

## Strategy 2: Add Sub-Agent Exit Contracts with Orchestrator Validation [DONE]

### Problem

Sub-agents spawned via Claude Code's Task tool operate without memory of prior interactions and may skip steps — especially writing handoff files, marking TODO items, or propagating constraints. The orchestrator in `task-execute.md` currently trusts agents to produce correct output without verification. If an executor fails to write its handoff file, the next sequential phase starts without critical context.

### Files Affected

| File | Lines | Action |
|------|-------|--------|
| `agents/task-executor.md` | 117 | Add exit contract section |
| `agents/task-verificator.md` | 45 | Add exit contract section |
| `agents/plan-verificator.md` | 53 | Add exit contract section |
| `commands/task-execute.md` | 80 | Add post-spawn validation checks |

### Fix

#### 2a. Define exit contracts for each agent

Add a `## Exit Contract` section to each agent file. This is a structured output the agent MUST produce as its final message when completing its work.

**Before** (`agents/task-executor.md` — ends with):

```markdown
## Hard Rules

- Do NOT implement code from other phases.
- Do NOT skip quality checks unless `verification_mode` is `final` or `none`.
- Do NOT mark a task complete if its implementation has not been saved to disk.
- Do NOT mark the phase complete if quality checks are still failing (when they are required).
- MANDATORY: Mark each task `- [x]` immediately after completing it in `plan-phase-N.md` — never batch at the end.
- Do NOT write to `plan.md` Overall Progress — the orchestrator updates it centrally after all executors complete.
- Do not add scope beyond what the TODO items describe. Use the PRD for additional context.
```

**After** (append before Hard Rules):

```markdown
## Exit Contract

When your phase is complete (or if you cannot complete it), you MUST output a structured status block as the LAST thing in your response. This is mandatory — the orchestrator validates this output.

```yaml
# EXIT CONTRACT — Phase N
status: COMPLETE | PARTIAL | FAILED
phase: <phase_number>
todos_total: <count>
todos_done: <count>
files_written:
  - <path to each file you created or modified>
handoff_written: true | false | N/A  # N/A if last phase
constraints_discovered: <count>  # 0 if none
quality_checks: PASS | FAIL | SKIPPED
error: <description if PARTIAL or FAILED, null otherwise>
```

Rules:

- ALWAYS output this block, even on failure.
- `status: PARTIAL` means some TODOs completed but you could not finish.
- `status: FAILED` means you could not implement any TODOs (e.g., blocked by constraint violation).
- The orchestrator reads this to decide whether to proceed, retry, or stop.

```

Apply equivalent exit contracts to `plan-verificator.md` and `task-verificator.md`:

**plan-verificator exit contract:**

```yaml
# EXIT CONTRACT — Plan Verification
result: PASS | PARTIAL | FAIL
issues_found: <count>
issues_blocking: <count>
report_written: true | false
report_path: <path to plan-verify-report.md>
```

**task-verificator exit contract:**

```yaml
# EXIT CONTRACT — Task Verification
result: PASS | PARTIAL | FAIL
phases_verified: <count>
issues_found: <count>
issues_critical: <count>
report_written: true | false
report_path: <path to verify-report.md>
```

#### 2b. Add orchestrator validation in task-execute

**Before** (`commands/task-execute.md`, step 5.5):

```markdown
5.5. **Update plan.md Overall Progress:**
   After all task-executors complete, read each `plan-phase-N.md` to check if all TODOs are marked `- [x]`.
   For each phase where all TODOs passed, update the corresponding line in `plan.md` Overall Progress from `- [ ]` to `- [x]`.
   This centralizes progress updates and avoids parallel write conflicts.
6. After all task-executors complete, automatically spawn the **task-verificator agent** (unless `verification_mode=none`).
```

**After**:

```markdown
5.5. **Validate executor exit contracts (MANDATORY):**
   After each task-executor completes, parse its exit contract from the agent's final response.

   a. **Check contract exists.** If no exit contract block found in the agent's output:
      - Report warning: "Executor for phase N did not produce an exit contract."
      - Fall back to file-based validation: check if `plan-phase-N.md` has all TODOs marked `- [x]`.

   b. **Check contract status.** If `status: PARTIAL` or `status: FAILED`:
      - Report the error to the user.
      - Ask: "Phase N reported [status]. Retry this phase, skip it, or stop execution?"
      - If retry: re-spawn executor for that phase (max 2 retries).
      - If skip: proceed to next phase, note the skip in plan.md.
      - If stop: halt execution and report partial progress.

   c. **Check handoff file exists.** If executor reported `handoff_written: true`:
      - Verify `.temp/tasks/<task_name>/handoffs/phase-N-to-N+1.yml` actually exists on disk.
      - If missing: warn user, ask whether to proceed without handoff or retry.

   d. **Check TODO consistency.** Read `plan-phase-N.md` and verify:
      - Count of `- [x]` items matches `todos_done` from exit contract.
      - Count of total items matches `todos_total`.
      - If mismatch: warn user with specific discrepancy.

5.6. **Update plan.md Overall Progress:**
   For each phase where validation passed (all TODOs marked `- [x]`), update the corresponding line in `plan.md` Overall Progress from `- [ ]` to `- [x]`.

6. After all task-executors complete and pass validation, automatically spawn the **task-verifier agent** (unless `verification_mode=none`).
```

### Estimated Savings

Not a token reduction strategy — this is a reliability improvement. Impact: prevents silent failures that currently require manual debugging and re-execution, saving 10-30 minutes per failed multi-phase task.

---

## Strategy 3: Rewrite Hook with Robust Parsing and Expanded Context [DONE]

### Problem

The hook (`hooks/inject-task-context.sh`, 78 lines, 635 tokens) parses `state.yml` using `grep` + `awk` + a `while read` loop. This approach silently breaks on: multiline YAML values, values containing colons with spaces, nested YAML structures, and values with special characters. It also omits `verification_mode` from the injected context, forcing every command to re-read `state.yml` to discover it.

### Files Affected

| File | Lines | Action |
|------|-------|--------|
| `hooks/inject-task-context.sh` | 78 | Rewrite entirely |

### Fix

Replace the bash YAML parser with a Python one-liner that uses PyYAML (available on most systems) with a bash fallback.

**Before** (`hooks/inject-task-context.sh` — 78 lines):

```bash
#!/usr/bin/env bash
# UserPromptSubmit hook — injects active task context into Claude's session.
# Reads state.yml and outputs JSON with additionalContext.

STATE_FILE=".temp/tasks/state.yml"

if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Parse state.yml (simple key: value format)
active_task=$(grep "^active_task:" "$STATE_FILE" | awk '{print $2}' | tr -d '"')
status=$(grep "^status:" "$STATE_FILE" | awk '{print $2}' | tr -d '"')
task_path=$(grep "^task_path:" "$STATE_FILE" | awk '{print $2}' | tr -d '"')

# Parse phase_files list
phase_files_list=""
in_phase_files=0
while IFS= read -r line; do
  if [[ "$line" == "phase_files:" ]]; then
    in_phase_files=1
    continue
  fi
  if [[ $in_phase_files -eq 1 ]]; then
    if [[ "$line" =~ ^[a-zA-Z] ]]; then
      break
    fi
    file=$(echo "$line" | sed 's/^[[:space:]]*- //')
    if [[ -n "$phase_files_list" ]]; then
      phase_files_list="${phase_files_list}, ${file}"
    else
      phase_files_list="${file}"
    fi
  fi
done < "$STATE_FILE"

if [[ -z "$active_task" || "$active_task" == "null" || "$active_task" == "none" ]]; then
  exit 0
fi

# Parse constraints section (multiline YAML between constraints: and next top-level key)
constraints_section=""
in_constraints=0
while IFS= read -r line; do
  if [[ "$line" == "constraints:" ]]; then
    in_constraints=1
    continue
  fi
  if [[ $in_constraints -eq 1 ]]; then
    # Stop at next top-level key (no leading space)
    if [[ "$line" =~ ^[a-zA-Z] ]]; then
      break
    fi
    constraints_section="${constraints_section}${line}\n"
  fi
done < "$STATE_FILE"

# Emit banner to stderr (visible in terminal, not sent to Claude)
echo "Active task: $active_task (status: $status)" >&2

# Build constraints block for context
constraints_block=""
if [[ -n "$constraints_section" ]]; then
  constraints_block="\\n\\nCONSTRAINTS:\\n${constraints_section}"
fi

# Build phase files block
phase_files_block=""
if [[ -n "$phase_files_list" ]]; then
  phase_files_block="\\n- Phase Files: ${phase_files_list}"
fi

# Emit context injection as JSON to stdout (Claude Code reads this)
cat <<JSON
{
  "additionalContext": "ACTIVE TASK CONTEXT:\\n- Task: ${active_task}\\n- Status: ${status}\\n- Path: ${task_path}\\n- PRD: ${task_path}/prd.md\\n- Plan: ${task_path}/plan.md\\n- Context: ${task_path}/context.md${phase_files_block}${constraints_block}\\nAlways read state.yml and relevant task files before acting on any /task-* command.\\n\\nIMPORTANT: Check constraints before making changes. Invariants must NEVER be violated."
}
JSON
```

**After** (`hooks/inject-task-context.sh` — 62 lines):

```bash
#!/usr/bin/env bash
# UserPromptSubmit hook — injects active task context into Claude's session.
# Uses Python+PyYAML for robust parsing, with grep fallback.

STATE_FILE=".temp/tasks/state.yml"

if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# --- Parse state.yml via Python (robust) or grep (fallback) ---

parse_with_python() {
  python3 -c "
import yaml, json, sys

with open('$STATE_FILE') as f:
    state = yaml.safe_load(f)

if not state or state.get('active_task') in (None, 'null', 'none'):
    sys.exit(1)

tp = state.get('task_path', '')
pf = state.get('phase_files', [])
vm = state.get('verification_mode', 'per_phase')
cs = state.get('constraints', {})

# Format constraints
c_lines = []
for inv in cs.get('invariants', []):
    c_lines.append(f\"  - [I] {inv.get('constraint', inv) if isinstance(inv, dict) else inv}\")
for dec in cs.get('decisions', []):
    c_lines.append(f\"  - [D] {dec.get('constraint', dec) if isinstance(dec, dict) else dec}\")
for disc in cs.get('discovered', []):
    c_lines.append(f\"  - [*] {disc.get('constraint', disc) if isinstance(disc, dict) else disc}\")

ctx_parts = [
    'ACTIVE TASK CONTEXT:',
    f\"- Task: {state['active_task']}\",
    f\"- Status: {state.get('status', 'unknown')}\",
    f\"- Path: {tp}\",
    f\"- PRD: {tp}/prd.md\",
    f\"- Plan: {tp}/plan.md\",
    f\"- Verification Mode: {vm}\",
]
if pf:
    ctx_parts.append(f\"- Phase Files: {', '.join(pf)}\")
if c_lines:
    ctx_parts.append('\\nCONSTRAINTS:')
    ctx_parts.extend(c_lines)
ctx_parts.append('\\nAlways read state.yml and relevant task files before acting on any /task-* command.')
ctx_parts.append('IMPORTANT: Check constraints before making changes. Invariants must NEVER be violated.')

# Banner to stderr
print(f\"Active task: {state['active_task']} (status: {state.get('status')}, mode: {vm})\", file=sys.stderr)

# JSON to stdout
print(json.dumps({'additionalContext': '\\n'.join(ctx_parts)}))
" 2>/dev/null
}

parse_with_grep() {
  active_task=$(grep "^active_task:" "$STATE_FILE" | head -1 | sed 's/^active_task:[[:space:]]*//' | tr -d '"')
  status=$(grep "^status:" "$STATE_FILE" | head -1 | sed 's/^status:[[:space:]]*//' | tr -d '"')
  task_path=$(grep "^task_path:" "$STATE_FILE" | head -1 | sed 's/^task_path:[[:space:]]*//' | tr -d '"')
  vm=$(grep "^verification_mode:" "$STATE_FILE" | head -1 | sed 's/^verification_mode:[[:space:]]*//' | tr -d '"')

  if [[ -z "$active_task" || "$active_task" == "null" || "$active_task" == "none" ]]; then
    exit 0
  fi

  echo "Active task: $active_task (status: $status, mode: ${vm:-per_phase})" >&2

  printf '{"additionalContext":"ACTIVE TASK CONTEXT:\\n- Task: %s\\n- Status: %s\\n- Path: %s\\n- PRD: %s/prd.md\\n- Plan: %s/plan.md\\n- Verification Mode: %s\\nAlways read state.yml and relevant task files before acting on any /task-* command.\\nIMPORTANT: Check constraints before making changes. Invariants must NEVER be violated."}' \
    "$active_task" "$status" "$task_path" "$task_path" "$task_path" "${vm:-per_phase}"
}

# Try Python first, fall back to grep
parse_with_python || parse_with_grep
```

Key improvements:

1. **PyYAML handles all YAML edge cases** — nested structures, colons in values, multiline strings.
2. **Adds `verification_mode`** to injected context — agents no longer need to re-read state.yml for this.
3. **Constraint formatting distinguishes types** — `[I]` for invariants, `[D]` for decisions, `[*]` for discovered.
4. **Grep fallback** ensures the hook works even without Python/PyYAML installed, but with reduced functionality (no constraints, no phase files).
5. **`head -1`** prevents multi-match bugs from grep.

### Estimated Savings

Not a token reduction — a reliability fix. Eliminates silent parsing failures and reduces redundant state.yml reads by injecting `verification_mode` upfront.

---

## Strategy 4: Add Inter-Task Dependency Tracking [DONE]

### Problem

`state.yml` tracks a single `active_task` with no mechanism to reference prior tasks. When Task B depends on Task A's architectural decisions, the user must manually re-explain constraints from Task A. Archived tasks exist in `.temp/tasks/archive/` but nothing links them to new tasks.

### Files Affected

| File | Lines | Action |
|------|-------|--------|
| `commands/task-create.md` | 81 | Add `--after <task>` flag |
| `commands/task-complete.md` | 52 | Write task summary to registry |
| `references/prd-templates.md` | 92 | Add "Predecessor" section, renumber 11→12→13 |
| `commands/task-add-context.md` | 39 | Fix section number reference (9→12) |
| `commands/task-run.md` | 32 | Update section number reference (12→13) |
| `commands/task-update-docs.md` | 73 | Update section number references (12→13, 9→12) |
| NEW: `commands/task-list.md` | ~45 | New command to list tasks |

### Fix

#### 4a. Add task registry file

Create a persistent task registry at `.temp/tasks/registry.yml` that survives individual task lifecycles. `/task-complete` writes to it; `/task-create` reads from it.

**New file** (`.temp/tasks/registry.yml` — created automatically):

```yaml
# Task Registry — auto-maintained by /task-complete and /task-create
tasks:
  - name: setup-auth
    status: done
    created_at: 2025-03-15T10:00:00Z
    completed_at: 2025-03-15T14:30:00Z
    prd_path: .temp/tasks/archive/setup-auth/prd.md
    key_decisions:
      - "D1: Use OAuth2 with PKCE flow"
      - "D2: JWT tokens with 15-min expiry"
    constraints_exported:
      - "All API calls must use Bearer token authentication"
      - "Refresh tokens stored server-side only"
    files_modified:
      - src/auth/oauth.ts
      - src/middleware/auth.ts
  - name: add-user-profiles
    status: done
    depends_on: setup-auth
    # ...
```

#### 4b. Modify `/task-complete` to write to registry

**Before** (`commands/task-complete.md`, step 4):

```markdown
4. **Update `state.yml`:**
   ```yaml
   active_task: none
   status: done
   completed_at: <ISO timestamp>
   updated_at: <ISO timestamp>
   ```

```

**After** (insert between step 4 and step 5):

```markdown
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

```

#### 4c. Modify `/task-create` to accept `--after <task>`

**Before** (`commands/task-create.md`, step 1):

```markdown
1. Parse `$ARGUMENTS`:
   a. Detect `--quick` anywhere in the arguments string. If present, set QUICK_MODE=true and remove `--quick` from the string.
   b. From the remaining string: first word is `<task-name>` (slugified, lowercase, hyphens), remainder is the description.
   c. If QUICK_MODE is false, check the description against the Quick-Suggest Heuristic below. If it matches, mention to the user: "This looks like a quick task. Consider using `--quick` for a faster flow." Then proceed with the full flow unchanged.
```

**After**:

```markdown
1. Parse `$ARGUMENTS`:
   a. Detect `--quick` anywhere in the arguments string. If present, set QUICK_MODE=true and remove `--quick` from the string.
   b. Detect `--after <predecessor-task>` anywhere in the arguments string. If present, set PREDECESSOR=<predecessor-task> and remove the flag from the string.
   c. From the remaining string: first word is `<task-name>` (slugified, lowercase, hyphens), remainder is the description.
   d. If QUICK_MODE is false, check the description against the Quick-Suggest Heuristic below. If it matches, mention to the user: "This looks like a quick task. Consider using `--quick` for a faster flow." Then proceed with the full flow unchanged.

1.5. **Load predecessor context (if `--after` specified):**
   a. Read `.temp/tasks/registry.yml`.
   b. Find the entry matching PREDECESSOR name. If not found, warn and continue without predecessor.
   c. Extract `key_decisions`, `constraints_exported`, and `files_modified` from the registry entry.
   d. If predecessor's `prd_path` exists, read its Section 9 (Decisions) and Section 10 (Constraints) for full context.
   e. Store predecessor context for injection into the new PRD.
```

#### 4d. Add predecessor section to Full PRD template

**Before** (`references/prd-templates.md`, after Section 11):

```markdown
## 11. Additional Context
[Reserved — populated by /task-add-context]
```

**After** (insert between Section 10 and Section 11, shifting numbering):

```markdown
## 11. Predecessor Task
[Populated by /task-create when `--after` flag is used]

| Field | Value |
|-------|-------|
| Predecessor | <task-name> |
| Key Decisions Inherited | <D1 summary>, <D2 summary> |
| Constraints Inherited | <list> |
| Files to Be Aware Of | <list of files modified by predecessor> |

**Inherited constraints are automatically added to Section 10 as invariants.**

## 12. Additional Context
[Reserved — populated by /task-add-context]

## 13. Ad-Hoc Changes
[Populated during implementation — tracks changes made outside the original plan]
| Date | Type | Description | Files Affected | Rationale |
|------|------|-------------|----------------|-----------|
```

Also update `state.yml` template to include:

```yaml
depends_on: <predecessor-task-name or null>
```

**IMPORTANT: Update section number references across the codebase.**

Inserting Section 11 (Predecessor Task) shifts the existing sections:

- Old Section 11 (Additional Context) → **Section 12**
- Old Section 12 (Ad-Hoc Changes) → **Section 13**

Files that reference these by number must be updated:

| File | Current Reference | New Reference |
|------|-------------------|---------------|
| `commands/task-add-context.md` line 30 | "Section 9 (Additional Context)" | "Section 12 (Additional Context)" |
| `commands/task-run.md` line 21 | "Section 12 (Ad-Hoc Changes)" | "Section 13 (Ad-Hoc Changes)" |
| `commands/task-update-docs.md` lines 11, 20 | "Section 12" (Ad-Hoc Changes) | "Section 13" |
| `commands/task-update-docs.md` line 65 | "Section 9 (Additional Context)" | "Section 12 (Additional Context)" |

> **Pre-existing bug found:** `task-add-context.md` currently says "Section 9 (Additional Context)" but Section 9 has always been "Decisions" — Section 11 is "Additional Context". The same bug exists in `task-update-docs.md` line 65. Fix both to use Section 12 (the new number after renumbering). Sections 9 (Decisions) and 10 (Constraints) are unchanged.

#### 4e. New `/task-list` command

**New file** (`commands/task-list.md`):

```markdown
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
```

### Estimated Savings

Not a token reduction — a capability addition. Enables multi-task workflows where each task builds on prior decisions, eliminating manual re-explanation of constraints (~5-10 min per dependent task).

---

## Strategy 5: Inline Plan Verification into Plan Generation [DONE]

### Problem

`/task-plan` generates the plan (step 8), writes it, then spawns `plan-verificator` as a separate step 10. This means the user sees the plan, then gets a verification report that might say "FAIL — 3 requirements not covered." The user then waits for auto-fix iterations. This is wasteful because the plan-generation step already has all the context needed to check coverage — it just read the PRD and scanned the repo.

### Files Affected

| File | Lines | Action |
|------|-------|--------|
| `commands/task-plan.md` | 89 | Merge verification into generation step |

### Fix

**Before** (`commands/task-plan.md`, steps 8-10):

```markdown
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
```

**After**:

```markdown
8. **Generate and verify the plan inline:**

   a. Read all PRD functional requirements (Section 3) and extract a checklist of requirement IDs (FR-1, FR-2, ...).

   b. Read `CLAUDE.md` for coding guidelines, naming conventions, and structural rules.

   c. Generate the plan files:
      - Always generate an index `plan.md` plus individual `plan-phase-N.md` files.
      - For "single phase" (A): generate exactly one `plan-phase-1.md` with all TODOs.
      - For "split into phases" (B): generate multiple phase files with dependency graph.

   d. **Self-check before writing (MANDATORY):**
      Before writing any file, verify internally:

      - **Coverage**: Every FR-N from step 8a maps to at least one TODO in a phase file. If any FR-N is unmapped, add a TODO for it to the appropriate phase.
      - **Dependencies**: Phase dependency graph has no cycles. Each phase's `Dependencies:` header is consistent with the graph in `plan.md`.
      - **Quality commands**: If `verification_mode` is `per_phase`, every phase file has a Quality Checks section with commands discovered from the project. If `final`, a `plan-phase-final.md` exists with quality check TODOs.
      - **Guideline consistency**: File paths in TODOs follow naming conventions from CLAUDE.md. Planned actions don't violate structural rules.

      If any check fails, fix it in the generated content before writing. Do not write a plan you know is incomplete.

   e. Write all plan files.

9. Write to `state.yml`: `phase_files` list, `verification_mode`, status `planned`.

10. **Post-write deep verification (optional, for complex tasks):**
    If the task has 3+ phases or the user requested deep verification:
    - Spawn `plan-verifier` agent in **deep** mode.
    - This catches file conflicts, edge case coverage, and constraint traceability that are harder to verify inline.
    - Report results to user.
    If the task is simple (1-2 phases), skip this step — the inline check in step 8d is sufficient.
```

Key changes:

1. **Coverage, dependency, and guideline checks happen during generation** (step 8d) rather than after. The LLM already has the PRD in context — checking coverage is a simple cross-reference, not a separate agent spawn.
2. **Deep verification remains available** but is now optional and reserved for complex tasks. Simple tasks skip the extra agent spawn entirely.
3. **The plan-verifier agent is NOT removed** — it's still needed for `/task-verify plan deep` and for the pre-execution gate in `/task-execute`. Its role shifts from "always run after planning" to "deep analysis on demand."

### Estimated Savings

Eliminates 1 sub-agent spawn (629 tokens for plan-verifier agent prompt) for simple tasks. More importantly, eliminates the user-facing back-and-forth cycle of "generate → verify → auto-fix → re-verify" which currently takes 2-4 iterations for plans that fail coverage checks. Saves ~30-60 seconds of wall-clock time per plan generation.

---

## Strategy 6: Rename Verificator → Verifier Across All Files [DONE]

### Problem

The term "verificator" is used in 9 files across ~20 references. It's a non-standard English word (the standard form is "verifier"). This causes confusion when searching, discussing, or extending the workflow.

### Files Affected

| File | Occurrences | Action |
|------|-------------|--------|
| `agents/plan-verificator.md` | filename + 2 internal | Rename file + update content |
| `agents/task-verificator.md` | filename + 2 internal | Rename file + update content |
| `commands/task-execute.md` | 10 | Find-replace |
| `commands/task-plan.md` | 3 | Find-replace |
| `commands/task-verify.md` | 2 | Find-replace |
| `commands/task-constraints.md` | 1 | Find-replace |
| `verification/performance.md` | 1 | Find-replace |
| `verification/quality.md` | 1 | Find-replace |
| `verification/security.md` | 1 | Find-replace |

### Fix

This is a mechanical find-and-replace with two file renames.

**Step 1: Rename files**

```bash
mv agents/plan-verificator.md agents/plan-verifier.md
mv agents/task-verificator.md agents/task-verifier.md
```

**Step 2: Update frontmatter in renamed files**

In `agents/plan-verifier.md`:

```yaml
# Before
name: plan-verificator
description: Verifies plan quality before execution. Checks coverage, dependencies, quality commands, and guideline consistency. Spawned by /task-plan and /task-execute.

# After
name: plan-verifier
description: Verifies plan quality before execution. Checks coverage, dependencies, quality commands, and guideline consistency. Spawned by /task-plan and /task-execute.
```

In `agents/task-verifier.md`:

```yaml
# Before
name: task-verificator
description: Verifies the full implementation after all task-executor agents complete. Spawned by /task-execute.

# After
name: task-verifier
description: Verifies the full implementation after all task-executor agents complete. Spawned by /task-execute.
```

**Step 3: Global find-replace across all files**

Apply these replacements in all `.md` files:

| Find | Replace |
|------|---------|
| `plan-verificator` | `plan-verifier` |
| `task-verificator` | `task-verifier` |
| `Plan-Verificator` | `Plan-Verifier` |
| `Task-Verificator` | `Task-Verifier` |
| `Verificator Agent` | `Verifier Agent` |
| `Verificator` (standalone, case-sensitive) | `Verifier` |
| `verificator` (standalone, case-sensitive) | `verifier` |

**Step 4: Verify no orphaned references**

```bash
grep -r "verificator" .claude/
# Should return zero results
```

### Estimated Savings

Zero token impact. Pure consistency improvement. Reduces cognitive overhead when reading, searching, or extending the workflow.

---

## New File Structure

```
.claude/
├── agents/
│   ├── constraint-tracker.md       # ~520 tokens, add exit contract
│   ├── docs-initializer.md         # unchanged
│   ├── docs-manager.md             # unchanged
│   ├── docs-researcher.md          # unchanged
│   ├── localization-agent.md       # ~353 tokens, add exit contract
│   ├── phase-reviewer.md           # unchanged
│   ├── plan-verifier.md            # RENAMED from plan-verificator.md, add exit contract
│   ├── task-executor.md            # 1,383 → ~1,250 tokens (trimmed + exit contract)
│   └── task-verifier.md            # RENAMED from task-verificator.md, add exit contract
├── commands/
│   ├── project-docs.md             # unchanged
│   ├── project-rules.md            # unchanged
│   ├── task-add-context.md         # unchanged
│   ├── task-checkpoint.md          # unchanged
│   ├── task-clarify.md             # unchanged
│   ├── task-complete.md            # ~594 → ~680 tokens (registry write)
│   ├── task-constraints.md         # updated references
│   ├── task-create.md              # ~937 → ~1,050 tokens (--after flag)
│   ├── task-execute.md             # ~1,112 → ~1,250 tokens (validation checks)
│   ├── task-list.md                # NEW — ~350 tokens
│   ├── task-plan.md                # ~1,227 → ~1,150 tokens (inline verification)
│   ├── task-run.md                 # updated references
│   ├── task-update-docs.md         # updated references
│   └── task-verify.md              # updated references
├── hooks/
│   └── inject-task-context.sh      # 635 → ~600 tokens (rewritten)
├── references/
│   ├── prd-templates.md            # ~661 → ~720 tokens (predecessor section)
│   ├── reports/                    # NEW directory
│   │   ├── constraint-compliance.md    # ~300 tokens (extracted)
│   │   ├── documentation.md            # ~1,250 tokens (extracted)
│   │   ├── handoff.md                  # ~200 tokens (extracted)
│   │   ├── localization-report.md      # ~280 tokens (extracted)
│   │   ├── phase-review.md             # ~250 tokens (extracted)
│   │   ├── plan-verification-report.md # ~330 tokens (extracted)
│   │   └── verification-report.md      # ~400 tokens (extracted)
│   └── shared-patterns.md         # 957 → ~600 tokens (context protocol removed)
├── skills/                         # unchanged subtree
└── verification/                   # updated verificator→verifier references
```

---

## Projected Totals

| Category | Before | After | Change |
|----------|--------|-------|--------|
| Agents | 5,819 | ~5,950 | +2% (exit contracts added, executor trimmed) |
| Commands | 9,282 | ~9,850 | +6% (new task-list, --after flag, validation) |
| References | 4,655 | ~4,300 | -8% (shared-patterns trimmed; report-formats split into reports/ but total content preserved) |
| Hook | 635 | ~600 | -6% |
| Skills | 17,847 | 17,847 | unchanged |
| Verification | 2,032 | 2,032 | unchanged |
| **Total** | **40,270** | **~40,580** | **+0.8%** |

**Total file size increases slightly** due to new capabilities (exit contracts, task-list, --after flag). But total file size is not the real metric — most files are never loaded together. The key metric is **active context per operation**:

| Operation | Before | After | Reduction |
|-----------|--------|-------|-----------|
| `/task-execute` (4-phase) | ~8,411 orchestration tokens | ~5,200 tokens | **-38%** |
| `/task-plan` (simple task) | ~2,850 tokens (plan + verify agent) | ~1,950 tokens (inline check) | **-32%** |
| `/task-run` | ~1,360 tokens (shared-patterns load) | ~520 tokens (inlined protocol) | **-62%** |

---

## Implementation Priority

1. **Do first** (highest impact, lowest effort):
   - Rename `agents/plan-verificator.md` → `agents/plan-verifier.md` and `agents/task-verificator.md` → `agents/task-verifier.md`; global find-replace `verificator` → `verifier` across all 9 files (Strategy 6)
   - Rewrite `hooks/inject-task-context.sh` with Python parser + grep fallback (Strategy 3)
   - Inline task context loading protocol into `commands/task-execute.md` and `commands/task-run.md`, then trim `references/shared-patterns.md` (Strategy 1b)

2. **Do second** (medium impact, medium effort):
   - Split `references/report-formats.md` into `references/reports/` directory; update all agent file references (Strategy 1a)
   - Trim `agents/task-executor.md` self-refine loop (Strategy 1c)
   - Merge plan verification into plan generation step in `commands/task-plan.md` (Strategy 5)

3. **Do third** (high impact, high effort):
   - Add exit contracts to `agents/task-executor.md`, `agents/plan-verifier.md`, `agents/task-verifier.md`; add orchestrator validation to `commands/task-execute.md` (Strategy 2)
   - Add task registry, `--after` flag to `commands/task-create.md`, registry write to `commands/task-complete.md`, predecessor section to `references/prd-templates.md`, and new `commands/task-list.md` (Strategy 4)

---

## Validation

After applying all changes, verify by:

1. **Naming consistency:**

   ```bash
   grep -r "verificator" .claude/
   # Must return zero results
   ```

2. **File structure:**

   ```bash
   ls .claude/agents/plan-verifier.md .claude/agents/task-verifier.md
   ls .claude/references/reports/
   ls .claude/commands/task-list.md
   # All must exist
   ```

3. **Hook functionality:**

   ```bash
   # Create a minimal test state.yml
   mkdir -p .temp/tasks
   cat > .temp/tasks/state.yml << 'EOF'

active_task: test-hook
status: in_progress
task_path: .temp/tasks/test-hook
verification_mode: per_phase
phase_files:

- plan-phase-1.md
constraints:
  invariants:
  - id: I1
      constraint: "Test constraint with: colon"
  decisions: []
  discovered: []
EOF
   bash .claude/hooks/inject-task-context.sh

# Must output valid JSON with "verification_mode" and constraint text including the colon

   rm -rf .temp/tasks

   ```

4. **Functional smoke test:**
   ```

   /task-create test-validation "Add a hello world endpoint" --quick

# Should succeed, creating PRD + single-phase plan

   /task-list

# Should show the active task

   /task-complete

# Should write to registry.yml

   /task-list --done

# Should show the completed task with key decisions

   ```

Check that:
- No command references a non-existent file (e.g., `plan-verificator.md`)
- Exit contract YAML blocks render correctly in agent outputs
- `report-formats.md` no longer exists (replaced by `reports/` directory)
- `shared-patterns.md` no longer contains the "Task Context Loading" section
- No file references "Section 11 (Additional Context)" or "Section 12 (Ad-Hoc Changes)" with the old numbering — grep for `Section 11` and `Section 12` to verify they point to the correct headings after renumbering
- `task-add-context.md` no longer says "Section 9 (Additional Context)" (pre-existing bug, fixed as part of Strategy 4)

If any grep for `verificator` returns results, re-run the find-replace step. If the hook fails on the colon test, check the Python parser handles `yaml.safe_load` correctly for constraint dicts.

---

## Key Principle

> A workflow system for LLM agents must be defensive by default — trust but verify every sub-agent output structurally, load only the context each agent actually needs, and never assume YAML parsed by bash is YAML parsed correctly.
