#!/usr/bin/env bash
# =============================================================================
# Task Workflow Installer for Claude Code
# =============================================================================
# Usage: bash install-task-workflow.sh
# Run from the root of your project repository.
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[install]${NC} $1"; }
info() { echo -e "${BLUE}[info]${NC}   $1"; }
warn() { echo -e "${YELLOW}[warn]${NC}   $1"; }

# ─────────────────────────────────────────────
# 1. Directories
# ─────────────────────────────────────────────
log "Creating directory structure..."
mkdir -p .claude/commands
mkdir -p .claude/agents
mkdir -p .claude/hooks
mkdir -p .temp/tasks

# ─────────────────────────────────────────────
# 2. Commands
# ─────────────────────────────────────────────

log "Writing commands..."

# ── task-create ──────────────────────────────
cat > .claude/commands/task-create.md << 'HEREDOC'
# /task-create

Create a new task. Usage: `/task-create <task-name> <brief description>`

## Steps

1. Parse `$ARGUMENTS`: first word is `<task-name>` (slugified, lowercase, hyphens), remainder is the description.
2. Create directory `.temp/tasks/<task-name>/`.
3. Analyze the user's description carefully. Generate `.temp/tasks/<task-name>/prd.md` using the structure below.
4. Write `.temp/tasks/state.yml` with active task info.
5. Confirm to the user with a summary and suggest running `/task-clarify` next.

## PRD Structure

```markdown
# PRD: <task-name>

**Status:** Draft
**Created:** <today's date>
**Last Updated:** <today's date>

## 1. Overview
[Synthesize user's description into a clear problem statement]

## 2. Goals
[Primary and secondary goals inferred from the brief]

## 3. Functional Requirements
### 3.1 Core Features
[Concrete requirements inferred from the brief]
### 3.2 Edge Cases & Error Handling
[Any edge cases that are implied or obvious]

## 4. Non-Functional Requirements
[Performance, security, accessibility — infer what's relevant]

## 5. Technical Considerations
[Known patterns, dependencies, constraints — leave blank if none known yet]

## 6. Out of Scope
[Things explicitly or implicitly NOT included]

## 7. Gaps & Ambiguities
[Things the user did NOT mention but that will need decisions. Be thorough here — this is critical for the clarification step.]

## 8. Open Questions
[Questions that must be answered before implementation can start]

## 9. Additional Context
[Reserved — populated by /task-add-context]
```

## state.yml Structure

```yaml
active_task: <task-name>
created_at: <ISO date>
updated_at: <ISO date>
status: draft
task_path: .temp/tasks/<task-name>
prd: .temp/tasks/<task-name>/prd.md
plan: .temp/tasks/<task-name>/plan.md
context: .temp/tasks/<task-name>/context.md
```
HEREDOC

# ── task-clarify ─────────────────────────────
cat > .claude/commands/task-clarify.md << 'HEREDOC'
# /task-clarify

Run a structured clarification session for the active task.

## Steps

1. Read `.temp/tasks/state.yml` to identify the active task.
2. Read the task's `prd.md` file.
3. Check `$ARGUMENTS`:
   - If user specified a number (e.g., `5`) — run exactly that many questions.
   - If user specified a topic (e.g., `auth flow`) — focus questions on that topic.
   - If no arguments — analyze the PRD's "Gaps & Ambiguities" and "Open Questions" sections and decide how many questions are needed (typically 3–8, scaled to complexity).
4. Run the clarification session using the format below.
5. After the final question, ask the user:
   > "That covers the key questions. Would you like another round of clarification, or shall I update the PRD with your answers?"

## Clarification Session Format

Use this exact format for each question. Ask questions one at a time — do NOT ask if the user wants to continue between questions; maintain a natural flow.

```markdown
## Question [N]: [Topic Name]

[1–2 sentences explaining why this decision matters for the PRD]

| Option | Description | Tradeoffs |
|--------|-------------|-----------|
| **A** | **[Short name]** — [Description] | [Pros/Cons] |
| **B** | **[Short name]** — [Description] | [Pros/Cons] |
| **C** | **[Short name]** — [Description] | [Pros/Cons] |
| **D** | **[Short name]** — [Description] | [Pros/Cons] |

---

**My Recommendation: Option [X]**

[2–3 sentences explaining reasoning, acknowledging tradeoffs]

---
```

Wait for the user's response before asking the next question. Accept:
- Single option: `B`
- Combination: `B + D`
- Modification: `B but without X`

After each answer, note it internally. Do NOT recap after every question — only summarize at the very end.

## After Session Ends

When the user says "update PRD" (or equivalent):
1. Rewrite `.temp/tasks/<n>/prd.md` incorporating all clarification answers directly into the relevant sections — update requirements, resolve ambiguities, fill gaps in place. Do not add change annotations, diff markers, or "previously X, now Y" notes. The document should read as if it was always written this way.
2. Update `updated_at` in `state.yml`.
3. Tell the user what changed and suggest `/task-add-context` or `/task-plan` next.
HEREDOC

# ── task-add-context ─────────────────────────
cat > .claude/commands/task-add-context.md << 'HEREDOC'
# /task-add-context

Add context to the active task from files, URLs, or auto-discovery.

## Steps

1. Read `.temp/tasks/state.yml` to identify the active task and task path.
2. Check `$ARGUMENTS`:
   - `files <paths>` — read specified files and extract relevant patterns/details.
   - `url <url>` — fetch and summarize the URL (API docs, specs, etc.).
   - `discover` — auto-scan the repository (see below).
   - No argument — ask the user what kind of context they want to add.
3. Gather the context.
4. Present a summary of what was gathered.
5. Ask:
   > "Would you like to add more context, or shall I incorporate this into the PRD?"

## Auto-Discovery (when `discover` is specified or chosen)

Scan the repository for:
- Coding patterns and conventions (component structure, naming, file layout)
- Reusable utilities, hooks, helpers relevant to the task
- Existing implementations of similar features
- Tech stack (read `package.json`, config files, etc.)
- Quality commands: check `package.json` scripts, `Makefile`, `CLAUDE.md`, `.claude/settings.json` for lint/test/build commands. Record these — executors will need them.

## Updating PRD

When user confirms, append to or update Section 9 (Additional Context) of the PRD:

```markdown
## 9. Additional Context

### [Source: files | url | discovery] — <date>
[Summarized relevant findings]
```

Update `updated_at` in `state.yml`.
HEREDOC

# ── task-plan ────────────────────────────────
cat > .claude/commands/task-plan.md << 'HEREDOC'
# /task-plan

Create a detailed implementation plan. NO code is implemented at this stage.

## Steps

1. Read `.temp/tasks/state.yml`.
2. Read `prd.md` and `context.md` (if exists).
3. Before generating the plan, ask:
   > "Any notes before I create the plan? (e.g., TDD approach, specific patterns to follow, phases to prioritize)"
   Wait for response (user can say "none" to skip).
4. Scan the repository for coding patterns, file structure, naming conventions.
5. Read `CLAUDE.md` for project-specific guidelines.
6. Generate `plan.md` (structure below).
7. Update `state.yml` status to `planned`.
8. Suggest `/task-execute` next.

## plan.md Structure

```markdown
# Implementation Plan: <task-name>

**Status:** Ready
**Created:** <date>
**Based on PRD:** <prd path>

## Overall Progress
- [ ] Phase 1: <name>
- [ ] Phase 2: <name>
- [ ] Phase N: <name>

---

## Phase 1: <Name>

**Goal:** [What this phase achieves]
**Dependencies:** [Any prior phases or external deps]

### Tasks
- [ ] 1.1 [Task name]
  - File: `path/to/file.ts`
  - What to do: [Detailed description]
  - Code approach:
    ```typescript
    // Write the actual code here — exact implementation, not pseudocode
    ```
- [ ] 1.2 [Task name]
  ...

### Quality Checks After This Phase
- [ ] [command from discovery, e.g., `npm run lint:fix`]
- [ ] [command, e.g., `npm run type-check`]
- [ ] [command, e.g., `npm run test`]

---

## Phase 2: <Name>
...
```

### Key Rules for Plan Generation
- Write actual code in the plan — not pseudocode, not sketches. Executors implement by copying from this plan.
- Every file change must specify the exact file path.
- Quality checks must list the actual commands discovered from the project.
- If TDD was requested: each phase must list failing test code first, then implementation code.
HEREDOC

# rewrite task-plan with format selection
cat > .claude/commands/task-plan.md << 'HEREDOC'
# /task-plan

Create a detailed implementation plan. NO code is implemented at this stage.

## Steps

1. Read `.temp/tasks/state.yml`.
2. Read `prd.md` and `context.md` (if exists).
3. Scan the repository for coding patterns, file structure, naming conventions.
4. Read `CLAUDE.md` for project-specific guidelines.
5. **Analyze complexity and suggest a plan format** (see Plan Format Selection below).
6. Wait for the user to pick a format.
7. Ask:
   > "Any notes before I write the plan? (e.g., TDD approach, specific patterns to follow, phases to prioritize)"
   Wait for response (user can say "none" to skip).
8. Generate `plan.md` using the chosen format (see Plan Format Specs below).
9. Store the chosen format in `state.yml` as `plan_format`.
10. Update `state.yml` status to `planned`.
11. Suggest `/task-execute` next.

---

## Plan Format Selection

Before writing anything, analyze the PRD and codebase, then present this to the user:

```markdown
## Plan Format

I've analyzed the task. Here's my assessment:

**Complexity signals:**
- [e.g., "Touches 8+ files across 3 layers — high integration surface"]
- [e.g., "2 external APIs with undocumented edge cases"]
- [e.g., "Mostly CRUD scaffolding — mechanical and low-risk"]

**My recommendation: [Format name]**
[2–3 sentences explaining why this format fits the task complexity and risk profile]

| Format | Description | Best for |
|--------|-------------|----------|
| **A — Full code** | Every task contains complete, ready-to-run implementation code | Small, well-scoped tasks; isolated utilities; low ambiguity |
| **B — Detailed todos** | Each task has thorough description of what, why, constraints, patterns — no code | Large features; complex integrations; anything touching many files |
| **C — Hybrid** | Per-phase decision: mechanical phases get full code, complex logic phases get detailed todos | Most real-world features |
| **D — Skeleton + signatures** | Function/component signatures and interfaces only; bodies described not written | When type contracts must be locked in early |
| **B+D — Todos with signatures** | Detailed todos plus typed signatures — no implementation bodies | Large tasks where type safety matters from the start |

What format would you like? (A, B, C, D, or B+D)
```

Wait for the user's choice. Accept single options or combinations.
Record the chosen format in `state.yml` as `plan_format`.

---

## Plan Format Specs

All formats share the same outer structure. The **task block** content differs per format.

### Shared Outer Structure

```markdown
# Implementation Plan: <task-name>

**Status:** Ready
**Created:** <date>
**Based on PRD:** <prd path>
**Plan Format:** <A | B | C | D | B+D>

## Overall Progress
- [ ] Phase 1: <name>
- [ ] Phase 2: <name>
- [ ] Phase N: <name>

---

## Phase N: <name>

**Goal:** [What this phase achieves]
**Format:** <Full code | Detailed todos | Hybrid — [which phases get what] | Skeleton | Todos+Signatures>
**Dependencies:** [Prior phases or external deps, or "None"]

### Tasks
[Task blocks — format depends on chosen format, see specs below]

### Quality Checks After This Phase
- [ ] [e.g., `npm run lint:fix`]
- [ ] [e.g., `npm run type-check`]
- [ ] [e.g., `npm run test`]
```

---

### Format A — Full Code

```markdown
- [ ] N.N [Task name]
  - **File:** `path/to/file.ts`
  - **Action:** create | modify | delete
  - **What:** [One sentence summary]
  - **Implementation:**
    ```typescript
    // Complete, working implementation — not pseudocode
    // Include imports, error handling, edge cases
    ```
```

---

### Format B — Detailed Todos

```markdown
- [ ] N.N [Task name]
  - **File:** `path/to/file.ts`
  - **Action:** create | modify | delete
  - **What:** [Clear description of what needs to be built]
  - **Why:** [How this fits into the phase goal and overall task]
  - **Constraints:**
    - [e.g., "Must use existing `useAuth` hook, not create a new one"]
    - [e.g., "Return type must match `ApiResponse<T>` generic"]
  - **Patterns to follow:** [Reference to existing file, e.g., "Follow `src/hooks/useUser.ts`"]
  - **Edge cases to handle:**
    - [e.g., "Empty array response — return empty state, not error"]
    - [e.g., "Network timeout — surface user-facing message"]
  - **Do NOT:** [Anything the executor must avoid]
```

---

### Format C — Hybrid

Apply Format A or B per phase based on complexity.
Each phase must declare its format in the `**Format:**` header.

Typical split:
- Scaffolding, config, file creation → Format A (mechanical, low risk)
- Business logic, integrations, state → Format B (complex, needs reasoning)

---

### Format D — Skeleton + Signatures

```markdown
- [ ] N.N [Task name]
  - **File:** `path/to/file.ts`
  - **Action:** create | modify | delete
  - **Interfaces / Types:**
    ```typescript
    export interface TokenPayload {
      userId: string;
      role: UserRole;
    }
    ```
  - **Signatures:**
    ```typescript
    export async function signToken(payload: TokenPayload, expiresIn?: string): Promise<string>
    export async function verifyToken(token: string): Promise<TokenPayload | null>
    ```
  - **Implementation notes:** [What the body should do — prose, no code]
  - **Edge cases:** [List]
```

---

### Format B+D — Todos with Signatures

Combine Format B and Format D: full detailed todos AND typed signatures. No implementation bodies.

```markdown
- [ ] N.N [Task name]
  - **File:** `path/to/file.ts`
  - **Action:** create | modify | delete
  - **Interfaces / Types:**
    ```typescript
    // All types this task introduces or depends on
    ```
  - **Signatures:**
    ```typescript
    // All function/component signatures — no bodies
    ```
  - **What:** [Clear description]
  - **Why:** [Context]
  - **Constraints:** [List]
  - **Patterns to follow:** [Reference]
  - **Edge cases:** [List]
  - **Do NOT:** [Restrictions]
```

---

## Key Rules

- Every task must specify exact file path and action (create / modify / delete).
- Quality checks must list commands actually discovered from the project.
- If TDD was requested: each phase lists failing test signatures/stubs first, then implementation tasks.
- Format C: always declare the format in each phase header so executors know how to interpret tasks.
- Always write `plan_format` to `state.yml` — executor agents read it to know how to work with the plan.
HEREDOC

# ── task-execute ─────────────────────────────
cat > .claude/commands/task-execute.md << 'HEREDOC'
# /task-execute

Execute the implementation plan by spawning executor agents.

## Steps

1. Read `.temp/tasks/state.yml`.
2. Read `plan.md` — identify all phases and their status.
3. Ask the user:

   > **What would you like to execute?**
   > - `all` — all phases
   > - `phase <N>` — a specific phase
   > - `phases <N,M>` — specific phases

   Then ask:

   > **How should phases run?**
   > - `parallel` — all selected phases simultaneously (independent phases only)
   > - `sequential` — one after another in order

4. Spawn executor agents using the Task tool based on the choice.
5. After all executors complete, automatically spawn the **Verificator agent**.
6. Report final status to user.

## Executor Agent Instructions (pass to each Task invocation)

```
You are an Executor agent for task: <task-name>, Phase <N>: <phase-name>.

Read the full implementation plan at: <plan.md path>
Implement ONLY Phase <N>. Do not touch other phases.

After implementation:
1. Discover quality commands: check `package.json` scripts, `Makefile`, `CLAUDE.md`, `.claude/settings.json` — look for lint, type-check, test commands.
2. Run all discovered quality commands. Fix any errors before finishing.
3. Mark Phase <N> tasks as complete in plan.md (change `- [ ]` to `- [x]`).

Do NOT implement anything outside Phase <N>.
```

## Parallel vs Sequential

- **Parallel**: Use multiple simultaneous Task tool calls. Only safe when phases have no dependencies on each other.
- **Sequential**: Await each Task tool call before starting the next.

## Verificator

After all executors finish, spawn the Verificator agent (see `.claude/agents/verificator.md`).
Pass it: task name, plan.md path, list of phase summaries.
HEREDOC

# ── task-verify ──────────────────────────────
cat > .claude/commands/task-verify.md << 'HEREDOC'
# /task-verify

Verify quality at a specific stage. Usage: `/task-verify <prd|plan|code>`

## Steps

1. Read `.temp/tasks/state.yml`.
2. Parse `$ARGUMENTS` to determine verification type.

## Verification Types

### `prd`
Check PRD quality:
- Does it have clear, unambiguous requirements?
- Are all gaps and ambiguities addressed?
- Is it consistent with the project's existing features and patterns?
- Are non-functional requirements realistic?
- Produce a gap report with actionable suggestions.

### `plan`
Check plan quality against the PRD:
- Does the plan cover all functional requirements?
- Are the phases logically ordered with correct dependencies?
- Is the code in the plan consistent with repo patterns and conventions?
- Are quality checks defined for each phase?
- Produce a coverage report.

### `code`
Check implementation quality:
- Discover and run all quality commands (`package.json`, `Makefile`, `CLAUDE.md`).
- Compare implemented code against `plan.md` — flag any deviations.
- Check adherence to coding guidelines from `CLAUDE.md`.
- Produce a verification report at `.temp/tasks/<name>/verify-report.md`.

## Output

Always produce a structured report:
```markdown
# Verification Report: <type> — <task-name>
**Date:** <date>
**Result:** PASS | PARTIAL | FAIL

## Issues Found
| # | Severity | Location | Issue | Recommendation |
|---|----------|----------|-------|----------------|

## Summary
[Brief overall assessment]
```
HEREDOC

# ── task-update-docs ─────────────────────────
cat > .claude/commands/task-update-docs.md << 'HEREDOC'
# /task-update-docs

Discover documentation locations and update them based on the completed task.

## Steps

1. Read `.temp/tasks/state.yml`, `prd.md`, and `plan.md`.
2. Discover documentation locations:
   - Check `README.md` in root and subdirectories
   - Check `CLAUDE.md` for doc references
   - Check `docs/` directory if present
   - Check `prd.md` Section 9 (Additional Context) for any doc references mentioned
3. For each doc location found, assess: does this task's implementation change anything documented there?
4. Show the user a list of files that need updating and what needs to change.
5. Ask: "Shall I update all of these, or pick specific ones?"
6. Make the updates.
7. Summarize what was changed.
HEREDOC

# ── task-fix ─────────────────────────────────
cat > .claude/commands/task-fix.md << 'HEREDOC'
# /task-fix

Ad-hoc fix or enhancement in the context of the active task.

## Steps

1. Read `.temp/tasks/state.yml` to get active task context.
2. Read `prd.md` and `plan.md` (if they exist) — understand the task's intent.
3. Read `$ARGUMENTS` — this is the user's description of what to fix or enhance.
4. If arguments are empty, ask:
   > "What would you like to fix or change? (describe the issue, paste an error, or describe the enhancement)"
5. Analyze the issue in context of the task's PRD and plan.
6. Implement the fix or enhancement.
7. Run discovered quality commands to verify the fix doesn't break anything.
8. If the fix changes something significant, offer to update `plan.md` to reflect it.

## Notes
- This command is intentionally open-ended — it's the escape hatch for anything not covered by other commands.
- Always operate within the task's context: respect the PRD's goals and the plan's approach.
- For errors: read the full error message, trace it to the source, fix root cause — not symptoms.
HEREDOC

# ── task-run ──────────────────────────────────
cat > .claude/commands/task-run.md << 'HEREDOC'
# /task-run

Generic task-scoped command. Loads full task context, then executes whatever the user asks.

Usage: `/task-run <anything>`

Examples:
- `/task-run update the README to reflect the new auth flow`
- `/task-run refactor the token utilities to use a class instead of standalone functions`
- `/task-run check if plan phase 2 is still consistent with the PRD after the last clarification`
- `/task-run add JSDoc to all exported functions in src/lib/jwt.ts`
- `/task-run the build is failing with TS2345 — investigate and fix`

## Steps

1. Read `.temp/tasks/state.yml` — load active task name, status, and paths.
2. Read `prd.md` and `plan.md` (if they exist) — understand task intent, requirements, and current implementation plan.
3. Read `$ARGUMENTS` — this is the full instruction. Execute it exactly as described.
4. Use any tools needed: read files, write files, run commands, search the codebase — whatever the instruction requires.
5. After completing, briefly summarize what was done. If any files were modified that relate to the plan or PRD, offer to update them to stay consistent.

## Notes

- No assumed intent — do exactly what the instruction says, nothing more.
- Task context (PRD, plan) is loaded so actions stay coherent with the overall task, but it does not constrain what you can do.
- If `$ARGUMENTS` is empty, ask: "What would you like to do?"
HEREDOC

# ─────────────────────────────────────────────
# 3. Agents
# ─────────────────────────────────────────────

log "Writing agents..."

cat > .claude/agents/executor.md << 'HEREDOC'
---
name: executor
description: Implements a specific phase of a task plan. Spawned by /task-execute.
---

# Executor Agent

You are an Executor. You implement exactly one phase of a task plan — nothing more.

## Inputs (provided when you are spawned)

- `task_name`: the task you are implementing
- `phase_number`: which phase to implement
- `plan_path`: path to the full `plan.md`
- `prd_path`: path to `prd.md` (for reference)

## Instructions

1. Read the full `plan.md`. Understand all phases but implement **only your assigned phase**.
2. Read `state.yml` to determine `plan_format` — this controls how you interpret the plan.
3. Read `prd.md` to understand intent and constraints.
4. Implement every task in your phase according to the plan format:

### How to implement based on plan_format

**Format A (Full code)**
The plan contains complete implementation code. Use it directly.
Adapt only if it conflicts with the actual file structure on disk.

**Format B (Detailed todos)**
The plan contains descriptions, constraints, patterns, and edge cases — no code.
You must write the implementation yourself, guided strictly by each task's details.
Read the referenced pattern files. Respect every constraint. Handle every listed edge case.
Do not invent scope not described in the task.

**Format C (Hybrid)**
Check each phase's `**Format:**` header — it will say "Full code" or "Detailed todos".
Apply Format A or Format B rules accordingly per phase.

**Format D (Skeleton + signatures)**
The plan provides interfaces and function signatures.
Implement the bodies based on the implementation notes provided.
The signatures are contracts — do not change them.

**Format B+D (Todos with signatures)**
Combine Format B and D rules: respect the signatures as contracts, implement
bodies guided by the detailed todo descriptions. Do not change signatures.

5. After implementation, discover quality commands:
   - Check `package.json` → `scripts` for lint, type-check, test, build
   - Check `Makefile` for targets
   - Check `CLAUDE.md` for specified commands
6. Run all discovered quality commands. If any fail:
   - Fix the errors.
   - Re-run until all pass.
7. Update `plan.md` checkboxes — this is mandatory, not optional:
   - For every task you implemented in your phase: change `- [ ]` to `- [x]`
   - Mark the phase entry in the Overall Progress list: change `- [ ]` to `- [x]`
   - Edit the file directly using a write tool. Verify the changes are saved before finishing.

## Hard Rules
- Do NOT implement code from other phases.
- Do NOT skip quality checks.
- Do NOT mark tasks complete if quality checks are still failing.
- For Format B/D/B+D: do not add scope not described in the plan. If something is unclear, implement the minimal interpretation.
HEREDOC

cat > .claude/agents/verificator.md << 'HEREDOC'
---
name: verificator
description: Verifies the full implementation after all executor agents complete. Spawned by /task-execute.
---

# Verificator Agent

You verify that the implementation is complete, correct, and meets quality standards.

## Inputs (provided when you are spawned)

- `task_name`: the task being verified
- `plan_path`: path to `plan.md`
- `prd_path`: path to `prd.md`

## Instructions

1. Read `prd.md` — understand all requirements.
2. Read `plan.md` — understand all phases and tasks. Verify which tasks are marked `- [x]` (complete) vs `- [ ]` (incomplete).
3. Verify implementation:

   **a. Completeness** — Is every planned task marked complete? Are all files created/modified?

   **b. Correctness** — Does the implementation match the plan? Read the actual files and compare.

   **c. PRD compliance** — Does the implementation satisfy all functional and non-functional requirements?

   **d. Quality** — Discover and run all quality commands (same discovery process as executors). All must pass.

   **e. Coding standards** — Read `CLAUDE.md` for guidelines. Check that implementation follows them.

5. Write a verification report to `.temp/tasks/<task_name>/verify-report.md`:

```markdown
# Verification Report: <task-name>

**Date:** <date>
**Verificator result:** PASS | PARTIAL | FAIL

## Completeness
| Phase | Tasks | Complete | Issues |
|-------|-------|----------|--------|

## Quality Commands
| Command | Result | Notes |
|---------|--------|-------|

## PRD Compliance
| Requirement | Status | Notes |
|-------------|--------|-------|

## Issues Found
| # | Severity | File | Issue | Recommendation |
|---|----------|------|-------|----------------|

## Summary
[Overall assessment. If FAIL or PARTIAL — clear next steps for the user.]
```

6. Report the result to the user clearly. If issues exist, prioritize them by severity.
HEREDOC

# ─────────────────────────────────────────────
# 4. Hook
# ─────────────────────────────────────────────

log "Writing hook..."

cat > .claude/hooks/inject-task-context.sh << 'HEREDOC'
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

if [[ -z "$active_task" || "$active_task" == "null" || "$active_task" == "none" ]]; then
  exit 0
fi

# Emit banner to stderr (visible in terminal, not sent to Claude)
echo "📌 Active task: $active_task (status: $status)" >&2

# Emit context injection as JSON to stdout (Claude Code reads this)
cat <<JSON
{
  "additionalContext": "ACTIVE TASK CONTEXT:\n- Task: ${active_task}\n- Status: ${status}\n- Path: ${task_path}\n- PRD: ${task_path}/prd.md\n- Plan: ${task_path}/plan.md\n- Context: ${task_path}/context.md\n\nAlways read state.yml and relevant task files before acting on any /task-* command."
}
JSON
HEREDOC
chmod +x .claude/hooks/inject-task-context.sh

# ─────────────────────────────────────────────
# 5. settings.json — register hook
# ─────────────────────────────────────────────

log "Configuring .claude/settings.json..."

SETTINGS=".claude/settings.json"

if [[ -f "$SETTINGS" ]]; then
  # Merge hook into existing settings using Python (available on most systems)
  python3 - << 'PYEOF'
import json, sys

with open(".claude/settings.json", "r") as f:
    settings = json.load(f)

hook_entry = {
    "matcher": "",
    "hooks": [
        {
            "type": "command",
            "command": "bash \"$PWD/.claude/hooks/inject-task-context.sh\""
        }
    ]
}

if "hooks" not in settings:
    settings["hooks"] = {}

if "UserPromptSubmit" not in settings["hooks"]:
    settings["hooks"]["UserPromptSubmit"] = []

# Avoid duplicate
existing_cmds = [
    h["command"]
    for entry in settings["hooks"]["UserPromptSubmit"]
    for h in entry.get("hooks", [])
]
if not any("inject-task-context" in cmd for cmd in existing_cmds):
    settings["hooks"]["UserPromptSubmit"].append(hook_entry)

with open(".claude/settings.json", "w") as f:
    json.dump(settings, f, indent=2)

print("Hook merged into existing settings.json")
PYEOF
else
  cat > "$SETTINGS" << 'HEREDOC'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$PWD/.claude/hooks/inject-task-context.sh\""
          }
        ]
      }
    ]
  }
}
HEREDOC
  info "Created new settings.json with hook"
fi

# ─────────────────────────────────────────────
# 6. CLAUDE.md — append workflow section
# ─────────────────────────────────────────────

log "Configuring CLAUDE.md..."

WORKFLOW_SECTION='

---

## Task Workflow

This project uses a structured task workflow. Active task context is injected automatically at session start.

### Commands

| Command | Purpose |
|---------|---------|
| `/task-create <name> <description>` | Create a new task with a PRD |
| `/task-clarify [N questions] [topic]` | Run structured clarification Q&A on active task |
| `/task-add-context [files\|url\|discover]` | Add context from files, URLs, or repo scan |
| `/task-plan` | Generate detailed implementation plan (no code runs yet) |
| `/task-execute [all\|phase N\|phases N,M]` | Execute plan via agents (parallel or sequential) |
| `/task-verify <prd\|plan\|code>` | Verify quality at a specific stage |
| `/task-update-docs` | Update project documentation based on implementation |
| `/task-fix [description]` | Ad-hoc fix or enhancement in task context |
| `/task-run <anything>` | Generic task-scoped freeform command |

### State

Active task state lives in `.temp/tasks/state.yml`.
All task artifacts are in `.temp/tasks/<task-name>/`.

### Project Quality Commands

<!-- Override this section per project -->
<!-- The AI will auto-discover from package.json / Makefile if not specified -->
<!-- Example:
quality_commands:
  - npm run lint:fix
  - npm run type-check
  - npm run test
-->

### Coding Guidelines

<!-- Add project-specific coding guidelines here -->
<!-- Agents and plan generation will read this section -->
'

if [[ -f "CLAUDE.md" ]]; then
  if grep -q "## Task Workflow" "CLAUDE.md"; then
    warn "CLAUDE.md already contains Task Workflow section — skipping."
  else
    echo "$WORKFLOW_SECTION" >> CLAUDE.md
    info "Appended Task Workflow section to existing CLAUDE.md"
  fi
else
  cat > CLAUDE.md << 'HEREDOC'
# Project Guidelines
HEREDOC
  echo "$WORKFLOW_SECTION" >> CLAUDE.md
  info "Created CLAUDE.md with Task Workflow section"
fi

# ─────────────────────────────────────────────
# 7. .gitignore — exclude .temp
# ─────────────────────────────────────────────

log "Updating .gitignore..."

if [[ -f ".gitignore" ]]; then
  if ! grep -q "^\.temp" ".gitignore"; then
    echo -e "\n# Task workflow temp files\n.temp/" >> .gitignore
    info "Added .temp/ to .gitignore"
  else
    info ".temp/ already in .gitignore"
  fi
else
  printf "# Task workflow temp files\n.temp/\n" > .gitignore
  info "Created .gitignore with .temp/"
fi

# ─────────────────────────────────────────────
# 8. Initial state.yml
# ─────────────────────────────────────────────

if [[ ! -f ".temp/tasks/state.yml" ]]; then
  cat > .temp/tasks/state.yml << 'HEREDOC'
active_task: none
created_at: null
updated_at: null
status: idle
task_path: null
prd: null
plan: null
context: null
HEREDOC
  info "Created initial state.yml"
fi

# ─────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────

echo ""
echo -e "${GREEN}✅ Task workflow installed successfully!${NC}"
echo ""
echo "  Structure created:"
echo "  .claude/commands/   — task-create, task-clarify, task-add-context,"
echo "                        task-plan, task-execute, task-verify,"
echo "                        task-update-docs, task-fix, task-run"
echo "  .claude/agents/     — executor, verificator"
echo "  .claude/hooks/      — inject-task-context.sh (UserPromptSubmit)"
echo "  .claude/settings.json — hook registered"
echo "  CLAUDE.md           — workflow section added"
echo "  .temp/tasks/        — task artifacts (gitignored)"
echo ""
echo "  Next steps:"
echo "  1. Open Claude Code in this directory"
echo "  2. Run: /task-create my-feature your feature description here"
echo "  3. Follow the workflow from there"
echo ""
echo "  To customize quality commands or coding guidelines,"
echo "  edit the relevant sections in CLAUDE.md."
echo ""
