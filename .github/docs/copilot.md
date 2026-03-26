# GitHub Copilot Customization Primitives - Unified Reference

**Synthesized Document** | Version 1.0 | Date: 2026-03-24

---

## Executive Summary

GitHub Copilot provides a rich ecosystem of customization primitives that work together to create tailored AI coding experiences. This document synthesizes all customization types into a unified reference, helping you understand when and how to use each primitive.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Agent Types](#2-agent-types)
3. [Permission Levels](#3-permission-levels)
4. [Memory Systems](#4-memory-systems)
5. [Custom Instructions](#5-custom-instructions)
6. [Prompt Files](#6-prompt-files)
7. [Agent Skills](#7-agent-skills)
8. [Custom Agents](#8-custom-agents)
9. [Subagents](#9-subagents)
10. [Hooks](#10-hooks)
11. [MCP Servers](#11-mcp-servers)
12. [Tool Approval](#12-tool-approval)
13. [Tool Sets](#13-tool-sets)
14. [Agent Plugins](#14-agent-plugins)
15. [Choosing the Right Primitive](#15-choosing-the-right-primitive)
16. [File Locations Reference](#16-file-locations-reference)
17. [Configuration Settings](#17-configuration-settings)
18. [Best Practices](#18-best-practices)
19. [Quick Reference Cards](#19-quick-reference-cards)

---

## 1. Architecture Overview

### The Customization Hierarchy

```
┌─────────────────────────────────────────────────────────────────────┐
│                    GitHub Copilot Platform                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                │
│  │   Agents    │  │   Skills    │  │   Prompts   │                │
│  │  (Personas) │  │(Capabilities)│  │  (Tasks)    │                │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                │
│         │                │                │                        │
│         └────────────────┼────────────────┘                        │
│                          │                                         │
│  ┌───────────────────────┴───────────────────────┐                │
│  │              Custom Instructions               │                │
│  │         (Always-on Project Context)           │                │
│  └───────────────────────┬───────────────────────┘                │
│                          │                                         │
│  ┌───────────────────────┴───────────────────────┐                │
│  │                   Hooks                        │                │
│  │       (Lifecycle Event Automation)            │                │
│  └───────────────────────────────────────────────┘                │
│                                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                │
│  │MCP Servers  │  │   Plugins   │  │   Memory    │                │
│  │ (External)  │  │ (Bundled)   │  │  (Context)  │                │
│  └─────────────┘  └─────────────┘  └─────────────┘                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Key Concepts

| Concept                 | Description                                                     |
| ----------------------- | --------------------------------------------------------------- |
| **Agent Loop**          | The execution cycle: Understand → Act → Validate → Self-correct |
| **Context Injection**   | Automatic inclusion of project context in AI interactions       |
| **Progressive Loading** | 3-level skill loading (Discovery → Instructions → Resources)    |
| **Lifecycle Hooks**     | Deterministic code execution at specific agent events           |
| **Subagent Delegation** | Isolated worker agents for focused tasks                        |

### Activation Patterns

| Primitive           | Activation Pattern                          | Scope                         |
| ------------------- | ------------------------------------------- | ----------------------------- |
| Custom Instructions | **Automatic** - always included             | Project-wide or file-specific |
| Prompt Files        | **Manual** - invoked via `/` command        | Task-specific                 |
| Agent Skills        | **Semi-automatic** - loaded when relevant   | Task-specific                 |
| Custom Agents       | **Selection** - chosen from dropdown        | Persona-specific              |
| Subagents           | **Delegation** - spawned by main agent      | Task-isolated                 |
| Hooks               | **Event-driven** - fire at lifecycle points | Session-scoped                |

---

## 2. Agent Types

GitHub Copilot supports multiple agent execution environments, each suited for different workflows.

### Agent Types Comparison

| Agent Type      | Execution       | Interaction          | Tools Access     | Best For                                       |
| --------------- | --------------- | -------------------- | ---------------- | ---------------------------------------------- |
| **Ask**         | VS Code process | Real-time Q&A        | Full             | Answering questions, exploring codebase        |
| **Agent**       | VS Code process | Real-time autonomous | Full             | Interactive coding, feature implementation     |
| **Plan**        | VS Code process | Interactive planning | Read-only        | Complex planning, clarification                |
| **Copilot CLI** | Background CLI  | Async/background     | Limited          | Autonomous background work, worktree isolation |
| **Cloud Agent** | GitHub cloud    | Async/PR-based       | Cloud-configured | Team collaboration, PR workflows               |

### Built-in Local Agents

#### Ask Agent

- Works best for answering questions about your codebase
- Uses agentic capabilities to research and gather context
- Responses contain code blocks with "Apply in Editor" button

#### Agent (Default)

- Optimized for complex coding tasks based on high-level requirements
- Operates autonomously, determines relevant context and files to edit
- Plans work, iterates to resolve problems
- VS Code directly applies code changes in editor

#### Plan Agent

- Optimized for creating structured implementation plans
- **4-Phase Workflow:** Discovery → Alignment → Design → Refinement
- Uses read-only tools during planning
- Asks clarifying questions to resolve ambiguities
- Does not make code changes until plan is reviewed and approved

### Background Agents (Copilot CLI)

Runs independently in background using Git worktrees for isolation.

**Characteristics:**

- Runs outside VS Code, continues when VS Code is closed
- Uses Git worktrees to isolate changes from main workspace
- Multiple sessions can run simultaneously in parallel

**Isolation Modes:**

| Mode          | How It Works                           | Permission Levels                |
| ------------- | -------------------------------------- | -------------------------------- |
| **Worktree**  | Creates separate Git worktree folder   | Bypass Approvals only (auto-set) |
| **Workspace** | Operates directly in current workspace | Default, Bypass, or Autopilot    |

**Limitations:**

- Cannot access all VS Code built-in tools
- No access to extension-provided tools
- Limited to models available via CLI
- Can only access local MCP servers (no auth required)

### Cloud Agents

Run on GitHub's remote infrastructure for team collaboration.

**Key Features:**

- Integrates with GitHub repositories via pull requests
- Creates branches and PRs automatically
- Runs in ephemeral GitHub Actions environment
- Only pushes to `copilot/*` branches

**When to Use:**

| Use Case                             | Recommended Agent |
| ------------------------------------ | ----------------- |
| Interactive iteration, brainstorming | Local Agent       |
| Questions about codebase             | Ask Agent         |
| Structured implementation planning   | Plan Agent        |
| Background work while you continue   | Copilot CLI       |
| Team collaboration via PRs           | Cloud Agent       |

---

## 3. Permission Levels

Permission levels control how much autonomy the agent has during a session.

### Permission Levels Overview

| Level                 | Behavior                                                           | Use Case                               |
| --------------------- | ------------------------------------------------------------------ | -------------------------------------- |
| **Default Approvals** | Tools requiring approval show confirmation dialog                  | Normal development with oversight      |
| **Bypass Approvals**  | Auto-approves all tool calls, auto-retries on errors               | Trusted environments, faster iteration |
| **Autopilot**         | Auto-approves, auto-retries, auto-responds, continues autonomously | Fully autonomous task completion       |

### Autopilot Mode (Preview)

When **Autopilot** is selected:

| Behavior                      | Description                                           |
| ----------------------------- | ----------------------------------------------------- |
| **Continuous iteration**      | Agent works autonomously until task is complete       |
| **Auto-approve all tools**    | All tool calls approved automatically                 |
| **Auto-retry on errors**      | Agent automatically retries when encountering errors  |
| **Auto-respond to questions** | Tools that normally block for user input auto-respond |

**Enable:** `chat.autopilot.enabled` setting (on by default)

> **Caution:** Bypass Approvals and Autopilot remove manual approval prompts, including for potentially destructive actions.

### Approval Duration Options

When approving tools, you can approve for:

| Scope                      | Description             |
| -------------------------- | ----------------------- |
| **Single use**             | One-time approval       |
| **Current session**        | Until chat session ends |
| **Current workspace**      | For this project        |
| **All future invocations** | Global approval         |

---

## 4. Memory Systems

GitHub Copilot has **two complementary memory systems** for retaining context across conversations.

### Memory Systems Comparison

| Feature                            | Memory Tool (Local)       | Copilot Memory (Remote)              |
| ---------------------------------- | ------------------------- | ------------------------------------ |
| **Storage**                        | Local (on your machine)   | GitHub-hosted (remote)               |
| **Scopes**                         | User, Repository, Session | Repository only                      |
| **Shared across Copilot surfaces** | No (VS Code only)         | Yes (coding agent, code review, CLI) |
| **Created by**                     | You or agent during chat  | Copilot agents automatically         |
| **Enabled by default**             | Yes                       | No (opt-in)                          |
| **Expiration**                     | Manual management         | Automatic (28 days)                  |

### Memory Tool (Local)

A built-in tool that stores notes locally in three scopes:

| Scope          | Path                 | Persists Across                | Use For                                         |
| -------------- | -------------------- | ------------------------------ | ----------------------------------------------- |
| **User**       | `/memories/`         | All workspaces & conversations | Preferences, patterns, frequently used commands |
| **Repository** | `/memories/repo/`    | Conversations in workspace     | Codebase conventions, project structure         |
| **Session**    | `/memories/session/` | Current conversation only      | Task-specific context, in-progress plans        |

**User Memory Details:**

- First **200 lines** are automatically loaded into agent context at session start
- Use for general preferences applicable to any project

**Commands:**

| Command                        | Function                       |
| ------------------------------ | ------------------------------ |
| `Chat: Show Memory Files`      | Opens list of all memory files |
| `Chat: Clear All Memory Files` | Removes all memory files       |

**Storing Memories:**

```
Remember that I prefer tabs over spaces and always use single quotes in JavaScript
```

**Retrieving Memories:**

```
What are our commit message conventions?
```

### Copilot Memory (GitHub-Hosted)

Automatically captures repository-specific insights as agents work.

**Key Characteristics:**

- **Repository-scoped**: Only created by contributors with write access
- **Cross-agent**: What one Copilot agent learns is available to others
- **Verified before use**: Agents validate memories against current codebase
- **Auto-expired**: Memories deleted after 28 days

**Enable in VS Code:** `chat.copilotMemory.enabled`

**Enable on GitHub:** Personal Copilot settings (individual) or Organization policy settings (enterprise)

**Repository Management:** Repository Settings > Copilot > Memory

---

## 5. Custom Instructions

### Overview

Custom instructions are Markdown files that define coding standards and project context. The AI includes them automatically in chat requests.

**Note:** Custom instructions are NOT applied to inline suggestions as you type in the editor.

### Types

#### Always-On Instructions

Automatically included in every chat request.

| File                              | Purpose                                         | Scope               |
| --------------------------------- | ----------------------------------------------- | ------------------- |
| `.github/copilot-instructions.md` | Primary workspace instructions                  | Workspace           |
| `AGENTS.md`                       | Multi-agent compatibility (supports subfolders) | Workspace/Subfolder |
| `CLAUDE.md`                       | Claude Code compatibility                       | Workspace           |
| Organization-level                | Share across GitHub organization                | Organization        |

#### File-Based Instructions

Applied conditionally based on file patterns.

| Location                                 | Scope                        |
| ---------------------------------------- | ---------------------------- |
| `.github/instructions/*.instructions.md` | Workspace                    |
| `.claude/rules/*.md`                     | Workspace (Claude format)    |
| `~/.copilot/instructions/`               | User profile                 |
| `~/.claude/rules/`                       | User profile (Claude format) |

### File Format

```markdown
---
applyTo: '**/*.ts'
name: 'TypeScript Standards'
description: 'Coding conventions for TypeScript files'
---

# TypeScript Guidelines

- Use interfaces for data structures
- Prefer immutable data (const, readonly)
- Avoid any type; use unknown when type is uncertain
```

### Frontmatter Properties

| Property      | Required | Description                                                      |
| ------------- | -------- | ---------------------------------------------------------------- |
| `applyTo`     | No\*     | Glob pattern for file matching (\*required for auto-application) |
| `name`        | No       | Display name in UI                                               |
| `description` | No       | Short description of the instruction's purpose                   |

### Priority Order

1. **Personal instructions** (user-level) - Highest
2. **Repository instructions** (`.github/copilot-instructions.md` or `AGENTS.md`)
3. **Organization instructions** - Lowest

### When to Use

| Scenario                                 | Use Custom Instructions    |
| ---------------------------------------- | -------------------------- |
| Project-wide coding standards            | ✅ Always-on instructions  |
| Different rules for different file types | ✅ File-based instructions |
| Repeatable tasks                         | ❌ Use Prompt Files        |
| Complex workflows with scripts           | ❌ Use Agent Skills        |

---

## 6. Prompt Files

### Overview

Prompt files are standalone Markdown files invoked manually via `/` commands. Unlike custom instructions, they are not automatically applied.

### File Format

```markdown
---
description: 'Generate a new React form component'
name: 'react-form'
agent: 'agent'
model: GPT-4o
tools: ['search/codebase', 'vscode/askQuestions']
argument-hint: '[component name]'
---

Your prompt content here...
```

### Frontmatter Properties

| Field           | Required | Description                                                |
| --------------- | -------- | ---------------------------------------------------------- |
| `description`   | No       | Short description of the prompt                            |
| `name`          | No       | Name for `/` invocation (defaults to filename)             |
| `argument-hint` | No       | Hint text shown in chat input field                        |
| `agent`         | No       | Agent to use: `ask`, `agent`, `plan`, or custom agent name |
| `model`         | No       | Language model override                                    |
| `tools`         | No       | List of available tools                                    |

### File Locations

| Scope        | Location                          |
| ------------ | --------------------------------- |
| Workspace    | `.github/prompts/*.prompt.md`     |
| User profile | VS Code profile `prompts/` folder |

### Usage Methods

1. **Slash command:** Type `/prompt-name` in chat
2. **Command Palette:** Run `Chat: Run Prompt`
3. **Editor play button:** Open file and click play

### When to Use

| Use Case                                  | Recommended      |
| ----------------------------------------- | ---------------- |
| Lightweight, single-task prompts          | ✅ Prompt Files  |
| Persistent persona with tool restrictions | ❌ Custom Agents |
| Portable, multi-file capability           | ❌ Agent Skills  |

---

## 7. Agent Skills

### Overview

Agent Skills are folders containing instructions, scripts, and resources that GitHub Copilot loads when relevant. Built on an open standard (agentskills.io) for cross-platform portability.

### Key Benefits

| Benefit                  | Description                                         |
| ------------------------ | --------------------------------------------------- |
| **Specialize Copilot**   | Tailor capabilities for domain-specific tasks       |
| **Reduce repetition**    | Create once, use automatically across conversations |
| **Compose capabilities** | Combine multiple skills for complex workflows       |
| **Efficient loading**    | Only relevant content loads when needed             |
| **Cross-platform**       | Works across VS Code, CLI, and coding agent         |

### File Locations

| Type    | Project Skills    | Personal Skills      |
| ------- | ----------------- | -------------------- |
| Copilot | `.github/skills/` | `~/.copilot/skills/` |
| Claude  | `.claude/skills/` | `~/.claude/skills/`  |
| Generic | `.agents/skills/` | `~/.agents/skills/`  |

### Directory Structure

```
my-skill/
├── SKILL.md           # Required: Main instructions
├── script.sh          # Optional: Supporting script
├── template.js        # Optional: Template file
└── examples/          # Optional: Example scenarios
```

### SKILL.md File Format

```markdown
---
name: webapp-testing
description: Guide for testing web applications using Playwright. Use this when asked to create or run browser-based tests.
argument-hint: '[test file] [options]'
user-invocable: true
disable-model-invocation: false
---

# Web Application Testing with Playwright

## When to use this skill

- Create new Playwright tests
- Debug failing browser tests

## Creating tests

1. Review [test template](./test-template.js)
2. Identify user flow to test
```

### Frontmatter Properties

| Field                      | Required | Description                                                                     |
| -------------------------- | -------- | ------------------------------------------------------------------------------- |
| `name`                     | Yes      | Unique identifier (lowercase, hyphens, max 64 chars, must match directory name) |
| `description`              | Yes      | What skill does AND when to use it (max 1024 chars)                             |
| `argument-hint`            | No       | Hint text shown in chat input field                                             |
| `user-invocable`           | No       | Show in `/` menu (default: `true`)                                              |
| `disable-model-invocation` | No       | Prevent auto-loading (default: `false`)                                         |

### 3-Level Progressive Loading

```
Level 1: Discovery
    └── Reads name + description from all SKILL.md files

Level 2: Instructions Loading
    └── Loads SKILL.md body content when task matches description

Level 3: Resource Access
    └── Accesses additional files only when referenced in instructions
```

### Slash Command Configuration Matrix

| Configuration                                                       | Slash Command | Auto-loaded | Use Case                  |
| ------------------------------------------------------------------- | ------------- | ----------- | ------------------------- |
| Default (`user-invocable: true`, `disable-model-invocation: false`) | Yes           | Yes         | General-purpose skills    |
| `user-invocable: false`                                             | No            | Yes         | Background knowledge only |
| `disable-model-invocation: true`                                    | Yes           | No          | On-demand only            |
| Both set to restrict                                                | No            | No          | Disabled                  |

---

## 8. Custom Agents

### Overview

Custom agents are specialized AI configurations that provide tailored chat experiences. They consist of instructions, tools, model preferences, and handoffs.

### Components

| Component             | Description                               |
| --------------------- | ----------------------------------------- |
| **Instructions**      | Specific guidelines the AI follows        |
| **Tools**             | Restricted or expanded tool sets          |
| **Model Preferences** | Specific AI models optimized for the task |
| **Handoffs**          | Guided transitions to other agents        |

### File Locations

| Scope              | Location                                                 |
| ------------------ | -------------------------------------------------------- |
| Workspace          | `.github/agents/*.agent.md`                              |
| Workspace (Claude) | `.claude/agents/*.md`                                    |
| User profile       | `~/.copilot/agents/` or VS Code profile `agents/` folder |

### File Format

```yaml
---
description: Generate an implementation plan for new features
name: Planner
tools: ['web/fetch', 'search/codebase', 'search/usages']
model: ['Claude Opus 4.5', 'GPT-5.2']
agents: ['Red', 'Green', 'Refactor'] # Allowed subagents
handoffs:
  - label: Implement Plan
    agent: agent
    prompt: Implement the plan outlined above.
    send: false
hooks:
  PostToolUse:
    - type: command
      command: './scripts/format.sh'
---
# Agent Instructions
Your detailed instructions go here...
```

### Frontmatter Fields

| Field                      | Description                                              |
| -------------------------- | -------------------------------------------------------- |
| `description`              | Brief description shown as placeholder text              |
| `name`                     | Agent name (defaults to filename)                        |
| `argument-hint`            | Hint text for chat input field                           |
| `tools`                    | List of available tools/tool sets                        |
| `agents`                   | List of available subagents (`*` for all, `[]` for none) |
| `model`                    | AI model (single string or prioritized array)            |
| `user-invocable`           | Show in agents dropdown (default: true)                  |
| `disable-model-invocation` | Prevent subagent invocation (default: false)             |
| `target`                   | Target environment (`vscode` or `github-copilot`)        |
| `mcp-servers`              | MCP server config for GitHub Copilot target              |
| `handoffs`                 | List of transition actions to other agents               |
| `hooks`                    | Agent-scoped hook commands (Preview)                     |

### Handoffs: Guided Workflows

```yaml
handoffs:
  - label: Start Implementation # Button text
    agent: Implementation Agent # Target agent's name field (NOT the filename)
    prompt: Now implement the plan outlined above.
    send: false # Auto-submit (default: false)
    model: GPT-5.2 (copilot) # Optional model override
```

> **Critical:** The `agent` value must exactly match the target agent's `name` frontmatter field — it is **not** the filename slug. For example, an agent in `my-agent.agent.md` with `name: My Agent` must be referenced as `agent: My Agent`.
>
> **Prerequisite:** The target agent must have `user-invocable: true` (the default). Setting `user-invocable: false` removes the agent from the valid handoff targets list. Similarly, `disable-model-invocation: true` on the target agent will prevent handoff invocation entirely.

**Common workflow patterns:**

- Planning → Implementation
- Implementation → Review
- Write Failing Tests → Write Passing Tests

### Agent Types

| Agent Type       | Execution          | Interaction    | Use Case                   |
| ---------------- | ------------------ | -------------- | -------------------------- |
| **Local Agent**  | VS Code process    | Real-time      | Interactive iteration      |
| **Plan Agent**   | VS Code process    | Interactive    | Planning & clarification   |
| **Coding Agent** | Background (cloud) | Async          | Autonomous background work |
| **Cloud Agent**  | GitHub cloud       | Async/PR-based | Team collaboration         |

---

## 9. Subagents

### Overview

A **subagent** is an independent AI agent that performs focused, isolated work and reports results back to the main agent.

### Key Characteristics

| Feature                  | Description                                                        |
| ------------------------ | ------------------------------------------------------------------ |
| **Context Isolation**    | Operates in isolated context; doesn't pollute main conversation    |
| **Autonomous Operation** | Works independently and returns a summary                          |
| **Parallel Execution**   | Multiple subagents can run simultaneously                          |
| **Custom Configuration** | Can use custom agents with specific model, tools, and instructions |
| **Tool Delegation**      | Main agent passes only relevant subtask                            |

### How Subagents Work

```
1. User/Main Agent describes a complex task
2. Main agent recognizes subtasks benefiting from isolated context
3. Main agent starts subagent(s), passing only relevant subtask
4. Subagent works autonomously with its own context
5. Subagent returns summary/result to main agent
6. Main agent incorporates result and continues
```

### Configuration

#### Control Properties

| Property                   | Default   | Description                                            |
| -------------------------- | --------- | ------------------------------------------------------ |
| `user-invocable`           | `true`    | Controls visibility in agents dropdown                 |
| `disable-model-invocation` | `false`   | Prevents invocation as subagent                        |
| `agents`                   | `*` (all) | Restricts which custom agents can be used as subagents |

#### Subagent-Only Agent

```yaml
---
name: internal-helper
user-invocable: false
---
This agent can only be invoked as a subagent.
```

#### Restricting Available Subagents

```yaml
---
name: TDD
tools: ['agent']
agents: ['Red', 'Green', 'Refactor']
---
Implement using test-driven development.
```

### Orchestration Patterns

#### Pattern 1: Coordinator and Worker

```yaml
# Coordinator Agent
---
name: Feature Builder
tools: ['agent', 'edit', 'search', 'read']
agents: ['Planner', 'Plan Architect', 'Implementer', 'Reviewer']
---
You are a feature development coordinator.
1. Use the Planner agent to break down the feature
2. Use the Plan Architect agent to validate the plan
3. Use the Implementer agent to write the code
4. Use the Reviewer agent to check the implementation
```

#### Pattern 2: Multi-Perspective Analysis

```yaml
---
name: Thorough Reviewer
tools: ['agent', 'read', 'search']
---
Run these subagents in parallel:
- Correctness reviewer: logic errors, edge cases
- Code quality reviewer: readability, naming
- Security reviewer: input validation, injection risks
- Architecture reviewer: codebase patterns
Synthesize findings into a prioritized summary.
```

### Prompting Strategies

```
# Isolated research
"Perform isolated research into..."

# Parallel analysis
"Perform these tasks in parallel:"

# Multiple perspectives
"Review from different angles in parallel:"
```

---

## 10. Hooks

### Overview

Hooks enable execution of custom shell commands at key lifecycle points during agent sessions. They provide **deterministic, code-driven automation**.

> **Status:** Preview feature. Configuration format may change.

### Why Use Hooks

| Use Case                      | Description                  | Example                                 |
| ----------------------------- | ---------------------------- | --------------------------------------- |
| **Enforce Security Policies** | Block dangerous commands     | Prevent `rm -rf`, `DROP TABLE`          |
| **Automate Code Quality**     | Run formatters, linters      | Prettier after every file edit          |
| **Create Audit Trails**       | Log tool invocations         | Record all terminal commands            |
| **Inject Context**            | Add project-specific info    | Branch name, environment details        |
| **Control Approvals**         | Auto-approve safe operations | Require confirmation for sensitive ones |

### Hook Lifecycle Events

| Hook Event         | When It Fires                          | Common Use Cases                             |
| ------------------ | -------------------------------------- | -------------------------------------------- |
| `SessionStart`     | First prompt of new session            | Initialize resources, log session start      |
| `UserPromptSubmit` | User submits a prompt                  | Audit user requests, inject system context   |
| `PreToolUse`       | Before agent invokes any tool          | Block dangerous operations, require approval |
| `PostToolUse`      | After tool completes successfully      | Run formatters, log results                  |
| `PreCompact`       | Before conversation context compaction | Export important context                     |
| `SubagentStart`    | Subagent is spawned                    | Track nested agent usage                     |
| `SubagentStop`     | Subagent completes                     | Aggregate results, cleanup                   |
| `Stop`             | Agent session ends                     | Generate reports, cleanup resources          |

### Event Sequence

```
SessionStart
    │
    ▼
UserPromptSubmit ─────────────┐
    │                         │
    ▼                         │
PreToolUse ◄──────────────────┤ (repeats for each tool)
    │                         │
    ▼                         │
[Tool Execution]              │
    │                         │
    ▼                         │
PostToolUse ──────────────────┘
    │
    │ (context compaction)
    ▼
PreCompact
    │
    │ (subagent spawned)
    ├──────────────► SubagentStart
    │                        │
    │                        ▼
    │                [Subagent Work]
    │                        │
    │                        ▼
    │                SubagentStop ◄─────┘
    │
    ▼
Stop
```

### File Locations

| Scope               | Location                                                     |
| ------------------- | ------------------------------------------------------------ |
| Workspace (VS Code) | `.vscode/settings.json` with `github.copilot.chat.hooks` key |
| Workspace (Claude)  | `.claude/settings.json`, `.claude/settings.local.json`       |
| User                | `~/.claude/settings.json` or VS Code user settings           |
| Custom agent        | `hooks` field in `.agent.md` frontmatter                     |
| Plugin              | `hooks.json` or `hooks/hooks.json` within plugin directory   |

### Configuration Format

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "type": "command",
        "command": "./scripts/validate-tool.sh",
        "timeout": 15
      }
    ],
    "PostToolUse": [
      {
        "type": "command",
        "command": "npx prettier --write \"$TOOL_INPUT_FILE_PATH\""
      }
    ]
  }
}
```

### Hook Command Properties

| Property  | Type   | Description                               |
| --------- | ------ | ----------------------------------------- |
| `type`    | string | Must be `"command"`                       |
| `command` | string | Default command (cross-platform)          |
| `windows` | string | Windows-specific command override         |
| `linux`   | string | Linux-specific command override           |
| `osx`     | string | macOS-specific command override           |
| `cwd`     | string | Working directory (relative to repo root) |
| `env`     | object | Additional environment variables          |
| `timeout` | number | Timeout in seconds (default: 30, max: 60) |

### Input/Output Protocol

Hooks communicate via stdin (input) and stdout (output) using JSON.

#### Common Input Fields

```json
{
  "timestamp": "2026-02-09T10:30:00.000Z",
  "cwd": "/path/to/workspace",
  "sessionId": "session-identifier",
  "hookEventName": "PreToolUse",
  "transcript_path": "/path/to/transcript.json"
}
```

#### Common Output Fields

```json
{
  "continue": true,
  "stopReason": "Security policy violation",
  "systemMessage": "Unit tests failed"
}
```

#### PreToolUse Hook-Specific Output

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Destructive command blocked",
    "updatedInput": { "files": ["src/safe.ts"] },
    "additionalContext": "User has read-only access"
  }
}
```

| `permissionDecision` Values | Effect                    |
| --------------------------- | ------------------------- |
| `"allow"`                   | Proceed without prompting |
| `"ask"`                     | Prompt user for approval  |
| `"deny"`                    | Block the operation       |

### Exit Codes

| Exit Code | Behavior                                     |
| --------- | -------------------------------------------- |
| `0`       | Success: parse stdout as JSON                |
| `2`       | Blocking error: stop and show error to model |
| Other     | Non-blocking warning: continue processing    |

### Agent-Scoped Hooks

Define hooks directly in custom agent frontmatter:

```yaml
---
name: 'Strict Formatter'
hooks:
  PostToolUse:
    - type: command
      command: './scripts/format-changed-files.sh'
      timeout: 30
---
```

**Requirement:** Enable `chat.useCustomAgentHooks` setting.

---

## 11. MCP Servers

### Overview

Model Context Protocol (MCP) is an open standard for connecting AI models to external tools and services. MCP servers provide tools for tasks like file operations, databases, or external APIs.

### MCP Capabilities

| Capability    | Description                                   | How to Use                          |
| ------------- | --------------------------------------------- | ----------------------------------- |
| **Tools**     | Functions the AI can call                     | Automatically invoked when relevant |
| **Resources** | Read-only data (files, tables, API responses) | Chat → Add Context → MCP Resources  |
| **Prompts**   | Preconfigured prompt templates                | Type `/.` in chat                   |
| **MCP Apps**  | Interactive UI (forms, visualizations)        | Appear inline automatically         |

### When to Use

| Use Case                      | Use MCP                    |
| ----------------------------- | -------------------------- |
| Query databases               | ✅                         |
| Access external APIs          | ✅                         |
| Connect to cloud services     | ✅                         |
| Project-wide coding standards | ❌ Use Custom Instructions |

### Configuration Files

| Scope         | File                               |
| ------------- | ---------------------------------- |
| Workspace     | `.vscode/mcp.json`                 |
| User profile  | Run `MCP: Open User Configuration` |
| Dev Container | `devcontainer.json` customizations |

### Configuration Example

```json
{
  "servers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp"
    },
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@microsoft/mcp-server-playwright"]
    },
    "streaming-service": {
      "type": "sse",
      "url": "https://api.example.com/mcp/sse"
    }
  }
}
```

**Server Types:**
| Type | Description |
|------|-------------|
| `stdio` | Local process communication via stdin/stdout |
| `http` | HTTP-based MCP server |
| `sse` | Server-Sent Events for streaming connections |

**Important:** Avoid hardcoding API keys. Use input variables or environment files.

### Adding MCP Servers

| Method              | Steps                                                                               |
| ------------------- | ----------------------------------------------------------------------------------- |
| **From Gallery**    | Extensions view → Search `@mcp` → Install                                           |
| **Command Palette** | Run `MCP: Add Server` for guided flow                                               |
| **From Terminal**   | `code --add-mcp '{"name":"my-server","command":"uvx","args":["mcp-server-fetch"]}'` |

### Auto-Discovery

Enable `chat.mcp.discovery.enabled` to detect configurations from other apps (e.g., Claude Desktop).

### Sandbox MCP Servers

Restrict file system and network access for stdio MCP servers (macOS and Linux only).

```json
{
  "servers": {
    "myServer": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@example/mcp-server"],
      "sandboxEnabled": true,
      "sandbox": {
        "filesystem": {
          "allowWrite": ["${workspaceFolder}"]
        },
        "network": {
          "allowedDomains": ["api.example.com"]
        }
      }
    }
  }
}
```

**Benefit:** Tool calls are auto-approved in sandboxed environment.

### Managing MCP Servers

| Method            | Actions                         |
| ----------------- | ------------------------------- |
| Extensions view   | Right-click server or gear icon |
| `mcp.json` editor | Inline code lens actions        |
| Command Palette   | `MCP: List Servers`             |

### Server Trust

First-time server start requires trust confirmation. Review configuration before trusting.

**Reset trust:** Run `MCP: Reset Trust` command.

---

## 12. Tool Approval

### Overview

Tools with side effects require approval before running as a security measure. The approval system lets you control which tools can run automatically and which require confirmation.

### Approval Workflow

When a tool requires approval:

1. A confirmation dialog appears showing tool details
2. Review the information carefully
3. Approve for:
   - **Single use** - One-time approval
   - **Current session** - Until chat session ends
   - **Current workspace** - For this project
   - **All future invocations** - Global approval

### URL Approval (Two-Step Process)

When a tool accesses a URL (e.g., `#web/fetch`), a two-step approval process is used:

| Step                         | Purpose                                      | Options                                  |
| ---------------------------- | -------------------------------------------- | ---------------------------------------- |
| **Pre-approval (Request)**   | Trust the domain being contacted             | One-time or auto-approve future requests |
| **Post-approval (Response)** | Review fetched content before adding to chat | Always requires review                   |

**Note:** Post-approval is not linked to "Trusted Domains" - always requires review to prevent prompt injection.

### URL Auto-Approval Configuration

```json
{
  "chat.tools.urls.autoApprove": {
    "https://www.example.com": false,
    "https://*.contoso.com/*": true,
    "https://example.com/api/*": {
      "approveRequest": true,
      "approveResponse": false
    }
  }
}
```

Supports exact URLs, glob patterns, wildcards, and granular control with `approveRequest` and `approveResponse` properties.

### Editing Tool Parameters

Review and edit input parameters before a tool runs:

1. When the tool confirmation dialog appears, select the chevron next to the tool name
2. Edit any tool input parameters as needed
3. Select **Allow** to run the tool with modified parameters

### Disabling Auto-Approval for Specific Tools

```json
{
  "chat.tools.eligibleForAutoApproval": {
    "terminal": false
  }
}
```

Set to `false` to always require manual approval for that tool.

### Reset Tool Confirmations

Clear all saved tool approvals using: **Chat: Reset Tool Confirmations** command (Command Palette: Shift+Cmd+P)

---

## 13. Tool Sets

### Overview

Tool sets group related tools for easier reference in prompts, prompt files, and custom chat agents.

### Creating a Tool Set

1. Run **Chat: Configure Tool Sets** command from Command Palette
2. Select **Create new tool sets file**
3. Define your tool set in the `.jsonc` file

### Tool Set Structure

```json
{
  "reader": {
    "tools": ["search/changes", "search/codebase", "read/problems", "search/usages"],
    "description": "Tools for reading and gathering context",
    "icon": "book"
  },
  "writer": {
    "tools": ["edit", "createFile", "terminal"],
    "description": "Tools for making changes",
    "icon": "edit"
  }
}
```

### Tool Set Properties

| Property      | Description                                             |
| ------------- | ------------------------------------------------------- |
| `tools`       | Array of tool names (built-in, MCP, or extension tools) |
| `description` | Brief description displayed in the tools picker         |
| `icon`        | Icon for the tool set (see Product Icon Reference)      |

### Built-in Tool Sets

| Tool Set  | Tools Included |
| --------- | -------------- |
| `#edit`   | Editing tools  |
| `#search` | Search tools   |

### Using Tool Sets

Reference in prompts by typing `#` followed by the tool set name:

```
"Analyze the codebase for security issues #reader"
"Where is the DB connection string defined? #search"
```

In the tools picker, tool sets appear as collapsible groups of related tools.

### In Prompt Files and Custom Agents

```yaml
# In prompt file
---
tools: ['reader', 'vscode/askQuestions']
---
# In custom agent
---
tools: ['writer', 'search/codebase']
---
```

---

## 14. Agent Plugins

### Overview

Agent plugins are pre-packaged bundles of customizations from plugin marketplaces. A single plugin can provide any combination of slash commands, agent skills, custom agents, hooks, and MCP servers.

> **Status:** Preview feature. Enable/disable with `chat.plugins.enabled` setting.

### What Plugins Provide

| Customization  | Description                                        |
| -------------- | -------------------------------------------------- |
| Slash commands | Additional `/` commands                            |
| Skills         | Agent skills with instructions, scripts, resources |
| Agents         | Custom agents with specialized personas            |
| Hooks          | Shell commands at lifecycle points                 |
| MCP servers    | External tool integrations                         |

### Plugin Structure

```
my-testing-plugin/
├── plugin.json           # Plugin metadata
├── skills/
│   └── test-runner/
│       ├── SKILL.md      # Testing skill instructions
│       └── run-tests.sh  # Supporting script
├── agents/
│   └── test-reviewer.agent.md  # Code review agent
├── hooks/
│   └── hooks.json        # Hook configuration
├── scripts/
│   └── validate-tests.sh # Hook script
└── .mcp.json             # MCP server definitions
```

### Hooks in Plugins

| Format  | Path                       |
| ------- | -------------------------- |
| Claude  | `hooks/hooks.json`         |
| Copilot | `hooks.json` (plugin root) |

**Reference plugin paths:** Use `${CLAUDE_PLUGIN_ROOT}` token:

```json
{ "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate-tool.sh" }
```

### MCP Servers in Plugins

Place `.mcp.json` at plugin root:

```json
{
  "mcpServers": {
    "plugin-database": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"]
    }
  }
}
```

**Note:** Top-level key is `mcpServers` (not `servers`). Servers are implicitly trusted (no separate trust prompt).

### Discover and Install

| Method                  | Steps                                                                           |
| ----------------------- | ------------------------------------------------------------------------------- |
| **Browse Plugins**      | Extensions view (⇧⌘X) → Search `@agentPlugins`                                  |
| **Install from Source** | Command Palette → `Chat: Install Plugin From Source` → Enter Git repository URL |
| **View Installed**      | Extensions view → Agent Plugins - Installed                                     |

### Configure Marketplaces

Default marketplaces: `copilot-plugins`, `awesome-copilot`

Add custom marketplaces:

```json
{
  "chat.plugins.marketplaces": ["anthropics/claude-code"]
}
```

Supported formats: `owner/repo`, HTTPS git remote, SCP-style, or file URI.

### Use Local Plugins

```json
{
  "chat.pluginLocations": {
    "/path/to/my-plugin": true,
    "/path/to/another-plugin": false
  }
}
```

`true` = enabled, `false` = registered but disabled.

### Update Plugins

- **Manual:** `Extensions: Check for Extension Updates`
- **Auto:** Every 24 hours when `extensions.autoUpdate` enabled

---

## 15. Choosing the Right Primitive

### Decision Matrix

| Goal                                          | Use                     | When it activates                  |
| --------------------------------------------- | ----------------------- | ---------------------------------- |
| Apply coding standards everywhere             | Always-on instructions  | Automatically in every request     |
| Different rules for different files           | File-based instructions | When files match pattern           |
| Reusable task I run repeatedly                | Prompt files            | When I invoke `/command`           |
| Multi-step workflow with scripts              | Agent skills            | When task matches description      |
| Specialized AI persona with tool restrictions | Custom agents           | When selected or delegated         |
| Connect to external APIs                      | MCP servers             | When task matches tool description |
| Automate at lifecycle points                  | Hooks                   | When agent reaches lifecycle event |
| Install pre-packaged customizations           | Agent plugins           | When plugin is installed           |

### Quick Selection Guide

```
┌─────────────────────────────────────────────────────────────┐
│                    What do you need?                        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
              ┌─────────────────────────────┐
              │ Always-on coding standards? │──→ Custom Instructions
              └─────────────────────────────┘
                            │
                            ▼
              ┌─────────────────────────────┐
              │ Repeatable single task?     │──→ Prompt Files
              └─────────────────────────────┘
                            │
                            ▼
              ┌─────────────────────────────┐
              │ Multi-step with scripts?    │──→ Agent Skills
              └─────────────────────────────┘
                            │
                            ▼
              ┌─────────────────────────────┐
              │ Specialized persona?        │──→ Custom Agents
              └─────────────────────────────┘
                            │
                            ▼
              ┌─────────────────────────────┐
              │ External service?           │──→ MCP Servers
              └─────────────────────────────┘
                            │
                            ▼
              ┌─────────────────────────────┐
              │ Lifecycle automation?       │──→ Hooks
              └─────────────────────────────┘
```

### Recommended Implementation Order

1. **Start with** custom instructions for project-wide standards
2. **Add** prompt files for repeatable tasks
3. **Use** MCP when you need external data
4. **Create** custom agents for specialized personas
5. **Build** agent skills for complex workflows
6. **Configure** hooks for lifecycle automation
7. **Combine** multiple types as needs grow

---

## 16. File Locations Reference

### Complete Location Matrix

| Customization Type                   | Workspace Location                       | User Location              |
| ------------------------------------ | ---------------------------------------- | -------------------------- |
| Always-on instructions (Copilot)     | `.github/copilot-instructions.md`        | —                          |
| Always-on instructions (Multi-agent) | `AGENTS.md`                              | —                          |
| Always-on instructions (Claude)      | `CLAUDE.md` or `.claude/CLAUDE.md`       | `~/.claude/CLAUDE.md`      |
| File-based instructions              | `.github/instructions/*.instructions.md` | `~/.copilot/instructions/` |
| Claude rules                         | `.claude/rules/*.md`                     | `~/.claude/rules/`         |
| Prompt files                         | `.github/prompts/*.prompt.md`            | VS Code profile `prompts/` |
| Custom agents                        | `.github/agents/*.agent.md`              | `~/.copilot/agents/`       |
| Claude agents                        | `.claude/agents/*.md`                    | —                          |
| Agent skills                         | `.github/skills/*/SKILL.md`              | `~/.copilot/skills/`       |
| Claude skills                        | `.claude/skills/*/SKILL.md`              | `~/.claude/skills/`        |
| Hooks                                | `.github/hooks/*.json`                   | `~/.copilot/hooks/`        |
| Claude hooks                         | `.claude/settings.json`                  | `~/.claude/settings.json`  |

### Monorepo Support

Enable `chat.useCustomizationsInParentRepositories` to discover customizations from parent repository roots.

---

## 17. Quick Access Commands

### Key Settings

| Setting                                      | Purpose                                 | Default |
| -------------------------------------------- | --------------------------------------- | ------- |
| `chat.useAgentsMdFile`                       | Enable AGENTS.md support                | `true`  |
| `chat.useNestedAgentsMdFiles`                | Enable nested AGENTS.md (experimental)  | `false` |
| `chat.useClaudeMdFile`                       | Enable CLAUDE.md support                | `true`  |
| `chat.useCustomizationsInParentRepositories` | Monorepo parent discovery               | `false` |
| `chat.promptFilesLocations`                  | Custom prompt file locations            | —       |
| `chat.agentSkillsLocations`                  | Custom skill locations                  | —       |
| `chat.agentFilesLocations`                   | Custom agent file locations             | —       |
| `chat.hookFilesLocations`                    | Custom hook file locations              | —       |
| `chat.useCustomAgentHooks`                   | Enable agent-scoped hooks               | `false` |
| `chat.agent.enabled`                         | Enable/disable agents                   | Varies  |
| `chat.autopilot.enabled`                     | Enable Autopilot mode                   | `true`  |
| `chat.plugins.enabled`                       | Enable/disable agent plugins            | `true`  |
| `chat.mcp.discovery.enabled`                 | Auto-detect MCP configs from other apps | `false` |
| `chat.mcp.autoStart`                         | Auto-restart MCP servers                | `false` |
| `chat.copilotMemory.enabled`                 | Enable Copilot Memory (remote)          | `false` |
| `chat.tools.memory.enabled`                  | Enable local memory tool                | `true`  |

### Tool Approval Settings

| Setting                               | Purpose                                  |
| ------------------------------------- | ---------------------------------------- |
| `chat.tools.urls.autoApprove`         | URL auto-approval patterns               |
| `chat.tools.terminal.autoApprove`     | Terminal command auto-approval rules     |
| `chat.tools.terminal.sandbox.enabled` | Enable terminal sandboxing               |
| `chat.tools.eligibleForAutoApproval`  | Disable auto-approval for specific tools |
| `chat.tools.global.autoApprove`       | Global auto-approve all tools            |

### Quick Access Commands

| Command               | Purpose                         |
| --------------------- | ------------------------------- |
| `/instructions`       | Access instruction files        |
| `/prompts`            | Access prompt files             |
| `/skills`             | Access agent skills             |
| `/agents`             | Access custom agents            |
| `/hooks`              | Access hook configuration       |
| `/init`               | Generate workspace instructions |
| `/create-instruction` | AI-generate instruction file    |
| `/create-prompt`      | AI-generate prompt file         |
| `/create-skill`       | AI-generate skill               |
| `/create-agent`       | AI-generate agent               |
| `/create-hook`        | AI-generate hook                |

---

## 18. Best Practices

### For Custom Instructions

1. **Keep short and self-contained** - Single, simple statements
2. **Include reasoning** - Explain WHY a convention exists
3. **Show examples** - Concrete code patterns over abstract rules
4. **Focus on non-obvious rules** - Skip what linters/formatters enforce
5. **Use multiple files** - Separate by topic with `applyTo` patterns
6. **Store in workspace** - Share with team via version control
7. **Reference other files** - Use Markdown links to avoid duplication

### For Prompt Files

1. **Clear description** - What prompt accomplishes and output format
2. **Provide examples** - Expected input/output examples
3. **Reference instructions** - Use Markdown links instead of duplicating
4. **Use variables** - `${selection}`, `${input:variableName}` for flexibility
5. **Test and iterate** - Use editor play button for quick testing

### For Agent Skills

1. **Clear description** - Help AI know when to use the skill
2. **Modular design** - Keep skills focused on single capability
3. **Progressive disclosure** - Most important information first
4. **Reference external files** - Use Markdown links instead of embedding
5. **Version control** - Commit skills to repository for team sharing

### For Custom Agents

1. **Use read-only tools for planning/research** - No modifications
2. **Provide specialized instructions** - Consistent responses
3. **Use handoffs for guided workflows** - Sequential agent transitions
4. **Review tool lists** - Principle of least privilege when sharing

### For Subagents

1. **Define when to use subagents** - In custom agent instructions
2. **Clearly define task and output** - For each subagent
3. **Set `user-invocable: false`** - For internal-only agents
4. **Use `disable-model-invocation: true`** - Protect from unwanted use

### For Hooks

1. **Always output valid JSON** - To stdout
2. **Validate and sanitize input** - Prevent injection attacks
3. **Use `jq` or JSON libraries** - Construct output
4. **Check `stop_hook_active`** - Prevent infinite loops
5. **Never hardcode secrets** - Use environment variables

### Security Considerations

1. **Principle of least privilege** - Review tool lists before sharing agents
2. **Review tool parameters** - Before approving
3. **Bypass Approvals and Autopilot** - Remove security protections
4. **Review community skills** - Before using
5. **Protect hook scripts** - Use `chat.tools.edits.autoApprove` to prevent editing

---

## 19. Quick Reference Cards

### Primitive Comparison

| Feature         | Custom Instructions | Prompt Files | Agent Skills   | Custom Agents        | Hooks        |
| --------------- | ------------------- | ------------ | -------------- | -------------------- | ------------ |
| **Activation**  | Automatic           | Manual (`/`) | Semi-auto      | Selection            | Event-driven |
| **Purpose**     | Standards           | Tasks        | Capabilities   | Personas             | Automation   |
| **Content**     | Instructions        | Prompts      | Multi-file     | Instructions + Tools | Commands     |
| **Portability** | VS Code/GitHub      | VS Code      | Cross-platform | VS Code              | VS Code      |
| **Complexity**  | Low                 | Low          | High           | Medium               | Medium       |

### File Extensions

| Type                | Extension                 |
| ------------------- | ------------------------- |
| Custom Instructions | `.md`, `.instructions.md` |
| Prompt Files        | `.prompt.md`              |
| Custom Agents       | `.agent.md`               |
| Agent Skills        | `SKILL.md` (in directory) |
| Hooks               | `.json`                   |

### Hook Events Quick Reference

| Event              | Blocks | Can Modify Input | Common Use             |
| ------------------ | ------ | ---------------- | ---------------------- |
| `SessionStart`     | No     | No               | Inject context         |
| `UserPromptSubmit` | No     | No               | Audit, inject          |
| `PreToolUse`       | Yes    | Yes              | Block, approve, modify |
| `PostToolUse`      | Yes    | No               | Format, validate       |
| `PreCompact`       | No     | No               | Save state             |
| `SubagentStart`    | No     | No               | Track, init            |
| `SubagentStop`     | No     | No               | Aggregate, cleanup     |
| `Stop`             | Yes    | No               | Final validation       |

### Permission Decision Values (PreToolUse)

| Value     | Effect                    |
| --------- | ------------------------- |
| `"allow"` | Proceed without prompting |
| `"ask"`   | Prompt user for approval  |
| `"deny"`  | Block the operation       |

**Priority:** `deny` > `ask` > `allow`

---

## Related Resources

- [VS Code Copilot Documentation](https://code.visualstudio.com/docs/copilot/agents)
- [Customization Overview](https://code.visualstudio.com/docs/copilot/customization/overview)
- [Agent Skills Specification](https://agentskills.io)
- [Awesome Copilot Repository](https://github.com/github/awesome-copilot)
- [Anthropic Skills Repository](https://github.com/anthropics/skills)
