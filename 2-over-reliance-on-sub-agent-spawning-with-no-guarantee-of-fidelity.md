# Sub-Agent Fidelity Improvement Plan

## Current State

| Category | Tokens | Files |
|----------|--------|-------|
| Task Agents | 4,280 | 6 |
| Docs Agents | 2,846 | 3 |
| Reference Files | 3,994 | 2 |
| Spawning Commands | 2,341 | 3 |
| **Total** | **13,461** | **14** |

When `/task-execute` spawns a task-executor, the agent prompt (1,455 tokens) references `shared-patterns.md` (958 tokens) and `report-formats.md` (3,036 tokens). That's ~5,449 tokens of framework overhead before any task content loads. Sub-agents often skip these reads entirely, or load all 536 lines of report-formats.md to find one 20-line section.

**Target: Reduce per-agent framework overhead from ~5,400 to ~1,200 tokens (~78% reduction). Eliminate all external reference file dependencies from agent prompts.**

---

## Strategy Overview

Sub-agents can't reliably follow instructions that tell them to go read another file. The fix: inline the 2-3 critical rules each agent needs, replace verbose output format prescriptions with minimal checklists, and flatten nested phase hierarchies into linear steps.

| # | Strategy | Estimated Savings | Effort |
|---|----------|-------------------|--------|
| 1 | Inline critical protocols, eliminate reference reads | ~4,000 tokens/invocation | Medium |
| 2 | Replace output templates with must-include checklists | ~425 tokens across files | Low |
| 3 | Flatten multi-phase docs agent instructions | ~1,050 tokens across 3 files | Medium |
| 4 | Deduplicate constraint logic across agents | ~200 tokens across files | Low |
| 5 | Remove orchestration meta-info from agent files | ~200 tokens across files | Low |

---

## Strategy 1: Inline Critical Protocols, Eliminate Reference Reads

### Problem

Every agent prompt tells the sub-agent to read external reference files via lines like "Follow the task context loading protocol from `.claude/references/shared-patterns.md#task-context-loading`" and "See `.claude/references/report-formats.md#handoff-yaml` for the full template." Sub-agents often skip these reads, or load the entire file to find one section. This is the #1 fidelity risk: the agent prompt contains a pointer to critical information, but the agent may never load it.

### Files Affected

| File | Impact | Action |
|------|--------|--------|
| task-executor.md | 1,455 tokens | Rewrite: inline 3 protocols |
| plan-verificator.md | 662 tokens | Rewrite: inline context loading |
| task-verificator.md | 632 tokens | Rewrite: inline context loading |
| constraint-tracker.md | 637 tokens | Rewrite: inline context loading |
| localization-agent.md | 422 tokens | Rewrite: inline context loading |
| phase-reviewer.md | 472 tokens | Remove reference lines |

### Fix

**Before** (`task-executor.md` lines 21-28 — ~400 chars):

```markdown
1. Follow the task context loading protocol from `.claude/references/shared-patterns.md#task-context-loading`.
   Start with your assigned `plan-phase-N.md` (at `phase_file_path`) as primary source.
   You do NOT need to read other phase files unless checking a dependency.
   Check `verification_mode` from state.yml: if `per_phase`, run quality checks;
   if `final` or `none`, skip them during implementation.
2. **Pre-Implementation Constraint Check (MANDATORY):**
   Follow the constraint check protocol from `.claude/references/shared-patterns.md#constraint-check-protocol`.
   If ANY constraint would be violated: STOP and report to user before proceeding.
```

**After** (~180 chars):

```markdown
1. Read `state.yml` → extract `active_task`, `verification_mode`, `constraints`.
   Read your `plan-phase-N.md` (at `phase_file_path`) as primary source.
   Read `prd.md` for requirements and constraints.
2. **Constraint check (MANDATORY):** Read all constraints from `state.yml`.
   If ANY would be violated by your planned implementation: STOP and report.
```

**Before** (`constraint-tracker.md` lines 19-24 — ~200 chars):

```markdown
### Pre-Plan Stage
Verify that constraints are properly defined:
1. Read PRD Section 10 (Constraints)
2. Read state.yml constraints section
3. Check for inconsistencies
4. Report any missing constraints that should be derived from decisions
```

**After** (~100 chars):

```markdown
### Pre-Plan
1. Read PRD Section 10 and state.yml constraints section
2. Check for inconsistencies and missing constraints
3. Report findings
```

**Before** (`task-verificator.md` line 19 — ~150 chars):

```markdown
1. Follow the task context loading protocol from `.claude/references/shared-patterns.md#task-context-loading`.
   Specifically check: constraints section, `verification_mode`, and verify TODO completion in each `plan-phase-N.md`.
```

**After** (~100 chars):

```markdown
1. Read `state.yml` → extract constraints, verification_mode, phase_files.
   Read each `plan-phase-N.md` to check TODO completion.
```

### Estimated Savings

~4,000 tokens per agent invocation (reference files not loaded). **This is the single highest-impact change: guarantees the agent has all instructions without depending on external file reads.**

---

## Strategy 2: Replace Output Templates with Must-Include Checklists

### Problem

Agent prompts contain verbose output format descriptions that also reference external templates. Example: "Include: summary table (category/total/pass/fail/unchecked), invariant + decision-derived compliance with status+evidence, violations with severity/file/fix, recommendations, and verdict (PASS/FAIL/NEEDS_ATTENTION). See `.claude/references/report-formats.md#constraint-compliance` for the full template." This is both redundant and prescriptive — sub-agents drift on formatting regardless of how detailed the prescription is.

### Files Affected

| File | Impact | Action |
|------|--------|--------|
| task-executor.md | Handoff section (~100 tokens) | Replace with minimal list |
| plan-verificator.md | Output section (~50 tokens) | Replace with minimal list |
| phase-reviewer.md | Output section (~50 tokens) | Replace with minimal list |
| task-verificator.md | Output section (~38 tokens) | Replace with minimal list |
| constraint-tracker.md | Output section (~63 tokens) | Replace with minimal list |
| localization-agent.md | Output section (~38 tokens) | Replace with minimal list |

### Fix

**Before** (`task-executor.md` lines 104-113):

```markdown
### Handoff Generation (for sequential execution)

After completing your phase, generate a handoff file for the next phase:

**File:** `.temp/tasks/<task_name>/handoffs/phase-N-to-N+1.yml`
Include: files_modified with summaries, constraints_discovered, warnings_for_next_phase, quality_status (lint/type_check/tests/notes), and api_changes.
See `.claude/references/report-formats.md#handoff-yaml` for the full template.

If there is no next phase (this is the last phase), skip handoff generation.
```

**After**:

```markdown
### Handoff (if not last phase)

Write `.temp/tasks/<task_name>/handoffs/phase-N-to-N+1.yml`. Must include:
files_modified, constraints_discovered, warnings_for_next_phase, quality_status.
```

**Before** (`constraint-tracker.md` lines 63-65):

```markdown
Write a constraint compliance report to `.temp/tasks/<task_name>/constraint-report.md`.
Include: summary table (category/total/pass/fail/unchecked), invariant + decision-derived compliance with status+evidence, violations with severity/file/fix, recommendations, and verdict (PASS/FAIL/NEEDS_ATTENTION).
See `.claude/references/report-formats.md#constraint-compliance` for the full template.
```

**After**:

```markdown
Write `.temp/tasks/<task_name>/constraint-report.md`. Must include:
summary table, compliance status per constraint, violations, verdict (PASS/FAIL/NEEDS_ATTENTION).
```

### Estimated Savings

~50-100 tokens per file × 6 files = **~425 tokens saved across files**. Also eliminates the secondary fidelity risk of agents loading report-formats.md for template details.

---

## Strategy 3: Flatten Multi-Phase Docs Agent Instructions

### Problem

The three docs agents use "Phase 1/2/3/4" nested hierarchies: docs-initializer (117 lines), docs-manager (129 lines), docs-researcher (116 lines). Sub-agents follow flat numbered steps more reliably than nested phase hierarchies. Each "Phase N:" header adds navigation overhead and increases the chance the agent skips a phase or treats phases as optional.

### Files Affected

| File | Impact | Action |
|------|--------|--------|
| docs-initializer.md | 117 lines (~942 tokens) | Flatten to ~60 lines |
| docs-manager.md | 129 lines (~1,103 tokens) | Flatten to ~70 lines |
| docs-researcher.md | 116 lines (~801 tokens) | Flatten to ~55 lines |

### Fix

**Before** (`docs-researcher.md` lines 36-79 — ~1,400 chars):

```markdown
### Phase 1: Documentation Search

1. Search README.md:
   - Use Grep with case-insensitive search
   - Use -C 3 for surrounding context
   - Record file path, line number, and exact excerpt

2. Search ./docs/*.md:
   - Use Glob to find all .md files in ./docs/
   - Use Grep with case-insensitive search
   - Record all matches with context

3. For each match, record:
   - File path
   - Line number
   - Exact excerpt (quote directly)
   - Section heading (for context)

### Phase 2: Codebase Search (if scope allows)

Only proceed if documentation search yielded insufficient results AND scope is "docs-and-code".

1. Identify relevant file types based on query context
2. Search source files:
   - Use Grep with appropriate file type filters
   - Search for function definitions, class definitions
   - Search for comments and docstrings
3. Search configuration files:
   - Use Glob for *.{json,yaml,yml,toml,ini}
   - Search for relevant configuration keys
4. Search inline documentation:
   - JSDoc, docstrings, block comments

### Phase 3: Result Compilation

**If results found:**
Include: summary, sources tables (Documentation + Codebase with file/line/excerpt), related topics.
See `.claude/references/report-formats.md#research-results-found` for the full format.

**If NO results found:**
Include: result statement, locations searched, alternative search suggestions.
See `.claude/references/report-formats.md#research-results-not-found` for the full format.
```

**After** (~700 chars):

```markdown
## Instructions

1. Search README.md with Grep (case-insensitive, -C 3). Record: file, line, exact excerpt.
2. Search ./docs/*.md with Grep. Record all matches with context.
3. If scope is "docs-and-code" and results insufficient: search source files (Grep with type filters), config files (Glob for *.{json,yaml,yml,toml,ini}), inline docs (JSDoc, docstrings).
4. Break multi-word queries into individual terms and synonyms (e.g., "authentication" → also "auth", "login").
5. If results found: output summary, sources table (file/line/excerpt), related topics.
6. If no results: output "NO RESULTS for <query>", locations searched, alternative search suggestions.
```

### Estimated Savings

~350 tokens per file × 3 files = **~1,050 tokens saved**.

---

## Strategy 4: Deduplicate Constraint Logic Across Agents

### Problem

Constraint checking is independently described in 4 agents (task-executor, constraint-tracker, phase-reviewer, task-verificator). Each has its own description of what constraints are and how to check them. This creates inconsistency risk — when one description is updated, others may be missed.

### Files Affected

| File | Impact | Action |
|------|--------|--------|
| phase-reviewer.md | Constraint section (~50 tokens) | Reference constraint-tracker output |
| task-verificator.md | Constraint line (~25 tokens) | Reference constraint-tracker output |
| constraint-tracker.md | Constraint Categories (~100 tokens) | Keep as single source of truth |

### Fix

**Before** (`phase-reviewer.md` lines 48-52):

```markdown
### Constraints

- [ ] All invariants from PRD Section 10 are respected
- [ ] All decision-derived constraints are satisfied
- [ ] No violations of handoff warnings from previous phase
```

**After**:

```markdown
### Constraints

- [ ] No violations in constraint-report.md (if exists)
- [ ] Handoff warnings from previous phase addressed
```

**Before** (`task-verificator.md` line 37):

```markdown
   **f. Constraint compliance** — Verify all invariants and decision-derived constraints are respected.
```

**After**:

```markdown
   **f. Constraints** — Check constraint-report.md for violations. If none exists, verify from state.yml.
```

### Estimated Savings

~75 tokens × 2 files = **~150 tokens saved**.

---

## Strategy 5: Remove Orchestration Meta-Information

### Problem

Agent files contain sections describing when/how they are called. This is orchestration info for the spawning command, not instructions the sub-agent needs. Including it wastes context and may confuse the agent about its role.

### Files Affected

| File | Impact | Action |
|------|--------|--------|
| constraint-tracker.md | Integration Points (5 lines, ~100 tokens) | Remove |
| localization-agent.md | Integration section (4 lines, ~60 tokens) | Remove |
| plan-verificator.md | Exit Codes (4 lines, ~50 tokens) | Remove |

### Fix

**Before** (`constraint-tracker.md` lines 72-76):

```markdown
## Integration Points

1. **Pre-Plan**: Run after `/task-plan` to ensure constraints are traceable
2. **Post-Phase**: Run after each phase in `/task-execute` for continuous compliance
3. **Final**: Run as part of `/task-verify` for final audit
4. **On-Demand**: Run via `/task-constraints check` at any time
```

**After**: (section removed entirely)

**Before** (`localization-agent.md` lines 53-56):

```markdown
## Integration

This agent runs as "Phase 0" before implementation:
1. After `/task-plan` completes
2. Before `/task-execute` starts
3. Output informs orchestration strategy
```

**After**: (section removed entirely)

**Before** (`plan-verificator.md` lines 56-59):

```markdown
## Exit Codes

- **PASS**: All checks pass, proceed to execution
- **PARTIAL**: Some issues but non-blocking, warn user
- **FAIL**: Critical issues, block execution
```

**After**: (section removed — exit codes are self-evident from report content)

### Estimated Savings

~210 tokens × 3 files = **~200 tokens saved**.

---

## New File Structure

```
.claude/
├── agents/
│   ├── task-executor.md        # 1,455 → ~1,100 tokens
│   ├── plan-verificator.md     # 662 → ~450 tokens
│   ├── phase-reviewer.md       # 472 → ~350 tokens
│   ├── task-verificator.md     # 632 → ~450 tokens
│   ├── constraint-tracker.md   # 637 → ~480 tokens
│   ├── localization-agent.md   # 422 → ~320 tokens
│   ├── docs-initializer.md     # 942 → ~500 tokens
│   ├── docs-manager.md         # 1,103 → ~600 tokens
│   └── docs-researcher.md      # 801 → ~420 tokens
├── references/
│   ├── shared-patterns.md      # unchanged — fallback reference
│   └── report-formats.md       # unchanged — human reference only
```

---

## Projected Totals

| Category | Before | After | Reduction |
|----------|--------|-------|-----------|
| Task Agents (6 files) | 4,280 | 3,150 | -26% |
| Docs Agents (3 files) | 2,846 | 1,520 | -47% |
| Reference files loaded per invocation | 3,994 | 0 | -100% |
| **Per-agent framework overhead** | **~5,400** | **~1,200** | **-78%** |

| Operation | Before | After | Reduction |
|-----------|--------|-------|-----------|
| `/task-execute phase 1` (one executor) | ~5,400 | ~1,200 | -78% |
| `/task-execute all` (3 parallel executors) | ~16,200 | ~3,600 | -78% |
| `/project-docs add` (docs-manager) | ~5,100 | ~1,100 | -78% |

---

## Implementation Priority

1. **Do first** (highest fidelity impact, eliminates root cause):
   - Strategy 1: Inline critical protocols in all 9 agent files
   - Strategy 2: Strip output formatting to must-include checklists

2. **Do second** (medium impact, reduces agent complexity):
   - Strategy 3: Flatten docs agent instructions to linear steps

3. **Do third** (polish):
   - Strategy 4: Deduplicate constraint logic
   - Strategy 5: Remove orchestration meta-info

---

## Validation

After applying changes, verify by:

1. Run `bash -n .claude/hooks/inject-task-context.sh` — hook should parse correctly.
2. Create a test task: `/task-create test-fidelity --quick "Add a hello function"`
3. Execute: `/task-execute phase 1`
4. Check the output:
   - TODO items marked `[x]` in phase file
   - Handoff file created with required fields (files_modified, constraints_discovered, warnings_for_next_phase, quality_status)
   - No reference to missing format details
5. Compare agent behavior before/after — output should be functionally identical, formatting may vary.

If an agent fails to produce required output fields, add the missing item back as a single bullet in the must-include list for that agent.

---

## Key Principle

> A sub-agent that receives all critical instructions inline will always outperform one told to go find them in another file.
