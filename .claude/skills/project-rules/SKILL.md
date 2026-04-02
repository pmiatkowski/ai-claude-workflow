---
name: project-rules
description: |
  Manage coding guidelines and CLAUDE.md rules. Use when the user explicitly asks to
  add, change, delete, analyze, or discover coding conventions and rules.
  Trigger ONLY on: "add rule", "add coding rule", "change coding guidelines",
  "analyze rules", "discover coding conventions", "coding standards review".
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Rules Skill

Manage Claude Code coding guidelines stored in CLAUDE.md files and `.claude/rules/` directory.

## Memory Hierarchy

When modifying rules, understand the target location. **More specific locations take precedence over broader ones.**

| Priority    | Location           | Scope                      | Path                                                                                         |
| ----------- | ------------------ | -------------------------- | -------------------------------------------------------------------------------------------- |
| 1 (highest) | Managed Policy     | All users, all projects    | macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`<br>Linux: `/etc/claude-code/CLAUDE.md`<br>Windows: `C:\Program Files\ClaudeCode\CLAUDE.md` |
| 2           | Project Rules      | All users, this project    | `./CLAUDE.md` or `./.claude/CLAUDE.md`<br>`./.claude/rules/*.md` (modular, path-scoped)     |
| 3           | User Instructions  | Current user, all projects | `~/.claude/CLAUDE.md`<br>`~/.claude/rules/*.md`                                              |

> **Loading order vs priority:** User-level rules are loaded *before* project rules, but project rules have *higher priority* (they override conflicting user rules).

> `./CLAUDE.local.md` is **deprecated** — use `.claude/rules/` or `@path` imports instead.

**Default assumption**: Unless specified otherwise, add rules to `.claude/rules/<topic>.md` (project memory). Use `./CLAUDE.md` only for short, project-overview-level instructions.

## Actions

### ADD Rules

Add new rules to a CLAUDE.md file or `.claude/rules/*.md` file.

**Input sources:**

1. From file: User provides path to file containing rules
2. From text: User provides rule text directly
3. From discovery: Generated from codebase scan (see DISCOVER)

**Process:**

1. Determine target file (ask if unclear):
   - Broad project overview → `./CLAUDE.md`
   - Topic-specific or path-scoped → `.claude/rules/<topic>.md` (preferred for modularity)
   - Personal preference → `~/.claude/CLAUDE.md`
2. Read existing content to understand structure
3. Parse new rules and categorize them
4. Find appropriate section or create new one
5. Format rules according to template (see references/RULE_TEMPLATE.md)
6. If path-scoped (e.g. only applies to `src/api/**`), add `paths:` frontmatter
7. Insert maintaining markdown structure
8. For large rule sets, split across `.claude/rules/*.md` files and reference via `@path` imports in CLAUDE.md

**Rule Abstraction Principle:**

Rules must be high-level and implementation-agnostic. Describe **what** and **why**, not **how** with specific code.

- **DO**: State rules as principles — "Validate all external input at system boundaries", "Use consistent error response shapes across all API endpoints"
- **DO NOT**: Include code examples, specific function signatures, or implementation snippets unless the user explicitly asks for them
- **Rationale**: Code examples become stale when implementations change. High-level rules remain correct regardless of framework version, library choice, or refactoring

If a rule is hard to understand without an example, use a descriptive phrase instead:
- Instead of a code block showing a function signature, write: "Wrap async operations in try/catch, log errors to the configured logger, and return user-safe messages"
- Instead of a code block showing an import pattern, write: "Use named exports for all shared modules"

**Example insertion:**

- Use consistent indentation across all source files
- Prefer single quotes for strings in JavaScript and TypeScript
- Include trailing commas in multiline data structures

### CHANGE Rules

Modify existing rules in a CLAUDE.md or `.claude/rules/*.md` file.

**Process:**

1. Search CLAUDE.md and `.claude/rules/` for rules matching the query using Grep/Read
2. Present all matching rules with context (section, surrounding rules)
3. Ask user to confirm which rule(s) to modify
4. Accept the modification (full replacement or guided edit)
5. Apply change preserving formatting and structure

**Matching strategies:**

- Exact section name match
- Keyword search within rule text
- Fuzzy match for partial queries

**Example:**

```
User: /rules change indentation
Found in section "Code Style":
  "- Use tabs for indentation"
Change to: "- Use 2-space indentation"
```

### DELETE Rules

Remove rules from a CLAUDE.md or `.claude/rules/*.md` file.

**Process:**

1. Search CLAUDE.md and `.claude/rules/` for rules matching the query
2. Present all matching rules with context
3. Ask user to confirm deletion
4. Remove rule cleanly
5. If section becomes empty, ask whether to remove section
6. Clean up any orphaned `@import` references

**Example:**

```
User: /rules delete jquery
Found in section "Dependencies":
  "- Use jQuery for DOM manipulation"
Delete this rule? [Y/n]
```

### ANALYZE Rules

Analyze current CLAUDE.md and `.claude/rules/*.md` rules for quality issues.

**Analysis dimensions:**

1. **Coverage** - What aspects of development are covered?
   - Code style, naming, file organization, error handling, testing, security, performance, documentation, dependencies, git

2. **Conflicts** - Are there contradictory rules?
   - Example: "Use tabs" vs "Use 2-space indentation"

3. **Redundancy** - Duplicate or overlapping rules?

4. **Specificity** - Are rules actionable?
   - Vague: "Follow best practices", "Write clean code"
   - Specific: "Use 2-space indentation", "Name components with PascalCase"

5. **Organization** - Is the structure logical?
   - Consistent heading levels
   - Logical grouping
   - Appropriate section ordering

**Output:** Score (X/10), coverage table by category with gaps, issues table (type, location, issue, recommendation), suggestions list.

### DISCOVER Rules

Scan codebase to discover existing conventions and suggest rules.

**Discovery process:**

1. **Detect Tech Stack**
   - Check for: package.json, Cargo.toml, pyproject.toml, go.mod, etc.
   - Identify frameworks: React, Vue, Django, Rails, etc.
   - Identify test frameworks: Jest, pytest, Go test, etc.

2. **Analyze File Naming**
   - Use Glob to find patterns: `*.tsx`, `*.test.ts`, `*.spec.js`, `test_*.py`
   - Detect conventions: PascalCase, camelCase, kebab-case
   - Identify suffixes: .test, .spec, .module, .config

3. **Analyze Directory Structure**
   - Common directories: src/, lib/, components/, hooks/, utils/
   - Colocation patterns (tests next to source vs separate)

4. **Analyze Code Patterns**
   - Use Grep to find import patterns
   - Detect export patterns (named vs default)
   - Identify comment conventions
   - Find error handling patterns

5. **Check Existing Configs**
   - Linting: .eslintrc, ruff.toml, clippy.toml
   - Formatting: .prettierrc, .editorconfig
   - CI/CD: .github/workflows/, .gitlab-ci.yml

**Output:** Sections for tech stack, file naming patterns (table), directory structure, import patterns, existing configs, and suggested rules by category. End with "Add these rules to CLAUDE.md? [all/selective/none]"

## Reference Files

- `references/RULE_TEMPLATE.md` - Template for writing rules

## Best Practices

1. **Be Specific**: "Use 2-space indentation" > "Format code properly"
2. **Use Structure**: Organize with markdown headings and bullet points
3. **Keep Rules Abstract**: Write high-level rules without code examples — only add code examples when the user explicitly requests them
4. **Keep Current**: Review and update rules as project evolves
5. **Use Imports**: For large rule sets, use `@path/to/import` syntax
6. **Avoid Redundancy**: Don't duplicate rules across sections
7. **One Concept Per Rule**: Keep rules focused and atomic
8. **Target 200 Lines**: Keep each CLAUDE.md or rules file under 200 lines for better adherence
9. **Use Symlinks**: Share common rules across projects with symlinks: `ln -s ~/shared-rules .claude/rules/shared`
10. **Path-Scoped Rules**: Use `paths:` frontmatter to load rules only for relevant files, saving context
