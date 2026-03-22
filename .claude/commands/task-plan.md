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
8. **If Format S was chosen**, ask about quality check timing:
   > "For the Simplified format, when should quality checks (lint, test, etc.) run?"
   > 1. **After every phase** — Each phase executor runs quality checks before marking complete (safer, catches issues early)
   > 2. **After all phases complete** — Adds a Final Verification phase with all quality checks; runs once at the end (faster, but issues may compound)
   >
   > Which approach? (1 or 2)
   Store the choice in `state.yml` as `quality_check_mode: per_phase | final`.
9. Generate the plan using the chosen format (see Plan Format Specs below).
   - For formats A/B/C/D/B+D: generate a single `plan.md`.
   - For format S: generate an index `plan.md` plus individual `plan-phase-N.md` files in the task directory.
10. Store the chosen format in `state.yml` as `plan_format`. For format S, also write a `phase_files` list and `quality_check_mode` to `state.yml`.
11. Update `state.yml` status to `planned`.
12. **Optional: Run localization analysis**
    > "Would you like me to analyze file impact before execution? This helps identify potential conflicts. [yes/no]"
    If yes, spawn the localization-agent to generate `localization.md`.
13. Suggest `/task-execute` next.

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
| **S — Simplified** | Separate file per phase with clean TODO lists and dependency info; plan.md is an index | Any task size; focused executor context; dependency-heavy workflows |

What format would you like? (A, B, C, D, B+D, or S)
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
**Plan Format:** <A | B | C | D | B+D | S>

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
  - **Do NOT:** [Anything the task-executor must avoid]
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

### Format S — Simplified

Format S generates **separate files per phase** instead of a single monolithic plan. The main `plan.md` serves as an index only.

**Quality Check Modes:**
- `per_phase`: Quality checks section appears in each phase file. Task-executors run checks after completing their phase.
- `final`: No quality checks in phase files. A **Final Verification phase** is generated as the last phase containing all quality check TODOs. This phase runs after all implementation phases complete.

**When `quality_check_mode=final`:** Automatically generate a Final Verification phase as the last phase. This phase runs all quality checks and verification steps.

**Main `plan.md`** (index — no phase details):

```markdown
# Implementation Plan: <task-name>

**Status:** Ready
**Created:** <date>
**Based on PRD:** <prd path>
**Plan Format:** S
**Quality Checks:** per_phase | final

## Overall Progress
- [ ] Phase 1: <name>
- [ ] Phase 2: <name>
- [ ] Phase N: <name>
- [ ] Phase Final: Verification *(only when quality_check_mode=final)*

## Dependency Graph
Phase 1: (none)
Phase 2: Phase 1
Phase 3: Phase 1, Phase 2
Phase Final: All previous phases *(only when quality_check_mode=final)*

## Phase Files
- `plan-phase-1.md` — <one-line description>
- `plan-phase-2.md` — <one-line description>
- `plan-phase-N.md` — <one-line description>
- `plan-phase-final.md` — Final verification with quality checks *(only when quality_check_mode=final)*
```

**Per-phase file** (`plan-phase-N.md` in the task directory):

```markdown
# Phase N: <Phase Name>

**Goal:** <1-2 sentence description of what this phase achieves>
**Dependencies:** Phase 1, Phase 2 | None
**Files:**
- `path/to/file.ext` (create | modify | delete)
- `path/to/another-file.ext` (create | modify | delete)

## TODO
- [ ] <verb-first actionable item, e.g., "Create the UserService class with CRUD methods">
- [ ] <verb-first actionable item, e.g., "Add input validation for email and password fields">
- [ ] <verb-first actionable item, e.g., "Write unit tests for UserService.create and UserService.update">

## Quality Checks
<!-- Include this section ONLY if quality_check_mode is "per_phase" -->
- [ ] <quality command, e.g., npm run lint>
- [ ] <quality command, e.g., npm test>
```

**Final Verification Phase File** (`plan-phase-final.md` — generated ONLY when `quality_check_mode=final`):

```markdown
# Phase Final: Verification

**Goal:** Run all quality checks and verify implementation matches the plan
**Dependencies:** All previous phases
**Files:**
- *(none — this phase runs checks only)*

## TODO
- [ ] Run static type checks (discover from project: `npm run type-check`, `tsc --noEmit`, etc.)
- [ ] Run linting (discover from project: `npm run lint`, `eslint .`, etc.)
- [ ] Run tests (discover from project: `npm test`, `pytest`, etc.)
- [ ] Verify all TODO items in all phase files are marked complete
- [ ] Verify implementation matches plan specifications (read key files, compare to plan)
```

Format S rules:
- TODO items must be **single-line, verb-first** — no nested sub-fields (no What/Why/Constraints structure).
- Each TODO is one logical unit of work. Typically 3–10 items per phase.
- Generate one `plan-phase-N.md` per phase in the task directory alongside `plan.md`.
- Write a `phase_files` list to `state.yml` so agents can discover phase files without globbing.
- Write `quality_check_mode` to `state.yml` so task-executors know whether to run checks per-phase.
- The main `plan.md` contains **no phase details** — only progress tracking, dependency graph, and file list.
- Quality Checks section in phase files is only included when `quality_check_mode: per_phase`.
- When `quality_check_mode=final`: Generate a `plan-phase-final.md` file as the last phase containing quality check TODOs (type-check, lint, test, verification against plan).

---

## Key Rules

- Every task must specify exact file path and action (create / modify / delete).
- Quality checks must list commands actually discovered from the project.
- If TDD was requested: each phase lists failing test signatures/stubs first, then implementation tasks.
- Format C: always declare the format in each phase header so task-executors know how to interpret tasks.
- Always write `plan_format` to `state.yml` — task-executor agents read it to know how to work with the plan.
- Format S: generate separate `plan-phase-N.md` files and write `phase_files` and `quality_check_mode` to `state.yml`. The main `plan.md` is an index only. Include Quality Checks section in phase files only when `quality_check_mode: per_phase`. When `quality_check_mode=final`, also generate `plan-phase-final.md` with all quality check TODOs.
