# Rule Template Reference

## File Placement

Rules live in `.claude/rules/<topic>.md`. Two loading modes:

- **No frontmatter** — loads unconditionally at launch alongside CLAUDE.md
- **With `paths:` frontmatter** — loads only when a matching file is opened (saves context)

### Path-scoped Rule File

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "src/**/*.{ts,tsx}"
---

# API Rules

- All endpoints must validate input
- Return `{ error: string, code: number }` shapes
```

Supported glob patterns: `**/*.ts`, `src/**/*`, `*.md`, `src/**/*.{ts,tsx}`

---

## Rule Structure

### Basic Rule (Bullet Point)

```markdown
## Category Name

- Use clear, actionable statement
- Another rule in same category
```

### Rule with Rationale (preferred)

```markdown
## Category Name

- **Rule:** Use named exports for all components
- **Why:** Named exports enable better tree-shaking and IDE autocompletion
```

> This is the recommended pattern for most rules. It captures intent without tying the rule to a specific implementation.

### Rule with Example (user-requested only)

> **Only use code examples when the user explicitly asks for them.** Prefer descriptive prose over code blocks — rules should remain correct regardless of implementation changes.

````markdown
## Category Name

- Use named exports for components

  ```typescript
  // Good
  export function Button({ children }) { ... }

  // Avoid
  export default function Button({ children }) { ... }
  ```
````

````

### Rule with Constraints

```markdown
## Error Handling

- Always handle errors in async operations
  - Log errors with context
  - Return meaningful error messages to users
  - Never expose internal details in error messages
````

## Standard Categories

Organize rules under these standard categories:

1. **Code Style** - Formatting, indentation, quotes, semicolons
2. **Naming Conventions** - File, function, variable, component naming
3. **File Organization** - Directory structure, file placement
4. **Error Handling** - Try/catch, error logging, user messages
5. **Testing** - Test structure, naming, coverage
6. **Security** - Input validation, sanitization, auth
7. **Performance** - Optimization, lazy loading, caching
8. **Documentation** - Comments, README, API docs
9. **Dependencies** - Package management, version pinning
10. **Git/Version Control** - Commit messages, branch naming

## Rule Quality Checklist

Before adding a rule, verify:

- [ ] **Specific** - Is it actionable? (Not "write clean code")
- [ ] **Justified** - Is there a reason this rule exists?
- [ ] **Consistent** - Does it conflict with existing rules?
- [ ] **Scopable** - Is it clear when the rule applies?
- [ ] **Enforceable** - Can it be verified programmatically or by review?
- [ ] **Abstract** - Does the rule avoid specific code examples? (Unless user requested)

## Vague vs Specific Examples

| Vague (Avoid)          | Specific (Use)                                           |
| ---------------------- | -------------------------------------------------------- |
| Follow best practices  | Use React Testing Library for component tests            |
| Write clean code       | Functions should be under 50 lines                       |
| Handle errors properly | Wrap async operations in try/catch, log to console.error |
| Use good naming        | Use camelCase for variables, PascalCase for components   |
| Format code correctly  | Use 2-space indentation, single quotes for strings       |

## Using Imports for Large Rule Sets

When rules become extensive, split into separate files:

```markdown
# Project Memory

@./.claude/rules/code-style.md
@./.claude/rules/testing.md
@./.claude/rules/security.md
```

This keeps CLAUDE.md readable and allows focused updates.

## Target File Size

Keep each CLAUDE.md or rules file **under 200 lines**. Longer files:
- Consume more context tokens
- Reduce adherence to instructions

If a file grows large, split into topic-specific files in `.claude/rules/`.

## Sharing Rules Across Projects

Use symlinks to share common rule sets:

```bash
# Link a shared directory
ln -s ~/shared-claude-rules .claude/rules/shared

# Link an individual file
ln -s ~/company-standards/security.md .claude/rules/security.md
```

Symlinks are resolved normally. Circular symlinks are detected and handled gracefully.
