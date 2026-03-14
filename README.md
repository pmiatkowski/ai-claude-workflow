# Claude Code Task Workflow

A structured, agent-driven development workflow for Claude Code. It turns a rough idea into a clarified spec, a detailed plan, and a verified implementation — using slash commands, sub-agents, and automatic context injection.

---

## Concept

Most AI-assisted development fails at the edges: requirements are vague, context gets lost between sessions, and "just implement it" produces code that doesn't match what was actually needed. This workflow adds structure around those weak points without adding cognitive overhead.

The core idea is a **task** — a self-contained unit of work with its own PRD, implementation plan, and context file. One task is always "active." Every Claude Code session automatically knows which task you're working on and what stage it's at. You move through stages with simple slash commands.

```
/task-create  →  /task-clarify  →  /task-add-context  →  /task-plan  →  /task-execute  →  /task-verify
                                                                                          /task-update-docs
                                                                         (at any point) → /task-fix
                                                                         (at any point) → /task-run
```

No abstractions to memorize beyond the commands. No configuration required to start.

---

## How It Works

### State

All task state lives in `.temp/tasks/`. One file controls what's active:

```yaml
# .temp/tasks/state.yml
active_task: my-feature
status: planned
task_path: .temp/tasks/my-feature
prd: .temp/tasks/my-feature/prd.md
plan: .temp/tasks/my-feature/plan.md
context: .temp/tasks/my-feature/context.md
```

A `UserPromptSubmit` hook reads this file at the start of every Claude Code session and injects the active task context automatically. You'll see a banner:

```
📌 Active task: my-feature (status: planned)
```

Claude always knows the current task without you repeating it.

### Task Artifacts

Each task lives in its own directory:

```
.temp/tasks/
  state.yml                        ← active task pointer
  my-feature/
    prd.md                         ← requirements document (AI-generated + clarified)
    plan.md                        ← implementation plan with actual code
    context.md                     ← additional context from files, URLs, discovery
    verify-report.md               ← written by task-verificator agent
```

---

## Commands

### `/rules <action> [args]`

Manage Claude Code coding guidelines (CLAUDE.md rules). Actions:

| Action | Description | Example |
|--------|-------------|---------|
| `add` | Add new rules from file or inline text | `/rules add path/to/rules.md` |
| `change` | Modify existing rules matching query | `/rules change indentation` |
| `delete` | Remove rules matching query | `/rules delete jquery` |
| `analyze` | Analyze current rules for quality issues | `/rules analyze` |
| `discover` | Scan codebase to discover conventions | `/rules discover` |

The `discover` action scans the codebase to detect:

- Tech stack (from package.json, Cargo.toml, pyproject.toml, etc.)
- File naming conventions (PascalCase, camelCase, kebab-case)
- Directory structure patterns
- Import/export patterns
- Existing linting and formatting configs

The `analyze` action checks rules for:

- Coverage gaps (what's missing)
- Conflicts (contradictory rules)
- Specificity (vague vs actionable)
- Organization (structure quality)

---

### `/task-create <name> <description>`

Creates a new task. The name becomes the folder slug; the description is your rough brief.

Claude synthesizes the brief into a structured PRD with these sections:

| Section | Content |
|---------|---------|
| Overview | Synthesized problem statement |
| Goals | Primary and secondary goals inferred from the brief |
| Functional Requirements | Concrete requirements + edge cases |
| Non-Functional Requirements | Performance, security, accessibility |
| Technical Considerations | Known constraints or dependencies |
| Out of Scope | What's explicitly excluded |
| **Gaps & Ambiguities** | **Things you didn't mention that will need decisions** |
| Open Questions | Blockers that must be resolved before implementation |
| Additional Context | Reserved — populated by `/task-add-context` |

The Gaps & Ambiguities section is the most important — it's what feeds the clarification step.

**Example:**

```
/task-create user-auth Add email + password authentication with JWT tokens and refresh token rotation
```

---

### `/task-clarify [N] [topic]`

Runs a structured Q&A session to resolve ambiguities in the PRD.

By default, Claude analyzes the Gaps & Ambiguities section and decides how many questions are needed (typically 3–8, scaled to complexity). You can override:

- `/task-clarify` — AI decides question count and topics
- `/task-clarify 3` — exactly 3 questions
- `/task-clarify token expiry` — focus only on token expiry decisions

Each question follows a consistent format:

```
## Question 2: Refresh Token Storage

Refresh tokens need to persist across sessions. Where they're stored affects
security, UX, and implementation complexity.

| Option | Description                                         | Tradeoffs                                      |
|--------|-----------------------------------------------------|------------------------------------------------|
| A      | httpOnly cookie — browser handles storage           | Secure vs XSS; requires CORS config            |
| B      | localStorage — JS-accessible                        | Simple; vulnerable to XSS                     |
| C      | In-memory + silent refresh — token never persisted  | Most secure; lost on tab close                 |
| D      | Database-backed rotation — server tracks all tokens | Full revocation control; adds DB round-trip    |

---

My Recommendation: Option A

httpOnly cookies prevent XSS access to the token entirely. Given you're building
a standard web app without unusual CORS requirements, this is the safest default.
Option D adds revocation capability but the complexity is rarely worth it unless
you need remote logout across all devices.

---
```

Claude asks questions one at a time without asking if you want to continue between them. When the session is complete, it asks whether you want another round or to update the PRD.

After your answers are confirmed, the PRD is updated in place.

---

### `/task-add-context [mode]`

Adds external context to the task. Three modes:

| Mode | Usage | What it does |
|------|-------|--------------|
| `files <paths>` | `/task-add-context files src/auth src/middleware` | Reads specified files, extracts relevant patterns |
| `url <url>` | `/task-add-context url https://jwt.io/introduction` | Fetches and summarizes the page |
| `discover` | `/task-add-context discover` | Auto-scans the repository |
| *(no argument)* | `/task-add-context` | Asks what you'd like to add |

**Auto-discovery** (`discover`) scans for:

- Coding patterns and conventions (component structure, naming, file layout)
- Reusable utilities, hooks, helpers relevant to the task
- Existing implementations of similar features
- Tech stack (reads `package.json`, config files, etc.)
- Quality commands — lint, type-check, test, build commands — recorded for later use by task-executor agents

After gathering context, Claude asks whether to add more or incorporate into the PRD (appended to Section 9: Additional Context).

---

### `/task-plan`

Generates a detailed implementation plan. **No code is executed at this stage.**

Before writing anything, Claude analyzes the PRD and codebase complexity, then proposes a plan format:

```
## Plan Format

I've analyzed the task. Here's my assessment:

Complexity signals:
- Touches 6 files across auth, middleware, and API layers — moderate integration surface
- One external library (jsonwebtoken) with well-documented API — low ambiguity
- Phase 1 is pure scaffolding; Phases 2–3 contain business logic with edge cases

My recommendation: C — Hybrid
Phase 1 (scaffolding) → Full code. Phase 2–3 (logic + middleware) → Detailed todos.
Writing full code for business logic upfront tends to miss edge cases that only become
clear when reading the actual files. Detailed todos keep the task-executor grounded in context.

| Format | Description                                                             | Best for                                             |
|--------|-------------------------------------------------------------------------|------------------------------------------------------|
| A      | Full code — complete implementation in the plan                         | Small, isolated tasks; low ambiguity                 |
| B      | Detailed todos — what, why, constraints, patterns; no code              | Large features; complex integrations                 |
| C      | Hybrid — full code for mechanical phases, todos for complex logic       | Most real-world features                             |
| D      | Skeleton + signatures — interfaces and function signatures; no bodies   | When type contracts must be locked in early          |
| B+D    | Todos with signatures — detailed todos plus typed contracts; no bodies  | Large tasks where type safety matters from the start |

What format would you like? (A, B, C, D, or B+D)
```

You pick the format. Then Claude asks for any final notes (TDD, patterns to follow, etc.) and generates `plan.md`.

Every phase in the plan follows the same outer structure — goal, dependencies, tasks, quality checks — with the **task block** varying by format:

**Format A — Full code**

```markdown
- [ ] 1.1 Create JWT utility module
  - **File:** `src/lib/jwt.ts`
  - **Action:** create
  - **What:** JWT sign/verify utilities using RS256
  - **Implementation:**
    ```typescript
    export const signToken = (payload: TokenPayload, expiresIn = '15m') =>
      jwt.sign(payload, process.env.JWT_PRIVATE_KEY!, { algorithm: 'RS256', expiresIn });
    ```
```

**Format B — Detailed todos**

```markdown
- [ ] 2.1 Implement login endpoint
  - **File:** `src/routes/auth.ts`
  - **Action:** modify
  - **What:** POST /auth/login — validate credentials, issue access + refresh tokens
  - **Why:** Core auth flow; tokens must be issued atomically or not at all
  - **Constraints:**
    - Use existing `UserRepository.findByEmail()` — do not query DB directly
    - Refresh token must be stored in httpOnly cookie, not response body
  - **Patterns to follow:** `src/routes/user.ts` for error handling pattern
  - **Edge cases:** wrong password → 401 (not 403); unverified email → 403 with specific message
  - **Do NOT:** return the refresh token in the JSON response body
```

**Format D — Skeleton + signatures**

```markdown
- [ ] 1.2 Define token types
  - **File:** `src/types/auth.ts`
  - **Action:** create
  - **Interfaces:**
    ```typescript
    export interface TokenPayload { userId: string; role: UserRole; }
    export interface TokenPair { accessToken: string; refreshToken: string; }
    ```
  - **Signatures:**
    ```typescript
    export async function signToken(payload: TokenPayload, expiresIn?: string): Promise<string>
    export async function verifyToken(token: string): Promise<TokenPayload | null>
    ```
  - **Implementation notes:** signToken wraps jsonwebtoken.sign with RS256; verifyToken catches all errors and returns null
```

**Format B+D** combines both: typed signatures as contracts plus full detailed todos for the implementation body.

The chosen format is stored in `state.yml` as `plan_format` so task-executor agents know how to interpret their tasks.

---

### `/task-execute [scope]`

Executes the plan by spawning sub-agents. Claude asks two questions:

**What to execute:**

- `all` — all phases
- `phase 2` — a specific phase
- `phases 1,3` — specific phases

**How to run them:**

- `parallel` — all selected phases simultaneously (for independent phases)
- `sequential` — one after another in order

Claude spawns **Task-Executor agents** via the Task tool. Each task-executor:

1. Reads `state.yml` to determine `plan_format`
2. Reads the full plan but implements only its assigned phase
3. Interprets tasks according to the plan format:
   - **A**: copies and applies the provided code directly
   - **B**: reads constraints, patterns, and edge cases — writes implementation guided by the todos
   - **C**: applies A or B rules per phase based on each phase's `**Format:**` header
   - **D**: implements function bodies respecting the signatures as fixed contracts
   - **B+D**: honours signatures as contracts, implements guided by detailed todos
4. Discovers quality commands from `package.json`, `Makefile`, `CLAUDE.md`
5. Runs all quality commands — fixes errors before finishing
6. Updates `plan.md` — marks every completed task `- [x]` and the phase entry in Overall Progress

After all task-executors finish, a **Task-Verificator agent** runs automatically.

The Task-Verificator:

- Checks every planned task is marked complete
- Reads the actual implementation files and compares against the plan
- Verifies all functional requirements from the PRD are satisfied
- Runs all quality commands independently
- Checks adherence to coding guidelines in `CLAUDE.md`
- Writes a verification report to `.temp/tasks/<name>/verify-report.md`

---

### `/task-verify <prd|plan|code>`

Manual verification at any stage.

| Target | What it checks |
|--------|---------------|
| `prd` | Requirement clarity, internal consistency, coverage of edge cases, alignment with existing project features |
| `plan` | PRD coverage, phase ordering and dependencies, code consistency with repo patterns, quality check definitions |
| `code` | Runs quality commands, compares implementation to plan, checks coding standards from `CLAUDE.md` |

Produces a structured report:

```markdown
# Verification Report: code — user-auth
Date: 2025-01-15
Result: PARTIAL

## Issues Found
| # | Severity | Location         | Issue                              | Recommendation              |
|---|----------|------------------|------------------------------------|-----------------------------|
| 1 | HIGH     | src/auth/jwt.ts  | Missing error handling on verify() | Wrap in try/catch, return null |
| 2 | LOW      | src/middleware   | Unused import 'lodash'             | Remove                      |
```

---

### `/task-update-docs`

Discovers documentation locations and checks if they need updating after implementation.

Discovery checks:

- `README.md` in root and subdirectories
- `CLAUDE.md` for doc references
- `docs/` directory
- PRD Section 9 for any doc references mentioned during context gathering

Claude presents a list of files that need updating and what needs to change, then asks for confirmation before making edits.

---

### `/task-fix [description]`

Ad-hoc fixes and enhancements in the context of the active task. The escape hatch for anything not covered by the structured flow.

```
/task-fix TypeError: Cannot read property 'userId' of undefined in middleware/auth.ts line 34
/task-fix the refresh token endpoint isn't returning the new access token in the response body
/task-fix add rate limiting to the login endpoint
```

Claude reads the PRD and plan to understand intent before fixing — so fixes stay consistent with the overall design. After fixing, it runs quality commands and offers to update the plan if the change is significant.

---

### `/task-run <anything>`

Generic task-scoped freeform command. Loads the full task context (state, PRD, plan) and then executes exactly what you ask — no assumed intent, no constrained scope.

```
/task-run update the README to reflect the new auth flow
/task-run refactor token utilities to use a class instead of standalone functions
/task-run check if plan phase 2 is still consistent with the PRD after the last clarification
/task-run add JSDoc to all exported functions in src/lib/jwt.ts
/task-run the build is failing with TS2345 — investigate and fix
```

The difference from `/task-fix`: `/task-fix` is repair-oriented and always runs quality checks afterwards. `/task-run` has no assumed intent — it does exactly what the instruction says, nothing more. Use it when you know what you want but it doesn't fit any of the structured commands.

---

## Full Walkthrough Example

```bash
# 1. Start a task
/task-create user-auth Add email + password auth with JWT and refresh token rotation

# Claude creates .temp/tasks/user-auth/prd.md
# Sections include: Goals, Requirements, and a Gaps & Ambiguities section
# with questions like: token storage strategy, expiry durations, refresh rotation policy

# 2. Clarify the gaps
/task-clarify

# Claude asks 5 questions (scaled to PRD complexity):
# Q1: Token storage strategy → answered: httpOnly cookies
# Q2: Access token expiry → answered: 15 minutes
# Q3: Refresh token rotation → answered: rotate on every use
# Q4: Rate limiting on login → answered: yes, 5 attempts per 15 min
# Q5: Remember me → answered: extend refresh token to 30 days
# Claude updates prd.md with answers

# 3. Add context from the repo
/task-add-context discover

# Claude scans: finds existing middleware pattern, reads package.json scripts
# Quality commands discovered: npm run lint:fix, npm run type-check, npm run test
# Existing pattern found: Express middleware in src/middleware/*.ts
# Claude appends findings to prd.md Section 9

# 4. Plan the implementation
/task-plan

# Claude asks for notes → "TDD please, failing tests first"
# Generates plan.md with 3 phases:
# Phase 1: JWT utilities + token storage (with failing tests first)
# Phase 2: Auth endpoints (register, login, refresh, logout)
# Phase 3: Auth middleware + route protection

# 5. Execute
/task-execute

# Claude asks: all phases, sequential or parallel?
# → "phases 1,2 parallel, then phase 3 sequential"
#
# Spawns: task-executor for Phase 1 + task-executor for Phase 2 simultaneously
# Both finish → spawns task-executor for Phase 3
# All finish → verificator runs automatically
# Task-Verificator report: PASS ✓

# 6. Verify docs
/task-update-docs

# Claude finds: README.md needs auth section, CLAUDE.md needs env var docs
# Updates both after confirmation

# 7. Ad-hoc fix during review
/task-fix the login endpoint returns 500 when email doesn't exist instead of 401
# Claude reads the prd (auth must return 401 for invalid credentials, not 500)
# Fixes root cause, runs quality commands, confirms PASS
```

---

## Installation

Download `install-task-workflow.sh` and run it from your project root:

```bash
bash install-task-workflow.sh
```

The script is safe to run on existing projects — it merges into existing `CLAUDE.md` and `settings.json` rather than overwriting them. Re-running is idempotent.

### What gets installed

```
.claude/
  commands/
    task-create.md
    task-clarify.md
    task-add-context.md
    task-plan.md
    task-execute.md
    task-verify.md
    task-update-docs.md
    task-fix.md
    task-run.md
  agents/
    task-executor.md
    task-verificator.md
  hooks/
    inject-task-context.sh     ← runs on every session start
  settings.json                ← hook registered here

CLAUDE.md                      ← workflow reference + project overrides
.temp/tasks/                   ← task artifacts (gitignored)
  state.yml
.gitignore                     ← .temp/ added
```

### Requirements

- Claude Code with slash commands enabled
- Bash (macOS / Linux / WSL)
- Python 3 (used during install only, to merge `settings.json`)

---

## Project Customization

After installation, open `CLAUDE.md`. Two sections control project-specific behavior:

### Quality Commands Override

By default, agents auto-discover commands from `package.json`, `Makefile`, and `CLAUDE.md`. To pin specific commands:

```markdown
### Project Quality Commands
quality_commands:
  - npm run lint:fix
  - npm run type-check
  - npm run test:unit
  - npm run build
```

### Coding Guidelines

Agents read this section before generating plans and verifying code. Add anything you want enforced:

```markdown
### Coding Guidelines
- Use named exports only — no default exports except for Next.js pages
- All async functions must handle errors explicitly — no unhandled promise rejections
- Prefer composition over inheritance
- Tests must cover happy path, error path, and edge cases
- Components: colocate test files as `ComponentName.test.tsx`
```

---

## Architecture Notes

### Why flat command files, not a dispatcher

Each command (`task-create.md`, `task-plan.md`, etc.) is a standalone prompt file. A single dispatcher that parses `$ARGUMENTS` would concentrate complex, divergent logic into one file that grows unmanageable. Flat files mean each stage has its full prompt context without sharing space, and tab-autocomplete in Claude Code surfaces the full command list from `/task-`.

### Why a hook instead of manual context

Without the `UserPromptSubmit` hook, you'd need to re-establish task context at the start of every session. The hook reads `state.yml` and injects context before any message is processed — so `/task-clarify` just works, regardless of when you last worked on the task.

### Why plan format is a choice, not a fixed rule

Writing full implementation code into a plan works well for small, isolated tasks — the code is stable by the time it's executed. But for larger features, it's actively harmful: the AI writes code without seeing the actual files, misses project-specific patterns, and produces output that's already stale or subtly wrong by execution time.

Detailed todos (Format B) solve this by making the task-executor reason through the implementation with full file context — it reads the existing code, follows referenced patterns, and handles edge cases with real knowledge of the codebase. The plan provides *what* and *why*, not *how*.

The hybrid and signature formats cover the middle ground: lock in the contracts (types, interfaces, signatures) at planning time when context is richest, but leave implementation bodies to the task-executor. Format B+D is particularly useful for TypeScript-heavy codebases where type safety is non-negotiable but implementation flexibility is needed.

The chosen format is stored in `state.yml` so task-executor agents always know how to interpret their tasks without ambiguity.

### Why a separate task-verificator agent

Task-Executors are incentivized to finish their phase — they will rationalize partial compliance. The verificator runs after all execution is complete, with no investment in any particular phase, and checks the full picture: completeness, correctness, PRD compliance, and quality.

---

## File Reference

| File | Purpose | Modified by |
|------|---------|-------------|
| `state.yml` | Active task pointer | Every command |
| `prd.md` | Requirements document | `/task-create`, `/task-clarify`, `/task-add-context` |
| `plan.md` | Implementation plan (format varies: A/B/C/D/B+D) | `/task-plan`, task-executor agents |
| `context.md` | Additional gathered context | `/task-add-context` |
| `verify-report.md` | Full verification report | Verificator agent, `/task-verify` |
