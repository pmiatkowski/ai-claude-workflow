# Workflow Token Optimization Plan -- Phase 3

## Current State

| Category | Bytes | Files | Notes |
|----------|-------|-------|-------|
| Skills | 60,428 | 10 | 2 skills + 1 reference dir; largest category by far |
| Commands | 42,403 | 14 | Stable after fix-2 |
| Agents | 24,130 | 9 | Stable after fix-2 |
| References | 18,210 | 9 | shared-patterns + prd-templates + 7 report files |
| Verification | 8,121 | 3 | JS-specific commands embedded |
| Hook | 3,595 | 1 | Python mode full, grep fallback degraded |
| **Total** | **156,887** | **46** | |

**The dominant cost is skills.** The two skills (docs, project-rules) total 52,336 bytes of eagerly loadable content with high false-trigger risk. When a user casually says "docs" or "convention" in conversation, the entire skill plus all its references load into context. This is ~18,000-25,000 tokens wasted on a false trigger.

**Target: Reduce skill token cost by ~45%, eliminate JS-specific bias in verification rules, inline shared-patterns to remove a file and an indirection layer, make exit contracts file-based and deterministic, and fix the grep fallback degradation that causes redundant state.yml reads.**

---

## Strategy Overview

Six strategies ordered by impact (tokens saved in user projects) multiplied by effort.

| # | Strategy | Estimated Impact | Effort | Type |
|---|----------|-----------------|--------|------|
| 1 | Compress skills -- trim references, delete duplicates, tighten triggers | ~24,000 bytes saved on false trigger; ~3,500 bytes saved on correct trigger | Medium | Token reduction |
| 2 | Move new-skill to references | 8,092 bytes relocated; no token savings (already lazy), cleaner organization | Low | Cleanup |
| 3 | Make verification rules project-agnostic | ~800 bytes of JS-specific content refactored; correctness fix for non-JS projects | Medium | Correctness |
| 4 | Inline shared-patterns sections and delete the file | 3,076 bytes indirection eliminated; 4 files updated | Low | Token reduction |
| 5 | File-based exit contracts | Deterministic parsing; no token change | Medium | Reliability |
| 6 | Fix grep fallback + eliminate redundant state.yml reads | ~600 bytes of redundant reads eliminated per agent spawn | Medium | Reliability + tokens |

---

## Strategy 1: Compress Skills -- Trim References, Delete Duplicates, Tighten Triggers

### Problem

The two skills represent 52,336 bytes of eagerly loadable content. Their trigger words ("docs", "documentation", "README", "convention", "CLAUDE.md") have very high false-trigger rates -- they match common conversational terms that have nothing to do with documentation management or coding rules. When triggered, all references load into context.

Three specific waste sources:

1. **SEARCH_PATTERNS.md** (4,179 bytes) -- Teaches Claude how to use grep, glob, case sensitivity, synonym expansion, and regex patterns. Claude already has built-in Grep and Glob tools with these capabilities. The entire file duplicates what Claude natively knows how to do.

2. **MEMORY_HIERARCHY.md** (7,819 bytes) -- Documents Claude Code's own CLAUDE.md loading system: directory tree walking, `paths:` frontmatter, `claudeMdExcludes`, import syntax, decision flow charts. Claude already knows all of this -- it is a reference about Claude's own architecture. The only useful content is the "where to put rules" decision, which is already stated in 3 lines of the SKILL.md Memory Hierarchy table.

3. **DISCOVERY_PATTERNS.md** (5,530 bytes) -- Contains generic tech-stack detection tables (package.json means JavaScript, Cargo.toml means Rust, etc.), file naming patterns, directory structure patterns, and grep regex patterns for imports/exports/comments. Claude already knows all of this. The DISCOVER action in SKILL.md already describes the process -- the reference file just restates the same instructions with more tables.

### Files Affected

| File | Bytes | Action |
|------|-------|--------|
| `skills/docs/SKILL.md` | 7,713 | Tighten triggers, trim output format examples |
| `skills/docs/references/SEARCH_PATTERNS.md` | 4,179 | **DELETE** entirely |
| `skills/docs/references/DUPLICATE_CHECK.md` | 5,862 | Compress to protocol-only (~1,500 bytes) |
| `skills/docs/references/README_TEMPLATE.md` | 3,594 | Keep (template content, not instructional) |
| `skills/docs/references/FEATURE_DOC_TEMPLATE.md` | 3,966 | Keep (template content, not instructional) |
| `skills/project-rules/SKILL.md` | 9,766 | Tighten triggers, trim output format examples |
| `skills/project-rules/references/DISCOVERY_PATTERNS.md` | 5,530 | **DELETE** entirely |
| `skills/project-rules/references/MEMORY_HIERARCHY.md` | 7,819 | **DELETE** entirely |
| `skills/project-rules/references/RULE_TEMPLATE.md` | 3,907 | Keep (template content, not instructional) |

### Fix

#### 1a. Tighten skill triggers

The description field in each SKILL.md frontmatter controls when Claude auto-loads the skill. Broader terms cause more false triggers.

**Before** (`skills/docs/SKILL.md` lines 2-8):

```yaml
description: |
  Manage project documentation (README.md, ./docs/*.md). Use when the user wants to
  initialize, research, add, change, delete, or scan documentation. Triggers include:
  "docs", "documentation", "README", "initialize docs", "update docs", "find in docs",
  "living docs", "project documentation".
```

**After**:

```yaml
description: |
  Manage project documentation structure. Use when the user explicitly asks to
  initialize, research, add, change, delete, or scan project documentation files.
  Trigger ONLY on: "initialize docs", "update docs", "project docs", "scan docs",
  "docs init", "docs research", "docs add", "docs scan".
```

Removes high-frequency false triggers: "docs", "documentation", "README", "find in docs", "living docs", "project documentation". Users who want the skill can still use `/project-docs <action>` directly or say "initialize docs" / "update docs" etc.

**Before** (`skills/project-rules/SKILL.md` lines 2-8):

```yaml
description: |
  Manage coding guidelines and CLAUDE.md rules. Use when the user wants to
  add, change, delete, analyze, or discover coding conventions. Triggers
  include: "add rule", "coding guidelines", "convention", "CLAUDE.md",
  "coding standard", "project rules", "discover patterns".
```

**After**:

```yaml
description: |
  Manage coding guidelines and CLAUDE.md rules. Use when the user explicitly asks to
  add, change, delete, analyze, or discover coding conventions and rules.
  Trigger ONLY on: "add rule", "add coding rule", "change coding guidelines",
  "analyze rules", "discover coding conventions", "coding standards review".
```

Removes high-frequency false triggers: "convention", "CLAUDE.md", "project rules", "discover patterns". These terms appear constantly in normal conversation.

#### 1b. Delete SEARCH_PATTERNS.md (4,179 bytes saved)

The docs-researcher agent (`.claude/agents/docs-researcher.md`) already contains search instructions that cover query decomposition, synonym expansion, and multi-source searching. The SEARCH_PATTERNS.md file adds nothing beyond what Claude already does natively with its Grep and Glob tools.

**Before** (SKILL.md references section):

```markdown
- `references/SEARCH_PATTERNS.md` - Patterns for effective documentation search
```

**After** (remove the line entirely):

```markdown
- `references/README_TEMPLATE.md` - Industry-standard README template
- `references/FEATURE_DOC_TEMPLATE.md` - Template for ./docs/*.md files
- `references/DUPLICATE_CHECK.md` - Duplicate detection protocol
```

Then delete `skills/docs/references/SEARCH_PATTERNS.md`.

#### 1c. Compress DUPLICATE_CHECK.md (5,862 -> ~1,500 bytes)

The current file contains 4 detection strategies (title matching, content overlap, scope analysis, code symbol reference) with extended examples, plus a full resolution process with merge/separate strategies, output templates, and checklists. Much of this is instructional repetition -- Claude already understands fuzzy matching and overlap analysis.

**Before** (`skills/docs/references/DUPLICATE_CHECK.md` -- 5,862 bytes, 236 lines):

Full file with detailed examples, bash commands, resolution strategies, and checklists.

**After** (compressed to ~1,500 bytes, ~60 lines):

```markdown
# Duplicate Detection Protocol

Before adding documentation, check for existing similar content.

## Detection (run all three)

1. **Title match**: Grep README.md and ./docs/*.md for topic keywords (case-insensitive).
   Threshold: any match with >70% title similarity.
2. **Content overlap**: Search existing docs for 3+ key terms from proposed content.
   Threshold: 3+ terms found in single file.
3. **Code symbol check**: Grep for function/class names referenced in proposed content.
   Threshold: 2+ symbols found in existing doc.

## On Match Found

Present to user:
- Existing file path and section
- Overlap details (which terms/symbols matched)
- Options: **Merge** into existing, **Create separate** with cross-reference, **Cancel**

## Not a Duplicate If

- Different audience (users vs developers)
- Different scope (overview vs deep-dive)
- Different format (tutorial vs API reference)
```

This preserves the protocol logic while removing all the verbose examples, bash commands, merge/separate strategy walkthroughs, and checklists that Claude would generate naturally.

#### 1d. Delete MEMORY_HIERARCHY.md (7,819 bytes saved)

This file documents Claude Code's own CLAUDE.md system -- how files load, directory tree walking, `paths:` frontmatter, `claudeMdExcludes`, import syntax, and decision flow charts. Claude already knows all of this. The SKILL.md already contains a concise Memory Hierarchy table that covers the essential placement information.

**Before** (SKILL.md references section):

```markdown
- `references/RULE_TEMPLATE.md` - Template for writing rules
- `references/DISCOVERY_PATTERNS.md` - Detailed discovery patterns
- `references/MEMORY_HIERARCHY.md` - CLAUDE.md hierarchy reference
```

**After**:

```markdown
- `references/RULE_TEMPLATE.md` - Template for writing rules
```

Then delete `skills/project-rules/references/MEMORY_HIERARCHY.md`.

#### 1e. Delete DISCOVERY_PATTERNS.md (5,530 bytes saved)

The DISCOVER action in SKILL.md already provides step-by-step instructions for tech stack detection, file naming analysis, directory structure analysis, code pattern detection, and config extraction. The DISCOVERY_PATTERNS.md reference file restates all of this with additional tables that Claude already knows (e.g., "package.json means JavaScript").

Remove the reference line from SKILL.md. Then delete `skills/project-rules/references/DISCOVERY_PATTERNS.md`.

#### 1f. Trim SKILL.md output format examples

Both SKILL.md files contain verbose markdown output templates for every action. These templates are useful but oversized. Trim the longest ones by removing "Output format" sections that duplicate what the action steps already describe.

In `skills/docs/SKILL.md`, the RESEARCH action has two complete output format templates spanning 43 lines. Trim to inline hints:

**Before** (full markdown output templates for found/not-found):

```markdown
**Output format (found):**

```markdown
# Research Results: <query>

## Summary
[Direct answer synthesized from found information ONLY]

## Sources

### Documentation
| File | Line | Excerpt |
|------|------|---------|
...
```

**Output format (not found):**

```markdown
# Research Results: <query>

**Result:** NO RESULTS for "<query>"

## Locations Searched
...
```
```

**After** (replace with 5 lines):

```markdown
**Output:** If found, provide summary + sources table (file, line, excerpt).
If not found, output "NO RESULTS for <query>" with locations searched and alternative suggestions.
```

Apply the same treatment to the SCAN output format in the same file, and to the ANALYZE and DISCOVER output formats in `skills/project-rules/SKILL.md`.

### Estimated Savings

| Item | Bytes Removed |
|------|--------------|
| Delete SEARCH_PATTERNS.md | 4,179 |
| Delete MEMORY_HIERARCHY.md | 7,819 |
| Delete DISCOVERY_PATTERNS.md | 5,530 |
| Compress DUPLICATE_CHECK.md | ~4,360 (5,862 -> 1,500) |
| Trim SKILL.md output formats | ~2,800 |
| Tightened triggers (fewer false loads) | ~25,000 per avoided false trigger |
| **Total on-disk reduction** | **~24,688 bytes** |

The critical win is not the on-disk size but the per-conversation token savings. With tightened triggers, casual uses of "docs", "README", "convention", or "CLAUDE.md" no longer load 25,000+ bytes of skill content into context. When the skill IS correctly triggered, it loads ~14,300 bytes instead of ~25,300 bytes (docs skill: 7,713 -> ~5,900 + 3,594 + 3,966 + 1,500 = ~14,960; project-rules skill: 9,766 -> ~7,500 + 3,907 = ~11,407).

---

## Strategy 2: Move new-skill to references

### Problem

The file `skills/new-skill/skill-creation-guidelines.md` (8,092 bytes) is not a skill -- it has no SKILL.md file and is never auto-loaded by Claude's skill system. It is reference documentation for humans who want to create new skills. Its current location in `skills/` is misleading and wastes directory listing space during skill discovery.

### Files Affected

| File | Bytes | Action |
|------|-------|--------|
| `skills/new-skill/skill-creation-guidelines.md` | 8,092 | Move to `references/skill-creation-guidelines.md` and trim |

### Fix

Move the file and clean up the now-empty directory.

**Before**:

```
.claude/skills/new-skill/skill-creation-guidelines.md
```

**After**:

```
.claude/references/skill-creation-guidelines.md
```

No code references this file -- it is purely human-facing documentation. The `skills/new-skill/` directory can be deleted after the move.

Additionally, trim the file itself. ~45% (~3,640 bytes) is human-oriented content the agent doesn't need at runtime: "What Are Skills", skill locations table, nested directory discovery, permissions control, troubleshooting, and extended thinking. The agent-relevant content is the frontmatter field reference, string substitutions, supporting files structure, advanced patterns, tool restrictions, and content type patterns.

**Before** (8,092 bytes, 289 lines):

```markdown
# Claude Code Skill Creation Guidelines

Comprehensive reference for creating local and global skills in Claude Code.

## What Are Skills

Skills extend Claude's capabilities by providing custom instructions in a `SKILL.md` file. Claude can:
- Load skills automatically when relevant (based on description)
- Be invoked directly via `/skill-name`
- Run in isolated subagents
...
```

**After** (~4,450 bytes, ~130 lines):

```markdown
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
| `context` | No | Set `fork` to run in isolated subagent. |
| `agent` | No | Subagent type when `context: fork` |

## String Substitutions

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed |
| `$ARGUMENTS[N]` | Argument by 0-based index |

## Supporting Files

Skills can include multiple files:
```
my-skill/
├── SKILL.md           # Main instructions (required)
├── reference.md       # Detailed docs
└── examples.md        # Usage examples
```

## Advanced Patterns

### Dynamic Context Injection
Use `!`command`` syntax to run shell commands before content is sent to Claude.

### Running in Subagent
Add `context: fork` and `agent: Explore|Plan|general-purpose` for isolation.

## Quick Reference

1. Create directory: `mkdir -p .claude/skills/my-skill`
2. Create SKILL.md with frontmatter + instructions
3. Test: `/my-skill [args]` or trigger via description match
```

### Estimated Savings

No direct token savings (file was never loaded in user conversations). On-disk reduction of ~3,640 bytes via content trim. Organizational clarity: `skills/` directory now contains only actual skills.

---

## Strategy 3: Make Verification Rules Project-Agnostic

### Problem

The verification rules in `.claude/verification/` are loaded only by task-verifier in deep mode. They contain 8 hardcoded npm/npx commands and JS-specific content that breaks for non-JavaScript projects:

**quality.md** (lines 115-132) -- "Quality Commands" section:
```bash
npm run lint
npm run type-check
npm run test -- --coverage
npx escomplex .
npx jscpd src/
```

**performance.md** (lines 97-111) -- "Measurement Commands" section:
```bash
npm run build -- --analyze
npx lighthouse <url> --output=json
npx artillery run load-test.yml
```

**quality.md** also has JS-specific checklist items:
- "Type annotations present (TypeScript)"
- "JSDoc for public functions"

**performance.md** has JS/frontend-specific content:
- "Frontend Performance" section references React rendering, bundle size, tree shaking, code splitting
- "Rendering" section references "layout thrashing", "virtual scrolling", "memoization"

**security.md** has JS-specific content:
- "JavaScript/TypeScript" language-specific section: "No `eval()`", "No `innerHTML`", "Helmet.js", "CORS"

This is a **correctness bug**: when task-verifier runs in deep mode on a Python, Go, or Rust project, it tries to run `npm run lint` and checks for TypeScript annotations that don't exist. ~25-30% of the verification content is JS-specific.

### Files Affected

| File | Bytes | Action |
|------|-------|--------|
| `verification/quality.md` | 2,917 | Replace JS commands with discovery protocol, generalize checklist items, inline severity levels |
| `verification/performance.md` | 2,625 | Replace JS commands with discovery protocol, generalize frontend section, inline severity levels |
| `verification/security.md` | 2,579 | Generalize language-specific section, inline severity levels |

### Fix

#### 3a. Replace hardcoded commands with discovery-based approach

**Before** (`verification/quality.md` lines 115-132):

```markdown
## Severity Levels

See `.claude/references/shared-patterns.md#severity-levels` -- use the Quality domain column.

## Quality Commands

```bash
# Linting
npm run lint

# Type checking
npm run type-check

# Test coverage
npm run test -- --coverage

# Complexity analysis
npx escomplex .

# Duplicate detection
npx jscpd src/
```
```

**After**:

```markdown
## Severity Levels

| Level | Quality | Action |
|-------|---------|--------|
| CRITICAL | Blocks release | BLOCK -- Fix immediately |
| HIGH | Significant quality issue | BLOCK -- Fix before merge |
| MEDIUM | Quality concern | WARN -- Fix in current sprint |
| LOW | Minor improvement | INFO -- Address when possible |

## Quality Commands

Discover and run from the project (check in order):
1. `package.json` scripts: lint, type-check, test, build
2. `Makefile` targets: lint, test, type-check, build
3. `CLAUDE.md` dev commands section
4. Phase file Quality Checks section

Run all discovered commands. Report failures with full output.
```

This inlines the severity levels (eliminating the shared-patterns.md reference -- see Strategy 4) and replaces hardcoded npm commands with a language-agnostic discovery protocol.

Apply the same pattern to `verification/performance.md`:

**Before** (`verification/performance.md` lines 97-111):

```markdown
## Severity Levels

See `.claude/references/shared-patterns.md#severity-levels` -- use the Performance domain column.

## Measurement Commands

```bash
# Database query analysis
EXPLAIN ANALYZE <query>

# Bundle size
npm run build -- --analyze

# Lighthouse
npx lighthouse <url> --output=json

# Load testing
npx artillery run load-test.yml
```
```

**After**:

```markdown
## Severity Levels

| Level | Performance | Action |
|-------|-------------|--------|
| CRITICAL | System unusable | BLOCK -- Fix immediately |
| HIGH | Significant degradation | BLOCK -- Fix before merge |
| MEDIUM | Noticeable impact | WARN -- Fix in current sprint |
| LOW | Minor optimization | INFO -- Address when possible |

## Measurement Commands

Discover project tooling:
1. `package.json` scripts: look for build, analyze, benchmark commands
2. `Makefile` targets: look for bench, profile, load-test targets
3. Language-specific: `EXPLAIN ANALYZE` (SQL), `go test -bench` (Go), `cargo bench` (Rust), `pytest-benchmark` (Python)

Run relevant commands based on discovered tooling.
```

And `verification/security.md`:

**Before** (`verification/security.md` line 88):

```markdown
## Severity Levels

See `.claude/references/shared-patterns.md#severity-levels` -- use the Security domain column.
```

**After**:

```markdown
## Severity Levels

| Level | Security | Action |
|-------|----------|--------|
| CRITICAL | Active exploitation possible | BLOCK -- Fix immediately |
| HIGH | Significant vulnerability | BLOCK -- Fix before merge |
| MEDIUM | Moderate risk | WARN -- Fix in current sprint |
| LOW | Minor issue | INFO -- Address when possible |
```

#### 3b. Generalize language-specific content

**quality.md** -- Change JS-specific checklist items to language-agnostic:

**Before** (lines 75-77):

```markdown
- [ ] Type annotations present (TypeScript)
- [ ] JSDoc for public functions
```

**After**:

```markdown
- [ ] Type annotations present (if language supports them)
- [ ] Public functions documented (docstrings, JSDoc, or equivalent)
```

**performance.md** -- Generalize "Frontend Performance" section:

**Before** (lines 59-77, section title "Frontend Performance" with React-specific items):

```markdown
### Rendering
- [ ] No layout thrashing
- [ ] Virtual scrolling for long lists
- [ ] Debounced/throttled handlers
- [ ] Memoization for expensive computations
```

**After** (rename to "UI Performance", generalize):

```markdown
### UI Performance (if applicable)
- [ ] No unnecessary re-renders or layout thrashing
- [ ] Efficient list rendering for large datasets
- [ ] Debounced/throttled event handlers
- [ ] Caching for expensive computations
```

**security.md** -- Generalize language-specific section:

**Before** (lines 68-78, language-specific sections):

```markdown
### JavaScript/TypeScript
- [ ] No `eval()` usage
- [ ] No `innerHTML` without sanitization
- [ ] Helmet.js or similar for headers
- [ ] CORS configured properly

### Python
- [ ] No `exec()` or `eval()` on user input
- [ ] ORM used (no raw SQL)
- [ ] Secret key management (not in code)
- [ ] CSRF protection enabled
```

**After**:

```markdown
### Language-Specific (check applicable)
- [ ] No `eval()`/`exec()` on user input (JS, Python, Ruby)
- [ ] No unsanitized HTML injection (`innerHTML`, etc.)
- [ ] ORM or parameterized queries used (no raw SQL concatenation)
- [ ] Security headers configured (Helmet.js, Django middleware, etc.)
- [ ] CORS configured properly
- [ ] CSRF protection enabled where applicable
- [ ] Secret management (no keys in source code)
```

### Estimated Savings

No significant byte reduction (the discovery protocol replaces hardcoded commands with slightly more text). The value is **correctness**: verification rules now work for any language, not just JavaScript/TypeScript projects. The inline severity tables also prepare for Strategy 4 (eliminating shared-patterns.md references).

---

## Strategy 4: Inline shared-patterns Sections and Delete the File

### Problem

`references/shared-patterns.md` (3,076 bytes) contains three sections referenced by 4 other files:

| Section | Referenced By |
|---------|--------------|
| `#quality-command-discovery` | Nobody (self-referential header only) |
| `#constraint-check-protocol` | `commands/task-constraints.md` line 101 |
| `#severity-levels` | `verification/quality.md` line 113, `verification/performance.md` line 95, `verification/security.md` line 88 |

After Strategy 3 inlines severity levels into each verification file, only `#constraint-check-protocol` remains referenced by `task-constraints.md`. At that point, shared-patterns.md becomes a single-purpose file with 3,076 bytes of overhead.

### Files Affected

| File | Bytes | Action |
|------|-------|--------|
| `references/shared-patterns.md` | 3,076 | **DELETE** after inlining |
| `commands/task-constraints.md` | 2,853 | Inline constraint-check-protocol |
| `verification/quality.md` | 2,917 | Remove shared-patterns reference (done in Strategy 3) |
| `verification/performance.md` | 2,625 | Remove shared-patterns reference (done in Strategy 3) |
| `verification/security.md` | 2,579 | Remove shared-patterns reference (done in Strategy 3) |

### Fix

The constraint-check-protocol section (shared-patterns.md lines 26-55, ~700 bytes) is the only content still referenced after Strategy 3. Inline it into `task-constraints.md`.

**Before** (`commands/task-constraints.md` lines 99-102):

```markdown
### Check Constraints

Follow the constraint check protocol from `.claude/references/shared-patterns.md#constraint-check-protocol`.
Then output the report using the format from `.claude/references/reports/constraint-compliance.md`.
```

**After**:

```markdown
### Check Constraints

**Load constraints from:**
1. `state.yml` -> `constraints.invariants`: rules that must NEVER be violated.
2. `state.yml` -> `constraints.decisions`: constraints derived from PRD decisions.
3. `state.yml` -> `constraints.discovered`: constraints found during implementation.
4. `prd.md` Section 10: human-readable constraint descriptions.

**For each constraint:**
1. Read the relevant implementation files.
2. Verify the code respects the constraint.
3. Classify violations: CRITICAL (invariant violated -- BLOCK), HIGH (decision violated -- BLOCK), MEDIUM (partially met -- WARN), LOW (minor -- INFO).
4. CRITICAL/HIGH: STOP and report. MEDIUM/LOW: note for report, continue.

Output the report using the format from `.claude/references/reports/constraint-compliance.md`.
```

This adds ~500 bytes to task-constraints.md but eliminates the 3,076-byte shared-patterns.md file entirely. The `#quality-command-discovery` section was never referenced by anyone (only the file itself mentions it in its header description), so it is simply dropped.

After Strategy 3 removes the severity-levels references from verification files, and this change removes the constraint-check-protocol reference from task-constraints.md, no files reference shared-patterns.md. Delete it.

### Estimated Savings

- Delete `shared-patterns.md`: **-3,076 bytes** on disk
- Add inline protocol to task-constraints.md: **+500 bytes**
- Net savings: **~2,576 bytes** on disk
- Per-verification token savings: eliminates 1 file read indirection (task-verifier no longer needs to discover and read shared-patterns.md for severity levels -- they are inline in the verification files it already loaded)

---

## Strategy 5: File-Based Exit Contracts

### Problem

Exit contracts (added in fix-2 Strategy 2) are currently free-text YAML blocks that agents output as the last thing in their response. The orchestrator (`task-execute.md`) must parse this YAML from prose text, which is fragile:

1. The agent may wrap the YAML in explanatory text ("Here is my exit contract:")
2. The YAML may be malformed (indentation errors, missing fields)
3. The orchestrator must use heuristics to find the block (look for `# EXIT CONTRACT` marker)
4. There is no structural validation -- a missing `quality_checks` field silently fails

### Files Affected

| File | Bytes | Action |
|------|-------|--------|
| `agents/task-executor.md` | 5,660 | Change exit contract to write to file + output summary |
| `agents/task-verifier.md` | 3,009 | Change exit contract to write to file + output summary |
| `agents/plan-verifier.md` | 2,991 | Change exit contract to write to file + output summary |
| `commands/task-execute.md` | 5,967 | Update validation to read from file instead of parsing response |

### Fix

Instead of free-text YAML in the response, each agent writes its exit contract to a file AND outputs a one-line summary. The orchestrator reads the file.

**Before** (`agents/task-executor.md` exit contract, lines 86-109):

```markdown
## Exit Contract

When your phase is complete (or if you cannot complete it), you MUST output a structured status block as the LAST thing in your response. This is mandatory -- the orchestrator validates this output.

```yaml
# EXIT CONTRACT -- Phase N
status: COMPLETE | PARTIAL | FAILED
phase: <phase_number>
todos_total: <count>
todos_done: <count>
files_written:
  - <path to each file you created or modified>
handoff_written: true | false | N/A  # N/A if last phase
constraints_discovered: <count>  # 0 if none
quality_checks: PASS | FAIL | SKIPPED
error: <description if PARTIAL or FAILED, null otherwise>
```

Rules:

- ALWAYS output this block, even on failure.
- `status: PARTIAL` means some TODOs completed but you could not finish.
- `status: FAILED` means you could not implement any TODOs.
- The orchestrator reads this to decide whether to proceed, retry, or stop.
```

**After**:

```markdown
## Exit Contract

When your phase is complete (or if you cannot complete it), you MUST:

1. Write `.temp/tasks/<task_name>/exit-phase-<N>.yml` with this structure:

```yaml
status: COMPLETE | PARTIAL | FAILED
phase: <phase_number>
todos_total: <count>
todos_done: <count>
files_written:
  - <path>
handoff_written: true | false | N/A
constraints_discovered: <count>
quality_checks: PASS | FAIL | SKIPPED
error: null | <description>
```

2. As the LAST line of your response, output:
   `EXIT: Phase <N> <status> | <todos_done>/<todos_total> todos | quality: <quality_checks>`

Rules:
- ALWAYS write the file, even on failure.
- The one-line summary lets the orchestrator quickly check status.
- The orchestrator reads the full YAML file for validation details.
```

Apply the same pattern to:

- `agents/task-verifier.md` -- writes `.temp/tasks/<task_name>/exit-verify.yml`
- `agents/plan-verifier.md` -- writes `.temp/tasks/<task_name>/exit-plan-verify.yml`

Then update the orchestrator:

**Before** (`commands/task-execute.md` step 5.5, lines 28-49):

```markdown
5.5. **Validate executor exit contracts (MANDATORY):**
   After each task-executor completes, parse its exit contract from the agent's final response.

   a. **Check contract exists.** If no exit contract block found in the agent's output:
      - Report warning: "Executor for phase N did not produce an exit contract."
      - Fall back to file-based validation: check if `plan-phase-N.md` has all TODOs marked `- [x]`.
   ...
```

**After**:

```markdown
5.5. **Validate executor exit contracts (MANDATORY):**
   After each task-executor completes:

   a. **Check for exit summary line.** Parse the agent's last response line for `EXIT: Phase N <status>`.
      If not found: report warning, fall back to file-based validation.

   b. **Read exit file.** Read `.temp/tasks/<task_name>/exit-phase-<N>.yml`.
      If file missing: report warning, fall back to TODO count validation.
      Parse YAML. Validate all required fields present.

   c. **Check status.** If `status: PARTIAL` or `status: FAILED`:
      - Report error, ask user: retry / skip / stop.

   d. **Check handoff.** If `handoff_written: true`, verify file exists on disk.

   e. **Check TODO consistency.** Compare `todos_done` against actual `- [x]` count in `plan-phase-N.md`.
```

### Estimated Savings

No byte reduction. Reliability improvement: deterministic YAML parsing from file vs. heuristic parsing from prose text. Eliminates the class of bugs where agents embed the exit contract in explanatory text or use slightly wrong formatting.

---

## Strategy 6: Fix Grep Fallback + Eliminate Redundant state.yml Reads

### Problem

Two related issues:

**Issue A: Grep fallback is degraded.**

The hook's Python mode injects a rich context block: active_task, status, task_path, verification_mode, phase_files, AND formatted constraints with type markers ([I], [D], [*]). But the grep fallback only injects: active_task, status, task_path, and verification_mode -- NO constraints, NO phase_files. This means agents running in grep-fallback mode cannot trust the hook injection and must read state.yml themselves.

**Issue B: Agents redundantly read state.yml for data the hook already injected.**

When Python mode works:
- Hook injects: constraints, verification_mode, phase_files
- task-executor line 21: "Read `state.yml` -> extract `active_task`, `verification_mode`, `constraints`" -- re-reads what hook already provided
- task-verifier line 19: "Read `state.yml` -> extract constraints, `verification_mode`, and `phase_files`" -- same re-read

The agents should trust the hook's injection (when it includes the full data) and only re-read state.yml when the hook context is incomplete (grep fallback mode) or when they need to WRITE to state.yml (constraint propagation).

### Files Affected

| File | Bytes | Action |
|------|-------|--------|
| `hooks/inject-task-context.sh` | 3,595 | Upgrade grep fallback to include constraints and phase_files |
| `agents/task-executor.md` | 5,660 | Use hook-injected context when available, skip redundant reads |
| `agents/task-verifier.md` | 3,009 | Use hook-injected context when available, skip redundant reads |
| `agents/constraint-tracker.md` | 2,049 | Keep state.yml reads (authoritative source for audit) |

### Fix

#### 6a. Upgrade grep fallback to include constraints and phase_files

The grep fallback currently only extracts scalar values. Adding constraint and phase_file extraction with grep is feasible because state.yml has a predictable structure.

**Before** (`hooks/inject-task-context.sh` grep fallback, lines 83-97):

```bash
parse_with_grep() {
  active_task=$(grep "^active_task:" "$STATE_FILE" | head -1 | sed 's/^active_task:[[:space:]]*//' | tr -d '"')
  status=$(grep "^status:" "$STATE_FILE" | head -1 | sed 's/^status:[[:space:]]*//' | tr -d '"')
  task_path=$(grep "^task_path:" "$STATE_FILE" | head -1 | sed 's/^task_path:[[:space:]]*//' | tr -d '"')
  vm=$(grep "^verification_mode:" "$STATE_FILE" | head -1 | sed 's/^verification_mode:[[:space:]]*//' | tr -d '"')

  if [[ -z "$active_task" || "$active_task" == "null" || "$active_task" == "none" ]]; then
    exit 0
  fi

  echo "Active task: $active_task (status: $status, mode: ${vm:-per_phase})" >&2

  printf '{"additionalContext":"ACTIVE TASK CONTEXT:\\n- Task: %s\\n- Status: %s\\n- Path: %s\\n- PRD: %s/prd.md\\n- Plan: %s/plan.md\\n- Verification Mode: %s\\nAlways read state.yml and relevant task files before acting on any /task-* command.\\nIMPORTANT: Check constraints before making changes. Invariants must NEVER be violated."}' \
    "$active_task" "$status" "$task_path" "$task_path" "$task_path" "${vm:-per_phase}"
}
```

**After**:

```bash
parse_with_grep() {
  active_task=$(grep "^active_task:" "$STATE_FILE" | head -1 | sed 's/^active_task:[[:space:]]*//' | tr -d '"')
  status=$(grep "^status:" "$STATE_FILE" | head -1 | sed 's/^status:[[:space:]]*//' | tr -d '"')
  task_path=$(grep "^task_path:" "$STATE_FILE" | head -1 | sed 's/^task_path:[[:space:]]*//' | tr -d '"')
  vm=$(grep "^verification_mode:" "$STATE_FILE" | head -1 | sed 's/^verification_mode:[[:space:]]*//' | tr -d '"')

  if [[ -z "$active_task" || "$active_task" == "null" || "$active_task" == "none" ]]; then
    exit 0
  fi

  # Extract phase_files
  pf_list=""
  in_pf=0
  while IFS= read -r line; do
    if [[ "$line" == "phase_files:" ]]; then in_pf=1; continue; fi
    if [[ $in_pf -eq 1 ]]; then
      [[ "$line" =~ ^[a-zA-Z] ]] && break
      f=$(echo "$line" | sed 's/^[[:space:]]*- //' | tr -d '"')
      [[ -n "$f" ]] && pf_list="${pf_list:+$pf_list, }$f"
    fi
  done < "$STATE_FILE"

  # Extract constraints (simple text extraction)
  c_block=""
  in_inv=0; in_dec=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*invariants: ]]; then in_inv=1; in_dec=0; continue; fi
    if [[ "$line" =~ ^[[:space:]]*decisions: ]]; then in_dec=1; in_inv=0; continue; fi
    if [[ "$line" =~ ^[[:space:]]*discovered: ]]; then in_dec=0; in_inv=0; continue; fi
    if [[ $in_inv -eq 1 || $in_dec -eq 1 ]] && [[ "$line" =~ ^[[:space:]]+- ]]; then
      c_text=$(echo "$line" | sed 's/^[[:space:]]*- //' | sed 's/.*constraint:[[:space:]]*//' | tr -d '"')
      [[ -n "$c_text" ]] && c_block="${c_block}\\n  - $c_text"
    fi
    [[ "$line" =~ ^[a-z] ]] && { in_inv=0; in_dec=0; }
  done < "$STATE_FILE"

  echo "Active task: $active_task (status: $status, mode: ${vm:-per_phase})" >&2

  ctx="ACTIVE TASK CONTEXT:\\n- Task: ${active_task}\\n- Status: ${status}\\n- Path: ${task_path}\\n- PRD: ${task_path}/prd.md\\n- Plan: ${task_path}/plan.md\\n- Verification Mode: ${vm:-per_phase}"
  [[ -n "$pf_list" ]] && ctx="${ctx}\\n- Phase Files: ${pf_list}"
  [[ -n "$c_block" ]] && ctx="${ctx}\\n\\nCONSTRAINTS:${c_block}"
  ctx="${ctx}\\n\\nAlways read state.yml and relevant task files before acting on any /task-* command.\\nIMPORTANT: Check constraints before making changes. Invariants must NEVER be violated."

  printf '{"additionalContext":"%s"}' "$ctx"
}
```

This adds ~30 lines to the grep fallback but brings it to feature parity with the Python mode. The constraint extraction is a best-effort grep -- it may not handle every YAML edge case, but it covers the common patterns (constraint text in `constraint:` fields or bare strings).

#### 6b. Eliminate redundant state.yml reads in agents

The hook now always injects constraints, verification_mode, and phase_files (in both Python and grep modes). Agents should use the hook-injected context as their primary source and only read state.yml when they need to write to it.

**Before** (`agents/task-executor.md` lines 21-28):

```markdown
1. **Load context:** Read `state.yml` -> extract `active_task`, `verification_mode`, `constraints`.
   Read your `plan-phase-N.md` (at `phase_file_path`) as primary source.
   Read `prd.md` for requirements and constraints.
   You do NOT need to read other phase files unless checking a dependency.
   If `verification_mode` is `per_phase`, run quality checks; if `final` or `none`, skip them.
2. **Pre-Implementation Constraint Check (MANDATORY):**
   Read all constraints from `state.yml` (invariants, decisions, discovered) and `prd.md` Section 10.
   If ANY would be violated by your planned implementation: STOP and report to user before proceeding.
```

**After**:

```markdown
1. **Load context:** The hook has injected ACTIVE TASK CONTEXT into your session containing task, status, path, verification_mode, phase files, and constraints.
   If the hook context is present: use it for verification_mode, phase files, and constraints. Do NOT re-read state.yml for these.
   If the hook context is missing or incomplete: read `state.yml` as fallback.
   Read your `plan-phase-N.md` (at `phase_file_path`) as primary source.
   Read `prd.md` for requirements and additional constraint details.
2. **Pre-Implementation Constraint Check (MANDATORY):**
   Use the constraints from hook context (or state.yml if fallback). Also read `prd.md` Section 10.
   If ANY would be violated by your planned implementation: STOP and report to user before proceeding.
```

Note that task-executor still reads state.yml when it needs to WRITE to it (step 3.5, propagating discovered constraints). That read is necessary and unchanged.

**Before** (`agents/task-verifier.md` line 19):

```markdown
1. **Load context:** Read `state.yml` -> extract constraints, `verification_mode`, and `phase_files`.
```

**After**:

```markdown
1. **Load context:** Use the hook-injected ACTIVE TASK CONTEXT for constraints, `verification_mode`, and `phase_files`. If hook context is missing, read `state.yml` as fallback.
```

**constraint-tracker.md** -- Keep unchanged. It reads state.yml as the authoritative source for audits, which is correct. The hook injection is a convenience cache, not the source of truth for audit purposes.

### Estimated Savings

- Grep fallback upgrade: +~600 bytes to hook file, but eliminates the degraded mode entirely
- Agent redundancy elimination: saves ~300-600 tokens per agent spawn by avoiding a redundant state.yml read + parse. For a 4-phase execution chain (4 executors + 1 verifier), saves ~1,500-3,000 tokens of state.yml re-reading
- Reliability: all systems now have the same context regardless of Python availability

---

## New File Structure

```
.claude/
├── agents/
│   ├── constraint-tracker.md       # unchanged (reads state.yml as authority)
│   ├── docs-initializer.md         # unchanged
│   ├── docs-manager.md             # unchanged
│   ├── docs-researcher.md          # unchanged
│   ├── localization-agent.md       # unchanged
│   ├── phase-reviewer.md           # unchanged
│   ├── plan-verifier.md            # file-based exit contract
│   ├── task-executor.md            # file-based exit contract, trust hook context
│   └── task-verifier.md            # file-based exit contract, trust hook context
├── commands/
│   ├── project-docs.md             # unchanged
│   ├── project-rules.md            # unchanged
│   ├── task-add-context.md         # unchanged
│   ├── task-checkpoint.md          # unchanged
│   ├── task-clarify.md             # unchanged
│   ├── task-complete.md            # unchanged
│   ├── task-constraints.md         # inlined constraint-check-protocol (~+500 bytes)
│   ├── task-create.md              # unchanged
│   ├── task-execute.md             # file-based exit contract validation
│   ├── task-list.md                # unchanged
│   ├── task-plan.md                # unchanged
│   ├── task-run.md                 # unchanged
│   ├── task-update-docs.md         # unchanged
│   └── task-verify.md              # unchanged
├── hooks/
│   └── inject-task-context.sh      # upgraded grep fallback (~+600 bytes)
├── references/
│   ├── prd-templates.md            # unchanged
│   ├── skill-creation-guidelines.md # MOVED from skills/new-skill/ (trimmed)
│   └── reports/                    # unchanged
│       ├── constraint-compliance.md
│       ├── documentation.md
│       ├── handoff.md
│       ├── localization-report.md
│       ├── phase-review.md
│       ├── plan-verification-report.md
│       └── verification-report.md
├── skills/
│   ├── docs/
│   │   ├── SKILL.md                # tightened triggers, trimmed output formats
│   │   └── references/
│   │       ├── DUPLICATE_CHECK.md  # compressed (~1,500 bytes)
│   │       ├── README_TEMPLATE.md  # unchanged
│   │       └── FEATURE_DOC_TEMPLATE.md # unchanged
│   └── project-rules/
│       ├── SKILL.md                # tightened triggers, trimmed output formats
│       └── references/
│           └── RULE_TEMPLATE.md    # unchanged
└── verification/
    ├── performance.md              # project-agnostic, inline severity
    ├── quality.md                  # project-agnostic, inline severity
    └── security.md                 # project-agnostic, inline severity
```

**Deleted files:**
- `skills/docs/references/SEARCH_PATTERNS.md`
- `skills/project-rules/references/MEMORY_HIERARCHY.md`
- `skills/project-rules/references/DISCOVERY_PATTERNS.md`
- `references/shared-patterns.md`
- `skills/new-skill/` directory (moved to references)

**Files moved:**
- `skills/new-skill/skill-creation-guidelines.md` -> `references/skill-creation-guidelines.md`

---

## Projected Totals

| Category | Before (bytes) | After (bytes) | Change |
|----------|----------------|---------------|--------|
| Skills | 60,428 | ~34,740 | **-42%** (3 refs deleted, 1 compressed, SKILL.md trimmed) |
| Commands | 42,403 | ~42,900 | +1% (constraint protocol inlined) |
| Agents | 24,130 | ~24,500 | +1.5% (file-based exit contracts) |
| References | 18,210 | ~18,480 | +1.5% (skill-creation moved in, shared-patterns deleted, net slightly up due to new file) |
| Verification | 8,121 | ~8,200 | +1% (inline severity tables, generalize) |
| Hook | 3,595 | ~4,200 | +17% (upgraded grep fallback) |
| **Total** | **156,887** | **~133,020** | **-15.2%** |

But total on-disk size is not the real metric. The key metric is **active context per conversation**:

| Scenario | Before | After | Reduction |
|----------|--------|-------|-----------|
| False-triggered "docs" skill (user just said "README") | ~25,314 bytes (SKILL.md + 4 refs) | 0 bytes (no trigger) | **-100%** |
| Correctly-triggered docs skill | ~25,314 bytes | ~14,960 bytes | **-41%** |
| False-triggered "convention" / "CLAUDE.md" | ~27,022 bytes (SKILL.md + 3 refs) | 0 bytes (no trigger) | **-100%** |
| Correctly-triggered project-rules skill | ~27,022 bytes | ~11,407 bytes | **-58%** |
| Task execution (4-phase, deep verify) | ~3,076 bytes shared-patterns + redundant state.yml reads | 0 bytes shared-patterns + ~1,500 tokens saved from state.yml | **-100%** (shared-patterns), **-3K tokens** (state.yml) |

---

## Implementation Priority

1. **Do first** (highest impact, lowest effort):
   - Tighten skill triggers in `skills/docs/SKILL.md` and `skills/project-rules/SKILL.md` (Strategy 1a). Immediate reduction in false-trigger token waste.
   - Move `skills/new-skill/skill-creation-guidelines.md` to `references/skill-creation-guidelines.md` and trim (Strategy 2). Quick organizational win.

2. **Do second** (high impact, medium effort):
   - Delete `SEARCH_PATTERNS.md`, `MEMORY_HIERARCHY.md`, `DISCOVERY_PATTERNS.md` and update SKILL.md reference lists (Strategy 1b, 1d, 1e). Major byte savings.
   - Compress `DUPLICATE_CHECK.md` (Strategy 1c).
   - Inline shared-patterns sections and delete the file (Strategy 4). Depends on Strategy 3 severity-level inlining.

3. **Do third** (correctness + reliability):
   - Make verification rules project-agnostic (Strategy 3). Correctness fix.
   - Trim SKILL.md output format sections (Strategy 1f).
   - Upgrade grep fallback (Strategy 6a).

4. **Do fourth** (reliability, no token change):
   - File-based exit contracts (Strategy 5). Structural improvement.
   - Eliminate redundant state.yml reads (Strategy 6b). Depends on 6a.

---

## Validation

After applying all changes, verify by:

### 1. No orphaned references

```bash
grep -r "SEARCH_PATTERNS" .claude/
# Must return zero results

grep -r "MEMORY_HIERARCHY" .claude/
# Must return zero results

grep -r "DISCOVERY_PATTERNS" .claude/
# Must return zero results

grep -r "shared-patterns" .claude/
# Must return zero results

grep -r "skills/new-skill" .claude/
# Must return zero results
```

### 2. File structure

```bash
# These must NOT exist:
ls .claude/skills/docs/references/SEARCH_PATTERNS.md 2>/dev/null && echo "FAIL"
ls .claude/skills/project-rules/references/MEMORY_HIERARCHY.md 2>/dev/null && echo "FAIL"
ls .claude/skills/project-rules/references/DISCOVERY_PATTERNS.md 2>/dev/null && echo "FAIL"
ls .claude/references/shared-patterns.md 2>/dev/null && echo "FAIL"
ls .claude/skills/new-skill/ 2>/dev/null && echo "FAIL"

# These must exist:
ls .claude/skills/docs/references/DUPLICATE_CHECK.md
ls .claude/skills/docs/references/README_TEMPLATE.md
ls .claude/skills/docs/references/FEATURE_DOC_TEMPLATE.md
ls .claude/skills/project-rules/references/RULE_TEMPLATE.md
ls .claude/references/skill-creation-guidelines.md
```

### 3. Skill triggers

Test that casual conversation does NOT trigger the skills:
- Say "docs" or "README" in conversation -- neither skill should load
- Say "convention" or "CLAUDE.md" -- project-rules skill should NOT load
- Say "initialize docs" -- docs skill SHOULD load
- Say "add coding rule" -- project-rules skill SHOULD load
- Use `/project-docs init` -- docs skill SHOULD load
- Use `/project-rules discover` -- project-rules skill SHOULD load

### 4. Hook functionality (both modes)

```bash
# Create test state.yml
mkdir -p .temp/tasks
cat > .temp/tasks/state.yml << 'EOF'
active_task: test-hook
status: in_progress
task_path: .temp/tasks/test-hook
verification_mode: per_phase
phase_files:
  - plan-phase-1.md
constraints:
  invariants:
    - id: I1
      constraint: "All API calls must be authenticated"
  decisions:
    - id: D1-1
      from_decision: D1
      constraint: "Use OAuth2 with PKCE"
  discovered: []
EOF

# Test with Python
bash .claude/hooks/inject-task-context.sh
# Must output JSON with: Phase Files, CONSTRAINTS section, [I] and [D] markers

# Test grep fallback (simulate no Python)
PATH=/usr/bin bash .claude/hooks/inject-task-context.sh
# Must output JSON with: Phase Files, CONSTRAINTS section (may be simpler format)
# Must NOT be missing constraints entirely

rm -rf .temp/tasks
```

### 5. Verification rules agnostic

```bash
grep -c "npm\|npx" .claude/verification/*.md
# Must return: 0 for all three files

grep "TypeScript" .claude/verification/quality.md
# Must NOT contain JS-only phrasing like "Type annotations present (TypeScript)"
# Should contain language-agnostic phrasing
```

### 6. Exit contract files

```bash
# After running a task execution, check:
ls .temp/tasks/<task_name>/exit-phase-*.yml
ls .temp/tasks/<task_name>/exit-verify.yml
# Must exist and contain valid YAML with all required fields
```

---

## Key Principle

> A workflow system that users copy into their projects must minimize its ambient footprint. Every byte that loads on a false trigger is a tax on every conversation. The highest-leverage optimization is not trimming commands or agents (which load only when invoked), but tightening the skill trigger surface so that 52KB of documentation-tooling only loads when the user actually asks for documentation tooling.
