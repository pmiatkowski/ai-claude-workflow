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
                                                                         (at any point) → /task-checkpoint
                                                                         (at any point) → /task-constraints
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
verification_mode: per_phase     # per_phase | final | none
phase_files:
  - plan-phase-1.md
  - plan-phase-2.md
constraints:
  invariants:
    - id: I1
      constraint: "All API calls must be authenticated"
      added_at: 2024-01-15T10:00:00Z
  decisions:
    - id: D1-1
      from_decision: D1
      constraint: "Must use OAuth2, not custom auth"
      added_at: 2024-01-15T10:05:00Z
```

A `UserPromptSubmit` hook reads this file at the start of every Claude Code session and injects the active task context automatically. You'll see a banner:

```
Active task: my-feature (status: planned)
```

Claude always knows the current task without you repeating it.

### Task Artifacts

Each task lives in its own directory:

```
.temp/tasks/
  state.yml                        ← active task pointer + constraints
  my-feature/
    prd.md                         ← requirements document (AI-generated + clarified)
    plan.md                        ← plan index (progress, dependency graph, file list)
    plan-phase-1.md                ← phase details (TODOs, files, quality checks)
    plan-phase-2.md                ← phase details
    context.md                     ← additional context from files, URLs, discovery
    localization.md                ← file impact analysis (Phase 0)
    constraint-report.md           ← constraint compliance audit
    verify-report.md               ← written by task-verifier agent
    checkpoints/                   ← saved task states
      before-refactor/
        state.yml
        prd.md
        plan.md
    reviews/                       ← phase review reports
      phase-1-review.md
```

---

## Commands

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
| **Constraints** | **Invariants and decision-derived rules (Section 10)** |

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

After your answers are confirmed, the PRD is updated in place. **Decision-derived constraints** are automatically added to Section 10 and `state.yml`.

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

Before writing anything, Claude analyzes the PRD and codebase complexity, then asks two questions:

```
## Plan Configuration

I've analyzed the task. Here's my assessment:

Complexity signals:
- Touches 6 files across auth, middleware, and API layers — moderate integration surface
- One external library (jsonwebtoken) with well-documented API — low ambiguity

**Phase split:**
- **A) Single phase** — All TODOs in one `plan-phase-1.md` file. Best for small, focused tasks.
- **B) Split into phases** — Separate `plan-phase-N.md` files per phase with dependency tracking.

My recommendation: B — Split into 3 phases
Natural boundaries exist between utilities, endpoints, and middleware. Splitting enables
parallel execution of independent phases.

**Verification timing:**
- **1) After each phase** — Each phase executor runs quality checks before marking complete
- **2) After all phases** — Adds a Final Verification phase with all quality checks at the end
- **3) None** — No quality checks during execution

Please answer both: Phase split (A or B) and Verification (1, 2, or 3).
```

Plans are always split into an index `plan.md` plus individual `plan-phase-N.md` files. Each phase file contains:

```markdown
# Phase 1: JWT Utilities

**Goal:** Create token sign/verify utilities and token storage module
**Dependencies:** None
**Files:**
- `src/lib/jwt.ts` (create)
- `src/types/auth.ts` (create)

## TODO
- [ ] Create the TokenPayload and TokenPair interfaces in src/types/auth.ts
- [ ] Implement signToken utility with RS256 algorithm
- [ ] Implement verifyToken utility with null return on error
- [ ] Write unit tests for sign and verify functions

## Quality Checks
- [ ] npm run lint
- [ ] npm run type-check
- [ ] npm test
```

The main `plan.md` is an index — it tracks overall progress, dependency graph, and lists all phase files.

`verification_mode` is stored in `state.yml` as `per_phase`, `final`, or `none`.

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

#### Execution Flow

1. **Plan Verification** — A `plan-verifier` agent checks plan quality before execution
2. **Localization (Phase 0)** — A `localization-agent` analyzes file impact and identifies conflicts
3. **Task-Executor agents** — Each phase is implemented by a task-executor:
   - Reads `state.yml` to determine `verification_mode`
   - Reads the plan index and its assigned phase file
   - Implements only its assigned phase
   - Discovers quality commands from `package.json`, `Makefile`, `CLAUDE.md`
   - Runs all quality commands — fixes errors before finishing
   - Updates `plan.md` — marks every completed task `- [x]`
4. **Phase Review (optional)** — A `phase-reviewer` agent reviews each phase for quality
5. **Task-Verifier** — After all task-executors finish, runs automatically:
   - Checks every planned task is marked complete
   - Reads the actual implementation files and compares against the plan
   - Verifies all functional requirements from the PRD are satisfied
   - Runs all quality commands independently
   - Checks adherence to coding guidelines in `CLAUDE.md`
   - Checks against verification rules (quality, performance, security)
   - Writes a verification report to `.temp/tasks/<name>/verify-report.md`

---

### `/task-verify <prd|plan|code>`

Manual verification at any stage.

| Target | What it checks |
|--------|---------------|
| `prd` | Requirement clarity, internal consistency, coverage of edge cases, alignment with existing project features |
| `plan` | PRD coverage, phase ordering and dependencies, code consistency with repo patterns, quality check definitions |
| `code` | Runs quality commands, compares implementation to plan, checks coding standards, runs verification rules |

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

### `/task-constraints <action> [args]`

Manage constraints for the active task. Constraints are rules that must never be violated.

| Action | Description | Example |
|--------|-------------|---------|
| `add invariant "<text>"` | Add a fixed rule | `/task-constraints add invariant "All API calls must be authenticated"` |
| `add decision <D-id> "<text>"` | Add constraint from a decision | `/task-constraints add decision D1 "Must use OAuth2"` |
| `list` | List all constraints | `/task-constraints list` |
| `check` | Verify implementation respects constraints | `/task-constraints check` |
| `remove <id>` | Remove a constraint | `/task-constraints remove I1` |

**Constraint Types:**

| Type | Source | Example |
|------|--------|---------|
| **Invariant** | Fixed project requirements | "All API calls must be authenticated" |
| **Decision-derived** | Follows from clarification answers | "Must use OAuth2, not custom auth" (from D1) |

Constraints are:

- Stored in `state.yml` under `constraints:`
- Documented in PRD Section 10
- Injected into context by the hook
- Checked by task-executor before implementation
- Verified by task-verifier after implementation
- Can be audited on-demand via `constraint-tracker` agent

---

### `/task-checkpoint <action> [name]`

Create or restore checkpoints of task state. Useful before risky changes.

| Action | Description | Example |
|--------|-------------|---------|
| `create [name]` | Save current state | `/task-checkpoint create before-refactor` |
| `restore <name>` | Restore from checkpoint | `/task-checkpoint restore before-refactor` |
| `list` | List all checkpoints | `/task-checkpoint list` |

**What gets saved:**

- `state.yml`, `prd.md`, `plan.md`, `context.md`
- All handoff files, review files
- Constraint reports

**Storage:** `.temp/tasks/<task-name>/checkpoints/<name>/`

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

The difference from `/task-fix`: `/task-fix` is repair-oriented and always runs quality checks afterwards. `/task-run` has no assumed intent — it does exactly what the instruction says, nothing more.

---

## Additional Skills

### `/project-docs <action> [args]`

Manage project documentation (README.md, ./docs/*.md).

| Action | Description | Example |
|--------|-------------|---------|
| `init` | Initialize docs structure with templates | `/project-docs init` |
| `research <query>` | Find information in docs/codebase | `/project-docs research authentication` |
| `add <topic>` | Add new documentation | `/project-docs add API endpoints` |
| `change <topic>` | Update existing documentation | `/project-docs change installation` |
| `delete <topic>` | Remove documentation | `/project-docs delete legacy-api` |
| `scan` | Scan codebase and suggest doc updates | `/project-docs scan` |

---

### `/rules <action> [args]`

Manage Claude Code coding guidelines (CLAUDE.md rules).

| Action | Description | Example |
|--------|-------------|---------|
| `add` | Add new rules from file or inline text | `/rules add path/to/rules.md` |
| `change` | Modify existing rules matching query | `/rules change indentation` |
| `delete` | Remove rules matching query | `/rules delete jquery` |
| `analyze` | Analyze current rules for quality issues | `/rules analyze` |
| `discover` | Scan codebase to discover conventions | `/rules discover` |

---

### `/prd [brief]`

Create comprehensive Product Requirements Documents through iterative discovery. A 13-phase Socratic process that surfaces assumptions, validates thinking, and builds genuine understanding.

**Phases:**

1. Discovery & Challenge
2. Problem Validation
3. User Deep-Dive
4. Business Viability
5. Solution Definition
6-8. Requirements & Architecture
6. Risk Assessment
7. Go-to-Market
8. Success Metrics
12-13. Execution & Alignment

---

## Verification Rules

Task-verifier checks against rules in `.claude/verification/`:

### Quality (`quality.md`)

- Code readability (function size, naming, comments)
- Complexity (cyclomatic complexity, nesting depth)
- Duplication (DRY principle)
- Dead code detection
- Testing (coverage, quality, patterns)
- Error handling
- Documentation

### Performance (`performance.md`)

- Database (N+1 queries, indexing, query optimization)
- API (response time, rate limiting, payload size)
- Memory management (leaks, caching)
- Frontend (bundle size, rendering, assets)
- Concurrency (parallelization, resource limits)

### Security (`security.md`)

- OWASP Top 10 checks
- Language-specific security patterns
- Severity levels (CRITICAL → LOW)

---

## Full Walkthrough Example

```bash
# 1. Start a task
/task-create user-auth Add email + password auth with JWT and refresh token rotation

# Claude creates .temp/tasks/user-auth/prd.md
# Sections include: Goals, Requirements, Gaps & Ambiguities, and Constraints (Section 10)

# 2. Clarify the gaps
/task-clarify

# Claude asks 5 questions (scaled to PRD complexity):
# Q1: Token storage strategy → answered: httpOnly cookies
# Q2: Access token expiry → answered: 15 minutes
# Q3: Refresh token rotation → answered: rotate on every use
# Q4: Rate limiting on login → answered: yes, 5 attempts per 15 min
# Q5: Remember me → answered: extend refresh token to 30 days
# Claude updates prd.md with answers and adds decision-derived constraints

# 3. Add context from the repo
/task-add-context discover

# Claude scans: finds existing middleware pattern, reads package.json scripts
# Quality commands discovered: npm run lint:fix, npm run type-check, npm run test
# Existing pattern found: Express middleware in src/middleware/*.ts
# Claude appends findings to prd.md Section 9

# 4. Plan the implementation
/task-plan

# Claude recommends splitting into 3 phases with per-phase verification
# Claude asks for notes → "TDD please, failing tests first"
# Generates plan.md with 3 phases:
# Phase 1: JWT utilities + token storage (with failing tests first)
# Phase 2: Auth endpoints (register, login, refresh, logout)
# Phase 3: Auth middleware + route protection

# 5. Create a checkpoint before execution
/task-checkpoint create before-execute

# 6. Execute
/task-execute

# Plan-verifier runs: checks coverage, dependencies, quality commands
# Localization-agent runs (Phase 0): identifies file conflicts
# Claude asks: all phases, sequential or parallel?
# → "phases 1,2 parallel, then phase 3 sequential"
#
# Spawns: task-executor for Phase 1 + task-executor for Phase 2 simultaneously
# Both finish → spawns task-executor for Phase 3
# All finish → verifier runs automatically
# Task-Verifier report: PASS ✓

# 7. Check constraints
/task-constraints check

# Constraint-tracker verifies all invariants and decision-derived constraints

# 8. Verify docs
/task-update-docs

# Claude finds: README.md needs auth section, CLAUDE.md needs env var docs
# Updates both after confirmation

# 9. Ad-hoc fix during review
/task-fix the login endpoint returns 500 when email doesn't exist instead of 401
# Claude reads the prd (auth must return 401 for invalid credentials, not 500)
# Fixes root cause, runs quality commands, confirms PASS
```

---

## Architecture

```
.claude/
  commands/                  # Slash command prompts
    task-create.md           # Creates PRD from brief
    task-clarify.md          # Structured Q&A for ambiguities
    task-add-context.md      # Adds files/URLs/repo context
    task-plan.md             # Generates implementation plan
    task-execute.md          # Spawns Task-Executor agents
    task-verify.md           # Quality verification at any stage
    task-update-docs.md      # Updates documentation
    task-fix.md              # Ad-hoc fixes in task context
    task-run.md              # Generic task-scoped command
    task-checkpoint.md       # Create/restore task checkpoints
    task-constraints.md      # Manage invariants and decision constraints
    project-docs.md          # Documentation management
    project-rules.md         # CLAUDE.md rules management
  skills/                    # Skills (model-invoked capabilities)
    docs/                    # Documentation skill
      SKILL.md
      references/
    prd/                     # PRD creation skill
      SKILL.md
      references/
    project-rules/           # Rules management skill
      SKILL.md
      references/
    new-skill/               # Skill creation reference
      skill-creation-guidelines.md
  agents/
    task-executor.md         # Implements one plan phase
    task-verifier.md      # Verifies full implementation
    plan-verifier.md      # Verifies plan quality before execution
    localization-agent.md    # Analyzes file impact (Phase 0)
    phase-reviewer.md        # Reviews completed phases
    constraint-tracker.md    # Monitors constraint compliance
    docs-initializer.md      # Initializes doc structure
    docs-researcher.md       # Searches docs/codebase
    docs-manager.md          # CRUD operations on docs
  hooks/
    inject-task-context.sh   # UserPromptSubmit hook for context injection
  verification/              # Verification rules
    quality.md               # Code quality rules
    performance.md           # Performance rules
    security.md              # Security rules (OWASP)
  settings.json              # Registers the hook
```

### Key Concepts

1. **Flat command files**: Each command is standalone — no dispatcher. This keeps prompts focused and enables tab-autocomplete for `/task-*`.

2. **Multi-file plans**: Plans are split into an index `plan.md` and individual `plan-phase-N.md` files per phase. `verification_mode` in `state.yml` controls when quality checks run: `per_phase` (each phase), `final` (after all phases), or `none` (skip automated checks).

3. **Task-Executor → Task-Verifier flow**: After all task-executors complete, the task-verifier runs automatically.

4. **Constraints system**: Invariants and decision-derived rules that must never be violated. Tracked in `state.yml` and PRD Section 10.

5. **Context injection via hook**: The `inject-task-context.sh` runs on every `UserPromptSubmit`, reading `state.yml` and injecting active task context and constraints.

6. **Verification rules**: Quality, performance, and security checks stored in `.claude/verification/`.

---

## Project Customization

Open `CLAUDE.md` to customize project-specific behavior:

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

Agents read this section before generating plans and verifying code:

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

### Why the plan uses separate files per phase

A single monolithic plan forces every agent to load the entire plan even when implementing only one phase. Splitting into `plan-phase-N.md` files gives each task-executor focused context. The main `plan.md` serves as an index for progress tracking and dependency resolution.

The verification mode (`per_phase`, `final`, or `none`) lets you trade safety for speed: `per_phase` catches issues early, `final` runs one big verification pass, and `none` skips automated quality checks entirely.

### Why constraints are tracked separately

Constraints come from two sources: fixed invariants (project requirements) and decisions (from clarification). Tracking them separately in `state.yml` enables:

- Automatic injection into agent context
- Compliance checking at multiple stages
- Clear traceability from decisions to derived constraints

### Why a separate task-verifier agent

Task-Executors are incentivized to finish their phase — they will rationalize partial compliance. The verifier runs after all execution is complete, with no investment in any particular phase, and checks the full picture: completeness, correctness, PRD compliance, constraints, and quality.

---

## File Reference

| File | Purpose | Modified by |
|------|---------|-------------|
| `state.yml` | Active task pointer + constraints | Every command |
| `prd.md` | Requirements document | `/task-create`, `/task-clarify`, `/task-add-context` |
| `plan.md` | Plan index (progress, dependencies, file list) | `/task-plan`, task-executor agents |
| `plan-phase-N.md` | Phase details (TODOs, files, quality checks) | `/task-plan`, task-executor agents |
| `context.md` | Additional gathered context | `/task-add-context` |
| `localization.md` | File impact analysis | localization-agent |
| `constraint-report.md` | Constraint compliance audit | constraint-tracker |
| `verify-report.md` | Full verification report | verifier agent, `/task-verify` |
| `checkpoints/` | Saved task states | `/task-checkpoint` |
| `reviews/` | Phase review reports | phase-reviewer |
