# Project Guidelines


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

