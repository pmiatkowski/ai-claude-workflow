# Context Reduction Plan

## Current State

| Category | Tokens | Files |
|----------|--------|-------|
| Commands | ~8,890 | 13 |
| Agents | ~6,796 | 9 |
| Skills | ~13,165 | 12 |
| Verification | ~2,102 | 3 |
| Hook | ~408 | 1 |
| **Total** | **~31,362** | **38** |

Not all files load simultaneously, but a single `/task-execute` invocation pulls ~3,700 tokens of instructions before touching any project files. Combined with PRD (~500-1500), plan + phase files (~500-2000), state.yml, CLAUDE.md, and source code context — you can easily hit 8-12K tokens of overhead per operation.

**Target: reduce per-file instruction size by 40-60%, prioritizing the hot path (commands + agents used during execution).**

---

## Strategy Overview

Five concrete strategies, ordered by impact:

| # | Strategy | Estimated Savings | Effort |
|---|----------|-------------------|--------|
| 1 | Extract report templates to reference files | ~35% of agents | Medium |
| 2 | Trim verbose explanations to terse instructions | ~25% of commands | Low |
| 3 | Deduplicate shared patterns into a single shared reference | ~15% across agents | Medium |
| 4 | Convert example output blocks to 1-line descriptions | ~20% of commands | Low |
| 5 | Lazy-load verification checklists (don't inline) | ~100% of verification | Low |

---

## Strategy 1: Extract Report Templates to Reference Files [DONE]

### Problem

Agents contain full markdown report templates inline — often 30-60 lines of fenced code blocks showing exact output format. Claude doesn't need this level of prescription; a brief description + field list is sufficient.

### Files Affected

| File | Template Lines | Action |
|------|---------------|--------|
| `agents/constraint-tracker.md` | ~40 lines (compliance report) | Extract |
| `agents/plan-verificator.md` | ~30 lines (verification report) | Extract |
| `agents/task-verificator.md` | ~35 lines (verification report) | Extract |
| `agents/phase-reviewer.md` | ~25 lines (review report) | Extract |
| `agents/localization-agent.md` | ~25 lines (localization report) | Extract |
| `agents/docs-manager.md` | ~60 lines (multiple report blocks) | Extract |
| `agents/docs-researcher.md` | ~25 lines (result templates) | Extract |
| `agents/docs-initializer.md` | ~20 lines (summary template) | Extract |

### Fix

Create a single reference file: `.claude/references/report-formats.md`

Agents reference it only when generating output:

**Before** (`agents/constraint-tracker.md` — 730 tokens):

```markdown
## Output

Write a constraint compliance report to `.temp/tasks/<task_name>/constraint-report.md`:

\```markdown
# Constraint Compliance Report: <task-name>

**Date:** <date>
**Stage:** pre-plan | post-plan | post-phase | final
**Phase:** (if applicable)

## Summary
| Category | Total | Pass | Fail | Unchecked |
|----------|-------|------|------|-----------| 
| Invariants | 5 | 4 | 0 | 1 |
| Decision-Derived | 3 | 3 | 0 | 0 |
| **Total** | 8 | 7 | 0 | 1 |

## Invariant Compliance
| ID | Constraint | Status | Evidence | Notes |
|----|------------|--------|----------|-------|
| I1 | All API calls authenticated | PASS | authMiddleware on all routes | - |

## Decision-Derived Compliance
| ID | From | Constraint | Status | Evidence |
|----|------|------------|--------|----------|
| D1-1 | D1 | Use OAuth2 | PASS | OAuth2Strategy imported |

## Violations Found
| # | Severity | Constraint | File | Issue | Required Fix |
|---|----------|------------|------|-------|--------------| 
| 1 | HIGH | I5 | api/public.ts | Missing auth | Add authMiddleware |

## Recommendations
1. [Specific recommendation]

## Verdict
PASS | FAIL | NEEDS_ATTENTION
\```
```

**After** (~3 lines replacing ~40):

```markdown
## Output

Write a constraint compliance report to `.temp/tasks/<task_name>/constraint-report.md`.
Include: summary table (category/total/pass/fail), compliance details per constraint with status+evidence, violations with severity/file/fix, and a verdict (PASS/FAIL/NEEDS_ATTENTION).
See `.claude/references/report-formats.md#constraint-compliance` for the full template.
```

### Estimated Savings

~150-250 tokens per agent × 8 agents = **~1,200-2,000 tokens saved** from inline templates.

---

## Strategy 2: Trim Verbose Explanations [DONE]

### Problem

Commands contain explanatory prose that Claude doesn't need. Claude understands concepts like "search for files" without being told _why_ searching is useful.

### Files Affected (top offenders)

**`commands/task-plan.md` (1,618 tokens → target ~900)**

Cut these sections:

- The full Plan Format Spec is ~80 lines. Most of it repeats the same rules 3 times (once in the spec, once in "Rules" section, once in phase file templates). Deduplicate.
- The `plan-phase-N.md` and `plan-phase-final.md` templates are shown in full. Replace with 3-line descriptions.

Specific cuts in `task-plan.md`:

```
REMOVE — duplicate rule statements:
- "Quality Checks section in phase files is only included when verification_mode: per_phase."
  (stated 3 times in the file: steps, format spec, and key rules)
- "When verification_mode=none: no Quality Checks section..." 
  (stated 3 times)
- "Generate separate plan-phase-N.md files. The main plan.md is an index only."
  (stated 2 times)
- "Write phase_files and verification_mode to state.yml."
  (stated 2 times)

TRIM — plan.md template (currently 18 lines):
  Replace with: "Write plan.md as index: status, PRD ref, verification mode, 
  overall progress (checkbox per phase), dependency graph, phase file list."

TRIM — plan-phase-N.md template (currently 16 lines):
  Replace with: "Each phase file: goal (1-2 sentences), dependencies, file list 
  with action (create/modify/delete), TODO list (verb-first single-line items). 
  Add Quality Checks section only when verification_mode=per_phase."

TRIM — plan-phase-final.md template (currently 14 lines):
  Replace with: "Final verification phase (only when verification_mode=final): 
  no files to modify, TODOs for type-check, lint, test, and plan verification."
```

**`commands/task-create.md` (1,194 tokens → target ~700)**

Cut these sections:

- Full PRD template is 40 lines. It never changes. Move to `.claude/references/prd-templates.md`.
- Quick PRD template is 15 lines. Same — move to reference.
- State.yml templates shown twice (full + quick). Show once, note the differences.

```
REPLACE full PRD template (40 lines) WITH:
  "Generate prd.md using the Full PRD Template from 
  .claude/references/prd-templates.md#full"

REPLACE quick PRD template (15 lines) WITH:
  "Generate prd.md using the Quick PRD Template from 
  .claude/references/prd-templates.md#quick"

REPLACE two state.yml templates (30 lines total) WITH single block:
  "Write state.yml with: active_task, created_at, updated_at, status (draft|planned),
  task_path, prd, plan, context, constraints (invariants/decisions/discovered arrays).
  Quick mode adds: phase_files list, verification_mode: none, status: planned."
```

**`commands/task-execute.md` (1,111 tokens → target ~650)**

Cut these sections:

- Orchestration strategy table + explanation is clear but repeated in prose below. Keep table, cut prose.
- task-executor instructions block (15 lines) — this is the agent spawn prompt, but the agent file already has these instructions. You're writing them twice.
- Builder-Reviewer pattern section can be 3 lines.

```
REMOVE — the "task-executor Agent Instructions" fenced block:
  The agent file (agents/task-executor.md) already contains all these instructions.
  Replace with: "Spawn task-executor with: task_name, phase_number, plan_path, 
  phase_file_path, prd_path, handoff_path (if sequential)."

TRIM — Builder-Reviewer section from 7 lines to 2:
  "For high-risk phases: spawn task-executor, then phase-reviewer. 
  If rejected, re-spawn executor with feedback (max 2 retries)."

TRIM — Auto-Remediation Loop from 20 lines to 8:
  Collapse the if/else narrative into a simple algorithm:
  "1. Read verify-report result.
  2. If PASS → done.
  3. If FAIL/PARTIAL → ask user to auto-fix.
  4. If yes: spawn executors for affected phases with issues table, 
     re-verify. Max 2 iterations. Report remaining issues if still failing."
```

**`commands/task-clarify.md` (582 tokens → target ~350)**

```
TRIM — Clarification Session Format section:
  The markdown table format with 4 options per question doesn't need to be 
  specified this precisely. Replace the full template with:
  "For each question: explain why it matters (1-2 sentences), present 
  options in a table (option/description/tradeoffs), give your recommendation.
  Wait for response. Accept single option, combinations, or modifications."

REMOVE — "After Session Ends" steps 2-4 prose explanations:
  The numbered steps already say what to do. The sub-explanations add nothing.
```

### Estimated Savings

| File | Before | After | Saved |
|------|--------|-------|-------|
| task-plan.md | 1,618 | ~900 | ~718 |
| task-create.md | 1,194 | ~700 | ~494 |
| task-execute.md | 1,111 | ~650 | ~461 |
| task-clarify.md | 582 | ~350 | ~232 |
| Other commands | 4,385 | ~3,500 | ~885 |
| **Total** | **8,890** | **~6,100** | **~2,790** |

---

## Strategy 3: Deduplicate Shared Patterns [DONE]

### Problem

Multiple agents repeat the same logic patterns:

1. **"Read state.yml, read PRD, read plan"** — appears in task-executor, task-verificator, plan-verificator, constraint-tracker, localization-agent (5 agents).
2. **Quality command discovery** — "Check package.json scripts, Makefile, CLAUDE.md" appears in task-executor, task-verificator, task-plan (3 files).
3. **Constraint checking** — "Read invariants, read decision-derived, check violations" appears in task-executor, constraint-tracker, task-verificator (3 files).
4. **Severity levels table** — identical 4-row table appears in constraint-tracker, phase-reviewer, all 3 verification files (5 files).

### Fix

Create `.claude/references/shared-patterns.md` containing these shared blocks. Each agent references the section it needs.

```markdown
# Shared Patterns Reference

## Task Context Loading
Read state.yml → extract active_task, task_path, status, phase_files, 
verification_mode, constraints. Read prd.md for requirements. Read plan.md 
for progress. Read phase files from phase_files list in state.yml.

## Quality Command Discovery
Discover quality commands from: package.json scripts (lint, type-check, 
test, build), Makefile targets, CLAUDE.md specified commands, phase file 
Quality Checks section. Run all discovered commands.

## Constraint Check Protocol
Read state.yml constraints (invariants + decisions + discovered). For 
each constraint, verify implementation respects it. If violation found: 
report severity (CRITICAL=invariant violated, HIGH=decision violated, 
MEDIUM=partial, LOW=minor), file, issue, and required fix.

## Severity Levels
CRITICAL (blocks release) → fix immediately
HIGH (significant issue) → fix before proceeding
MEDIUM (moderate concern) → warn, fix in current sprint
LOW (minor) → info, address when possible
```

Then in each agent, replace the duplicated blocks with:

```markdown
Follow the constraint check protocol from `.claude/references/shared-patterns.md#constraint-check`.
```

### Estimated Savings

~50-80 tokens per dedup × ~15 instances = **~750-1,200 tokens saved** across all agents.

---

## Strategy 4: Convert Example Output Blocks to Descriptions

### Problem

Commands like `task-constraints`, `task-checkpoint`, `task-complete` show full example CLI output in fenced blocks. Claude can generate formatted output without seeing the exact format.

### Files Affected

| File | Example Output Lines | Action |
|------|---------------------|--------|
| `commands/task-constraints.md` | ~40 lines of example outputs | Replace with field lists |
| `commands/task-checkpoint.md` | ~25 lines | Replace with field lists |
| `commands/task-complete.md` | ~20 lines | Replace with field lists |
| `commands/task-update-docs.md` | ~35 lines | Replace with field lists |

### Example Fix

**Before** (`task-constraints.md` — list command output, 15 lines):

```markdown
Output:
\```
Constraints for task: <task-name>

Invariants (Must Never Change):
| ID | Constraint | Added |
|----|------------|-------|
| I1 | All API calls must be authenticated | 2024-01-15 |

Decision-Derived:
| ID | From | Constraint | Added |
|----|------|------------|-------|
| D1-1 | D1 | Must use OAuth2, not custom auth | 2024-01-15 |
\```
```

**After** (2 lines):

```markdown
Output: Display invariants table (ID, constraint, date) and decision-derived table (ID, source decision, constraint, date).
```

### Estimated Savings

**~400-600 tokens** across the affected commands.

---

## Strategy 5: Lazy-Load Verification Checklists

### Problem

The three verification files (`verification/quality.md`, `security.md`, `performance.md`) total ~2,100 tokens. They're only needed during deep verification but could be loaded into context by agent descriptions or eager reading.

### Fix

These files should only be read by `task-verificator` when `mode=deep`. Add to the agent instruction:

```markdown
**Deep mode only:** Read `.claude/verification/quality.md`, `security.md`, 
and `performance.md` for checklist items. Do not load these in standard mode.
```

This is already roughly the case, but make the lazy-load explicit in the verificator agent. Also ensure no command or skill description references these files in a way that triggers eager loading.

### Estimated Savings

**~2,100 tokens** kept out of context during normal operations (already partially the case, but worth enforcing).

---

## New File Structure

After applying all strategies, create these new reference files:

```
.claude/
├── agents/                          # Trimmed agent instructions
│   ├── constraint-tracker.md        # 730 → ~450 tokens
│   ├── docs-initializer.md          # 764 → ~500 tokens
│   ├── docs-manager.md              # 988 → ~550 tokens
│   ├── docs-researcher.md           # 717 → ~400 tokens
│   ├── localization-agent.md        # 481 → ~300 tokens
│   ├── phase-reviewer.md            # 525 → ~350 tokens
│   ├── plan-verificator.md          # 715 → ~450 tokens
│   ├── task-executor.md             # 1275 → ~800 tokens
│   └── task-verificator.md          # 599 → ~380 tokens
├── commands/                        # Trimmed commands
│   ├── task-create.md               # 1194 → ~700 tokens
│   ├── task-plan.md                 # 1618 → ~900 tokens
│   ├── task-execute.md              # 1111 → ~650 tokens
│   ├── task-clarify.md              # 582 → ~350 tokens
│   └── ... (other commands trimmed proportionally)
├── references/                      # NEW — extracted templates
│   ├── report-formats.md            # All report templates in one place
│   ├── prd-templates.md             # Full + Quick PRD templates
│   ├── plan-templates.md            # plan.md + phase file templates
│   └── shared-patterns.md           # Deduplicated shared logic
├── skills/                          # Unchanged (already reference-based)
├── verification/                    # Unchanged (lazy-loaded)
└── hooks/
    └── inject-task-context.sh       # Unchanged
```

---

## Projected Totals

| Category | Before | After | Reduction |
|----------|--------|-------|-----------|
| Commands | ~8,890 | ~5,600 | -37% |
| Agents | ~6,796 | ~4,180 | -38% |
| References (NEW) | 0 | ~2,000 | (moved, not added) |
| Skills | ~13,165 | ~13,165 | 0% (already lazy) |
| Verification | ~2,102 | ~2,102 | 0% (lazy-loaded) |
| Hook | ~408 | ~408 | 0% |
| **Active context** | **~15,686** | **~9,780** | **-38%** |

"Active context" = commands + agents (what loads during operations). Reference files load only when agents explicitly read them to produce output.

**Per-operation impact:**

| Operation | Before | After | Reduction |
|-----------|--------|-------|-----------|
| `/task-execute` chain | ~3,700 | ~2,280 | -38% |
| `/task-plan` chain | ~2,814 | ~1,650 | -41% |
| `/task-create` | ~1,194 | ~700 | -41% |
| `/task-clarify` | ~582 | ~350 | -40% |

---

## Implementation Priority

1. **Do first** (highest impact, lowest effort):
   - Trim `task-plan.md` — remove duplicate rules, compress templates
   - Trim `task-executor.md` — remove inline report template
   - Trim `task-execute.md` — remove duplicated agent instructions
   - Trim `task-create.md` — extract PRD templates to reference file

2. **Do second** (medium impact):
   - Create `references/report-formats.md` and extract all agent report templates
   - Create `references/shared-patterns.md` and deduplicate

3. **Do third** (polish):
   - Trim remaining commands (checkpoint, constraints, complete, verify)
   - Trim docs-* agents
   - Verify lazy-loading of verification checklists

---

## Validation

After trimming, verify each file still works by running through a test task:

```
/task-create test-context-reduction Fix the login button color --quick
/task-execute
```

Check that:

- Plans generate correctly (proper format without inline template)
- Reports generate correctly (agent reads reference file when needed)  
- Quality checks still run
- Handoffs still generate

If an agent produces malformed output, the reference file needs more detail — but start minimal and add only what's proven necessary.

---

## Key Principle

> **Claude doesn't need to see the output format to produce good output.**
> It needs to know: what information to include, where to write it, and what decision to make.
> Report templates are training wheels — remove them and add back only where Claude consistently fails.
