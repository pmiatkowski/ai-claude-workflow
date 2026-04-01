# Skill Creation Reference

Quick reference for creating skills in Claude Code.

## SKILL.md Frontmatter

| Field | Required | Description |
|-------|----------|-------------|
| `name` | No | Display name (max 64 chars). Defaults to directory name. |
| `description` | **Recommended** | What the skill does. Claude uses this to decide when to auto-load. |
| `argument-hint` | No | Shown during autocomplete. |
| `disable-model-invocation` | No | `true` to prevent auto-loading. Default: `false` |
| `user-invocable` | No | `false` to hide from `/` menu. Default: `true` |
| `allowed-tools` | No | Tools Claude can use without permission. |
| `model` | No | Model to use when skill is active. |
| `context` | No | Set `fork` to run in isolated subagent. |
| `agent` | No | Subagent type when `context: fork` (e.g., `Explore`, `Plan`, `general-purpose`). |

## String Substitutions

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed when invoking |
| `$ARGUMENTS[N]` | Access argument by 0-based index |
| `$N` | Shorthand for `$ARGUMENTS[N]` |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `${CLAUDE_SKILL_DIR}` | Directory containing SKILL.md |

**Note**: If `$ARGUMENTS` is not present in content, arguments are appended as `ARGUMENTS: <value>`.

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

Reference supporting files from SKILL.md using relative links. Keep SKILL.md under 500 lines.

## Advanced Patterns

### Dynamic Context Injection
Use `!`command`` syntax to run shell commands before content is sent to Claude. The commands execute first, output replaces placeholders, then Claude receives the rendered content.

### Running in Subagent
Add `context: fork` and `agent: Explore|Plan|general-purpose` for isolation. The skill content becomes the subagent prompt.

### Tool Restrictions
Use `allowed-tools` to limit what Claude can do. Format: `ToolName` or `ToolName(pattern)` for restricted Bash commands.

## Content Types

### Reference Content (adds knowledge Claude applies inline)
```yaml
---
name: api-conventions
description: API design patterns for this codebase
---
When writing API endpoints:
- Use RESTful naming conventions
- Return consistent error formats
```

### Task Content (step-by-step instructions for specific actions)
```yaml
---
name: deploy
description: Deploy the application
disable-model-invocation: true
---
1. Run the test suite
2. Build the application
3. Push to deployment target
```

## Quick Reference

1. **Create directory**: `mkdir -p .claude/skills/my-skill`
2. **Create SKILL.md** with frontmatter + instructions
3. **Test**: `/my-skill [args]` or trigger via description match
