# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **Claude Code Task Workflow** — a structured, agent-driven development workflow system. It provides slash commands, sub-agents, and automatic context injection to transform rough ideas into verified implementations.

## Development Commands

This is a pure configuration/documentation project with no build system. To test changes:

```bash
# Verify the hook script syntax
bash -n .claude/hooks/inject-task-context.sh
```

## Architecture

```
.claude/
  commands/                  # Slash command prompts (each is self-contained)
    task-create.md           # Creates PRD from brief
    task-clarify.md          # Structured Q&A for ambiguities
    task-add-context.md      # Adds files/URLs/repo context
    task-plan.md             # Generates implementation plan
    task-execute.md          # Spawns Task-Executor agents
    task-verify.md           # Quality verification at any stage
    task-update-docs.md      # Updates documentation
    task-fix.md              # Ad-hoc fixes in task context
    task-run.md              # Generic task-scoped command
    task-complete.md         # Close out a finished task
    task-list.md             # List active and completed tasks
    task-checkpoint.md       # Create/restore task checkpoints
    task-constraints.md      # Manage invariants and decision constraints
    project-docs.md          # Documentation management
    project-rules.md         # CLAUDE.md rules management
  skills/                    # Skills (model-invoked capabilities)
    docs/                    # Documentation skill
      SKILL.md
      references/
        README_TEMPLATE.md
        FEATURE_DOC_TEMPLATE.md
        SEARCH_PATTERNS.md
        DUPLICATE_CHECK.md
    prd/                     # PRD creation skill
      SKILL.md
      references/
        TEMPLATES.md
    project-rules/           # Rules management skill
      SKILL.md
      references/
        RULE_TEMPLATE.md
        DISCOVERY_PATTERNS.md
        MEMORY_HIERARCHY.md
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
    security.md              # Security rules (OWASP Top 10)
  settings.json              # Registers the hook
```

### Key Concepts

1. **Flat command files**: Each command is standalone — no dispatcher. This keeps prompts focused and enables tab-autocomplete for `/task-*`.

2. **Multi-file plans**: Plans are split into an index `plan.md` and individual `plan-phase-N.md` files per phase. `verification_mode` in `state.yml` controls when quality checks run: `per_phase` (each phase), `final` (after all phases), or `none` (skip automated checks).

3. **Task-Executor → Task-Verifier flow**: After all task-executors complete, the task-verifier runs automatically to check completeness, correctness, and quality.

4. **Constraints system**: Invariants (fixed rules) and decision-derived constraints (from clarification) are tracked in `state.yml` and must never be violated.

5. **Context injection via hook**: The `inject-task-context.sh` runs on every `UserPromptSubmit`, reading `state.yml` and injecting active task context so Claude always knows the current task.

6. **Verification rules**: Quality, performance, and security checks stored in `.claude/verification/` are applied by task-verifier.

### State Management

Task state lives in `.temp/tasks/` (gitignored):

- `state.yml` — active task pointer, status, paths, constraints
- `registry.yml` — completed task summaries (key decisions, constraints, files)
- `<task-name>/prd.md` — requirements document
- `<task-name>/plan.md` — plan index (progress, dependencies)
- `<task-name>/plan-phase-N.md` — phase details (TODOs, files, checks)
- `<task-name>/context.md` — additional context
- `<task-name>/localization.md` — file impact analysis
- `<task-name>/constraint-report.md` — constraint compliance audit
- `<task-name>/verify-report.md` — verification results
- `<task-name>/checkpoints/` — saved task states
- `<task-name>/reviews/` — phase review reports

## Task Workflow

This project itself uses the task workflow. Active task context is injected automatically at session start.

### Commands

| Command | Purpose |
|---------|---------|
| `/task-create <name> <description> [--quick] [--after <task>]` | Create a new task with a PRD. Add `--quick` for minimal PRD + inline plan. Add `--after <task>` to inherit from a completed task |
| `/task-clarify [N questions] [topic]` | Run structured clarification Q&A on active task |
| `/task-add-context [files\|url\|discover]` | Add context from files, URLs, or repo scan |
| `/task-plan` | Generate detailed implementation plan (no code runs yet) |
| `/task-execute [all\|phase N\|phases N,M]` | Execute plan via agents (parallel or sequential) |
| `/task-verify <prd\|plan\|code>` | Verify quality at a specific stage |
| `/task-update-docs` | Update project documentation based on implementation |
| `/task-fix [description]` | Ad-hoc fix or enhancement in task context |
| `/task-run <anything>` | Generic task-scoped freeform command |
| `/task-complete [--archive]` | Close out a finished task, optionally archive artifacts |
| `/task-list [--all \| --active \| --done]` | List active and completed tasks from registry |
| `/task-checkpoint <create\|restore\|list>` | Manage task checkpoints |
| `/task-constraints <add\|list\|check\|remove>` | Manage constraints for active task |
| `/project-docs <action>` | Manage project documentation |
| `/rules <action> [args]` | Manage Claude Code rules (add/change/delete/analyze/discover) |
| `/prd [brief]` | Create comprehensive PRD through iterative discovery |

### State

Active task state lives in `.temp/tasks/state.yml`.
All task artifacts are in `.temp/tasks/<task-name>/`.

### Constraints System

Constraints are rules that must never be violated during implementation:

- **Invariants**: Fixed rules from project requirements
- **Decision-derived**: Constraints that follow from decisions made in clarification

Constraints are:
- Stored in `state.yml` under `constraints:`
- Documented in PRD Section 10
- Injected into context by the hook
- Checked by task-executor before implementation
- Verified by task-verifier after implementation

### Verification Rules

The verification rules in `.claude/verification/` define checks for:

- **Quality**: Code readability, complexity, duplication, dead code, testing, error handling
- **Performance**: Database queries, API response time, memory management, frontend optimization
- **Security**: OWASP Top 10, language-specific patterns, severity levels

### Coding Guidelines

- Keep command files POSIX-compatible for the hook script
- Each command file must be self-contained with complete instructions
- Agent prompts must include all context needed for autonomous operation
- Hook script outputs JSON to stdout, user-facing messages to stderr
- Verification rules use severity levels: CRITICAL, HIGH, MEDIUM, LOW
