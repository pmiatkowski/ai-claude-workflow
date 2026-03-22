# Claude Code Skill Creation Guidelines

Comprehensive reference for creating local and global skills in Claude Code.

## What Are Skills

Skills extend Claude's capabilities by providing custom instructions in a `SKILL.md` file. Claude can:
- Load skills automatically when relevant (based on description)
- Be invoked directly via `/skill-name`
- Run in isolated subagents

**Note**: Custom commands (`.claude/commands/`) have been merged into skills. Both work the same way, but skills offer additional features like supporting files, frontmatter control, and subagent execution.

## Skill Locations

| Location | Path | Scope |
|----------|------|-------|
| Enterprise | Managed settings | All users in organization |
| Personal (Global) | `~/.claude/skills/<skill-name>/SKILL.md` | All your projects |
| Project (Local) | `.claude/skills/<skill-name>/SKILL.md` | This project only |
| Plugin | `<plugin>/skills/<skill-name>/SKILL.md` | Where plugin is enabled |

**Priority**: enterprise > personal > project. Plugin skills use `plugin-name:skill-name` namespace.

### Nested Directory Discovery

Claude Code automatically discovers skills from nested `.claude/skills/` directories. When editing `packages/frontend/`, skills in `packages/frontend/.claude/skills/` are also loaded.

## SKILL.md Structure

```markdown
---
name: my-skill
description: What this skill does and when to use it
argument-hint: [required-arg] [optional-arg]
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Grep, Glob
context: fork
agent: Explore
---

Your skill instructions here...
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | No | Display name (lowercase letters, numbers, hyphens; max 64 chars). Defaults to directory name. |
| `description` | **Recommended** | What the skill does and when to use it. Claude uses this to decide when to auto-load. |
| `argument-hint` | No | Shown during autocomplete. Example: `[issue-number]` or `<filename> [format]` |
| `disable-model-invocation` | No | Set `true` to prevent Claude from auto-loading. Use for manual-only workflows. Default: `false` |
| `user-invocable` | No | Set `false` to hide from `/` menu. Use for background knowledge. Default: `true` |
| `allowed-tools` | No | Tools Claude can use without permission when skill is active |
| `model` | No | Model to use when skill is active |
| `context` | No | Set `fork` to run in isolated subagent context |
| `agent` | No | Subagent type when `context: fork` (e.g., `Explore`, `Plan`, `general-purpose`) |
| `hooks` | No | Hooks scoped to skill lifecycle |

### Invocation Control Matrix

| Frontmatter | User can invoke | Claude can invoke | Context loading |
|-------------|-----------------|-------------------|-----------------|
| (default) | Yes | Yes | Description always in context, full skill loads when invoked |
| `disable-model-invocation: true` | Yes | No | Description not in context, loads only on user invoke |
| `user-invocable: false` | No | Yes | Description always in context, full skill loads when invoked |

## String Substitutions

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed when invoking |
| `$ARGUMENTS[N]` | Access argument by 0-based index |
| `$N` | Shorthand for `$ARGUMENTS[N]` (e.g., `$0`, `$1`) |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `${CLAUDE_SKILL_DIR}` | Directory containing SKILL.md |

**Note**: If `$ARGUMENTS` is not present in content, arguments are appended as `ARGUMENTS: <value>`.

### Example

```markdown
---
name: fix-issue
description: Fix a GitHub issue
disable-model-invocation: true
---

Fix GitHub issue $ARGUMENTS following our coding standards.
```

Usage: `/fix-issue 123` → "Fix GitHub issue 123 following our coding standards."

## Supporting Files

Skills can include multiple files in their directory:

```
my-skill/
├── SKILL.md           # Main instructions (required)
├── reference.md       # Detailed API docs
├── examples.md        # Usage examples
└── scripts/
    └── helper.py      # Utility scripts
```

Reference supporting files from SKILL.md:
```markdown
## Additional resources
- For API details, see [reference.md](reference.md)
- For examples, see [examples.md](examples.md)
```

**Best practice**: Keep SKILL.md under 500 lines. Move detailed content to separate files.

## Advanced Patterns

### Dynamic Context Injection

Use `!`command`` syntax to run shell commands before skill content is sent to Claude:

```markdown
---
name: pr-summary
description: Summarize changes in a pull request
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---

## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
- Changed files: !`gh pr diff --name-only`

## Your task
Summarize this pull request...
```

The commands execute first, output replaces placeholders, then Claude receives the rendered content.

### Running in Subagent

Add `context: fork` to run skill in isolation. The skill content becomes the subagent prompt:

```markdown
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---

Research $ARGUMENTS thoroughly:
1. Find relevant files using Glob and Grep
2. Read and analyze the code
3. Summarize findings with specific file references
```

**Agent types**: `Explore`, `Plan`, `general-purpose`, or custom subagent from `.claude/agents/`.

### Visual Output Pattern

Skills can bundle scripts that generate HTML for browser visualization:

```markdown
---
name: codebase-visualizer
description: Generate interactive tree visualization
allowed-tools: Bash(python *)
---

Run the visualization script:
```bash
python ${CLAUDE_SKILL_DIR}/scripts/visualize.py .
```
```

## Tool Restrictions

Use `allowed-tools` to limit what Claude can do:

```markdown
---
name: safe-reader
description: Read files without making changes
allowed-tools: Read, Grep, Glob
---
```

Format: `ToolName` or `ToolName(pattern)` for restricted Bash commands.

## Permissions Control

### Disable All Skills
```
# In /permissions deny rules:
Skill
```

### Allow/Deny Specific Skills
```
# Allow only specific skills
Skill(commit)
Skill(review-pr *)

# Deny specific skills
Skill(deploy *)
```

### Hide Individual Skills
Add `disable-model-invocation: true` to frontmatter.

## Types of Skill Content

### Reference Content
Adds knowledge Claude applies inline:
```markdown
---
name: api-conventions
description: API design patterns for this codebase
---

When writing API endpoints:
- Use RESTful naming conventions
- Return consistent error formats
```

### Task Content
Step-by-step instructions for specific actions:
```markdown
---
name: deploy
description: Deploy the application
disable-model-invocation: true
---

1. Run the test suite
2. Build the application
3. Push to deployment target
```

## Quick Reference: Creating a Skill

1. **Create directory**:
   ```bash
   # Local (project-specific)
   mkdir -p .claude/skills/my-skill

   # Global (all projects)
   mkdir -p ~/.claude/skills/my-skill
   ```

2. **Create SKILL.md**:
   ```markdown
   ---
   name: my-skill
   description: What it does and when Claude should use it
   ---

   Instructions for Claude...
   ```

3. **Test**:
   - Let Claude invoke: ask something matching the description
   - Direct invoke: `/my-skill [args]`

## Troubleshooting

### Skill Not Triggering
1. Check description includes natural keywords
2. Verify skill appears in "What skills are available?"
3. Rephrase request to match description
4. Try direct invocation with `/skill-name`

### Skill Triggers Too Often
1. Make description more specific
2. Add `disable-model-invocation: true`

### Claude Doesn't See All Skills
- Skill descriptions have a dynamic budget (~2% of context window, min 16,000 chars)
- Run `/context` to check for excluded skills warning
- Override with `SLASH_COMMAND_TOOL_CHAR_BUDGET` env variable

## Extended Thinking

Include the word "ultrathink" anywhere in skill content to enable extended thinking mode.
