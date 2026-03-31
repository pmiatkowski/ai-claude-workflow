# /task-create

Create a new task. Usage: `/task-create <task-name> <brief description> [--quick]`

Add `--quick` to skip clarification and planning questions. Generates a minimal PRD and single-phase plan with `verification_mode: none`, then suggests `/task-execute` immediately. Best for small, well-defined tasks (fixes, renames, small additions).

## Steps

1. Parse `$ARGUMENTS`:
   a. Detect `--quick` anywhere in the arguments string. If present, set QUICK_MODE=true and remove `--quick` from the string.
   b. From the remaining string: first word is `<task-name>` (slugified, lowercase, hyphens), remainder is the description.
   c. If QUICK_MODE is false, check the description against the Quick-Suggest Heuristic below. If it matches, mention to the user: "This looks like a quick task. Consider using `--quick` for a faster flow." Then proceed with the full flow unchanged.
2. Create directory `.temp/tasks/<task-name>/`.
3. Analyze the user's description carefully.
4. **Branch on QUICK_MODE:**
   - If false → follow the **Full Flow** below.
   - If true → follow the **Quick Flow** below.

---

## Full Flow

Generate `.temp/tasks/<task-name>/prd.md` using the Full PRD Template below.

Write `.temp/tasks/state.yml` using the state.yml Template below.

Confirm to the user with a summary and suggest running `/task-clarify` next.

### Full PRD Template

See `.claude/references/prd-templates.md#full-prd` for the full template.

### state.yml Template

Write `state.yml` with: `active_task`, `created_at`, `updated_at`, `status` (draft for full, planned for quick), `task_path`, `prd`, `plan`, `context` paths, and `constraints` (invariants/decisions/discovered arrays, initially empty). Quick mode also adds: `phase_files` list and `verification_mode: none`.

---

## Quick Flow

### Step A: Generate Quick PRD

See `.claude/references/prd-templates.md#quick-prd` for the template.

### Step B: Generate Plan Inline

Immediately generate the implementation plan without asking questions:

1. Scan the repository for coding patterns, file structure, and naming conventions.
2. Read `CLAUDE.md` for project-specific guidelines.
3. Generate a **single-phase plan** with these hardcoded defaults:
   - Phase split: single phase — one `plan-phase-1.md` with all TODOs
   - Verification mode: `none` — no Quality Checks sections, no Final Verification phase
4. Write `plan.md` (index) with: status Ready, PRD path, verification: none, Overall Progress (checkbox per phase), Dependency Graph, Phase Files list.
5. Write `plan-phase-1.md` with: goal (1-2 sentences), dependencies: None, file list with action (create/modify/delete), TODO list (verb-first single-line items, 3-10 typical). No Quality Checks section.

### Step C: Write state.yml

Use the state.yml Template above with quick-mode values: `status: planned`, include `phase_files` and `verification_mode: none`.

### Step D: Confirm

Report to the user:

> **Quick task created and planned.**
>
> PRD: `.temp/tasks/<task-name>/prd.md`
> Plan: `.temp/tasks/<task-name>/plan.md` (1 phase)
> Verification: none
>
> Run `/task-execute` to start implementation.

---

## Quick-Suggest Heuristic

When QUICK_MODE is false, check the description against these signals. If **2 or more** apply, suggest `--quick` to the user (but proceed with the full flow unless they re-run with the flag):

**Signals:** single sentence; small-task verbs (fix, typo, rename, update, bump, remove, add X to Y, refactor, adjust, tweak, revert, cleanup, move); specific file/function name; under 15 words; scope-limiting words (just, only, simply, quick, small).

**Do NOT suggest --quick if:** multiple requirements with "and"/"also"; multiple files/components; architecture/design-level work.
