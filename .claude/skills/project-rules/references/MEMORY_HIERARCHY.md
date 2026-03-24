# CLAUDE.md Memory Hierarchy Reference

## Hierarchy Overview

Claude Code loads memory from multiple sources. **More specific locations take precedence over broader ones.**

```
┌──────────────────────────────────────────────┐
│  1. Managed Policy (highest priority)         │
│     macOS:   /Library/Application Support/    │
│              ClaudeCode/CLAUDE.md             │
│     Linux:   /etc/claude-code/CLAUDE.md       │
│     Windows: C:\Program Files\ClaudeCode\     │
│              CLAUDE.md                        │
├──────────────────────────────────────────────┤
│  2. Project Instructions (team-shared)        │
│     ./CLAUDE.md  or  ./.claude/CLAUDE.md      │
│     ./.claude/rules/*.md  (modular rules)     │  ← Default for rules
├──────────────────────────────────────────────┤
│  3. User Instructions (personal)              │
│     ~/.claude/CLAUDE.md                       │
│     ~/.claude/rules/*.md                      │
└──────────────────────────────────────────────┘
```

> **Loading order vs priority:** User-level rules are loaded *before* project rules, but project rules have *higher priority* (they override conflicting user rules).

> **Note:** `./CLAUDE.local.md` is deprecated. Use `@path` imports or `.claude/rules/` instead.

## How CLAUDE.md Files Load

### Directory Tree Walking

Claude Code reads CLAUDE.md files by walking **up** the directory tree from your current working directory. If you run Claude Code in `foo/bar/`, it loads instructions from both `foo/bar/CLAUDE.md` and `foo/CLAUDE.md`.

### On-Demand Loading for Subdirectories

CLAUDE.md files in subdirectories **under** your current working directory are **not** loaded at launch. They load on-demand when Claude reads files in those subdirectories.

### Additional Directories

The `--add-dir` flag gives Claude access to directories outside your main working directory. By default, CLAUDE.md files from these directories are **not** loaded.

To also load CLAUDE.md files from additional directories, set the environment variable:

```bash
CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 claude --add-dir ../shared-config
```

## The `.claude/rules/` Directory

The preferred way to organize rules for non-trivial projects.

- **All `.md` files** in `.claude/rules/` are discovered recursively
- **No frontmatter** → loads unconditionally at launch (same priority as `.claude/CLAUDE.md`)
- **With `paths:` frontmatter** → loads only when a matching file is opened (saves context)
- Subdirectories are supported: `frontend/`, `backend/`, etc.
- **Symlinks are supported** for shared rule sets (circular symlinks are handled gracefully)

### Path-scoped Rule Format

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "src/**/*.{ts,tsx}"
  - "tests/**/*.test.ts"
---

# API Development Rules

- All API endpoints must include input validation
- Return consistent error shapes: `{ error: string, code: number }`
```

### Symlinks for Shared Rules

Link shared rule sets across projects:

```bash
# Link a shared directory
ln -s ~/shared-claude-rules .claude/rules/shared

# Link an individual file
ln -s ~/company-standards/security.md .claude/rules/security.md
```

### Example Structure

```
project/
├── CLAUDE.md                      # Main instructions (keep under 200 lines)
└── .claude/
    └── rules/
        ├── code-style.md          # Loads unconditionally
        ├── testing.md             # Loads unconditionally
        ├── api.md                 # Path-scoped: src/api/**/*.ts only
        ├── shared -> ~/shared-rules/  # Symlinked shared rules
        └── frontend/
            └── components.md      # Path-scoped: src/components/**/*.tsx
```

## When to Use Each Level

### Managed Policy (Enterprise)

- **Scope:** All users, all projects on the machine
- **Use for:** Company-wide security policies, compliance rules
- **Edited by:** System administrators only
- **Cannot be excluded:** Managed policy CLAUDE.md files always apply

### Project Instructions (`./CLAUDE.md` + `.claude/rules/`)

- **Scope:** All users working on this project
- **Use for:** Project-specific conventions, architecture decisions, team standards
- **Shared via:** Git (checked into repository)
- **Target size:** Keep each file under 200 lines

### User Instructions (`~/.claude/CLAUDE.md`)

- **Scope:** Current user, all projects
- **Use for:** Personal preferences, individual workflow
- **Not shared:** Lives in home directory
- **Priority:** Loaded before project rules, but project rules override conflicts

## Import Syntax

Use `@path/to/file` anywhere in a CLAUDE.md or rules file to inline another file.

```markdown
# Project Memory

@~/.claude/personal-preferences.md
@./docs/ai-guidelines.md
@./.claude/rules/testing.md
```

- `@~/.claude/...` — resolves to home directory
- `@./...` — resolves relative to the file containing the import
- Maximum import depth: 5 hops

## Decision Flow for Rule Placement

```
User wants to add a rule
         │
         ▼
┌────────────────────────┐
│ Company-wide security/ │──Yes──▶ Managed Policy
│ compliance requirement?│
└────────────────────────┘
         │ No
         ▼
┌────────────────────────┐
│ Should the whole team  │──Yes──▶ .claude/rules/<topic>.md
│ follow this on this    │         (or ./CLAUDE.md if very short)
│ project?               │
└────────────────────────┘
         │ No
         ▼
┌────────────────────────┐
│ Personal preference    │──Yes──▶ ~/.claude/CLAUDE.md
│ across all projects?   │
└────────────────────────┘
         │ No
         ▼
    .claude/rules/<topic>.md  (project-scoped, team-shared)
```

## Merging Behavior

When multiple CLAUDE.md / rules files exist, Claude Code merges them:

1. **Conflicting rules**: More specific location wins (project > user)
2. **Non-conflicting rules**: All are included
3. **Monorepos**: Use `claudeMdExcludes` to skip irrelevant CLAUDE.md files

### Excluding Files with `claudeMdExcludes`

```json
// .claude/settings.local.json
{
  "claudeMdExcludes": [
    "**/monorepo/CLAUDE.md",
    "/home/user/monorepo/other-team/.claude/rules/**"
  ]
}
```

Patterns are matched against absolute file paths using glob syntax. You can configure this at any settings layer. **Managed policy CLAUDE.md files cannot be excluded.**

## Common Patterns

### Pattern 1: Simple Project
One `./CLAUDE.md` with everything inline.

### Pattern 2: Modular Project
`./CLAUDE.md` as a short overview; detailed rules split into `.claude/rules/*.md`.

### Pattern 3: Path-scoped Efficiency
Use `paths:` frontmatter so rules only load for relevant files, keeping the context window lean.

### Pattern 4: Personal + Team
- `./CLAUDE.md` for team rules
- `~/.claude/CLAUDE.md` for personal preferences (not checked in)

### Pattern 5: Shared Rules Across Projects
Use symlinks to share common rules:

```bash
# One shared rules directory, linked into multiple projects
ln -s ~/company-standards/.claude/rules .claude/rules/company
```
