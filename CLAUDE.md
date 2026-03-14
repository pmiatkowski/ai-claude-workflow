# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **Claude Code Task Workflow** — a structured, agent-driven development workflow system that installs into other projects. It provides slash commands, sub-agents, and automatic context injection to transform rough ideas into verified implementations.

The installer (`install-task-workflow.sh`) creates the workflow structure in target projects.

## Development Commands

This is a pure configuration/documentation project with no build system. To test changes:

```bash
# Run the installer in a test project
cd /path/to/test-project
bash /path/to/install-task-workflow.sh

# Verify the hook script syntax
bash -n .claude/hooks/inject-task-context.sh
```

## Architecture

```
install-task-workflow.sh    # Single-file installer containing all components
.claude/
  commands/                  # Slash command prompts (each is self-contained)
    task-create.md           # Creates PRD from brief
    task-clarify.md          # Structured Q&A for ambiguities
    task-add-context.md      # Adds files/URLs/repo context
    task-plan.md             # Generates implementation plan (5 formats)
    task-execute.md          # Spawns Task-Executor agents
    task-verify.md           # Quality verification at any stage
    task-update-docs.md      # Updates documentation
    task-fix.md              # Ad-hoc fixes in task context
    task-run.md              # Generic task-scoped command
    rules.md                 # Manage Claude Code rules (CLAUDE.md)
  skills/                    # Skills (model-invoked capabilities)
    rules/                   # Rules management skill
      SKILL.md               # Main skill instructions
      references/            # Reference documentation
        RULE_TEMPLATE.md
        DISCOVERY_PATTERNS.md
        MEMORY_HIERARCHY.md
  agents/
    task-executor.md         # Implements one plan phase
    task-verificator.md      # Verifies full implementation
  hooks/
    inject-task-context.sh   # UserPromptSubmit hook for context injection
  settings.json              # Registers the hook
```

### Key Concepts

1. **Flat command files**: Each command is standalone — no dispatcher. This keeps prompts focused and enables tab-autocomplete for `/task-*`.

2. **Plan formats (A/B/C/D/B+D)**: Task-Executors interpret plans differently based on `plan_format` in `state.yml`. Format A has full code; Format B has detailed todos; Format C is hybrid; D has signatures only.

3. **Task-Executor → Task-Verificator flow**: After all task-executors complete, the task-verificator runs automatically to check completeness, correctness, and quality.

4. **Context injection via hook**: The `inject-task-context.sh` runs on every `UserPromptSubmit`, reading `state.yml` and injecting active task context so Claude always knows the current task.

### State Management

Task state lives in `.temp/tasks/` (gitignored):

- `state.yml` — active task pointer, status, paths
- `<task-name>/prd.md` — requirements document
- `<task-name>/plan.md` — implementation plan
- `<task-name>/context.md` — additional context
- `<task-name>/verify-report.md` — verification results

## Modifying the Installer

The installer uses heredocs to embed command/agent/hook content. When modifying:

1. Edit the heredoc content inside `install-task-workflow.sh`
2. Test by running the installer in a fresh directory
3. Verify the installed files match expectations

## Task Workflow

This project itself uses the task workflow. Active task context is injected automatically at session start.

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
| `/rules <action> [args]` | Manage Claude Code rules (add/change/delete/analyze/discover) |

### State

Active task state lives in `.temp/tasks/state.yml`.
All task artifacts are in `.temp/tasks/<task-name>/`.

### Coding Guidelines

- Keep installer script POSIX-compatible (avoid GNU-specific extensions)
- Each command file must be self-contained with complete instructions
- Agent prompts must include all context needed for autonomous operation
- Hook script outputs JSON to stdout, user-facing messages to stderr
