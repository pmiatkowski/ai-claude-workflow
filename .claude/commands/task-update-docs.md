# /task-update-docs

Update project documentation based on the completed task implementation.

## Steps

1. Read `.temp/tasks/state.yml` to identify the active task.

2. Read the task artifacts:
   - `prd.md` - What was requested and why
   - `prd.md` Section 13 - Ad-hoc changes made during implementation
   - `plan.md` - What was implemented (check for completed phases)

3. Analyze what changed:
   - New features added
   - Existing features modified
   - Features/APIs removed
   - Configuration changes
   - New dependencies
   - Ad-hoc changes from Section 13

4. **Research existing documentation** (using docs-researcher patterns):
   - Search README.md for related content
   - Search ./docs/*.md for related content
   - Identify documentation gaps and overlaps

5. **Generate ADRs from Decision Matrix**:
   - Read PRD Section 9 (Decisions)
   - For each significant decision (architectural, technology choice, pattern):
     - Create ADR file: `docs/adr/NNN-[slug].md`
     - Number sequentially based on existing ADRs
   - ADR format: Header "ADR-N: [Title]". Sections: Status, Context (from PRD), Decision (from Decision Matrix), Consequences (derived constraints from PRD Section 10), Alternatives Considered (table: Option, Pros, Cons, Why Not Chosen), Date.

6. Generate documentation update suggestions: Header "Documentation Update Analysis". Sections: Implementation Summary, Ad-Hoc Changes (table: Date, Type, Description, Doc Impact), Related Existing Documentation (table: File, Section, Relevance), Suggested Updates with subsections — New Documentation Needed (table: Priority, Topic, File), Updates to Existing Docs (table: File, Section, Change), Potential Duplicates (table: New Topic, Existing Doc, Action).

6. Ask user:
   > "Apply which updates? [all/selective/none]"
   >
   > For selective: "Which items would you like to apply?"

7. Spawn `docs-manager` agent with:
   - `action`: "add" or "change" based on update type
   - `prd_path`: path to PRD for context
   - `plan_path`: path to plan for context
   - Specific updates to apply

8. After docs-manager completes, summarize: Header "Documentation Updated". Sections: Files Changed (list with change description), Files Created (list with description), Cross-references Verified.

## Integration with /project-docs

This command uses the `docs` skill infrastructure:
- Uses `docs-researcher` patterns for finding existing content
- Spawns `docs-manager` agent for CRUD operations
- Follows duplicate detection rules before adding
- Uses templates from `.claude/skills/docs/references/`

## Discovery Locations

Always check these locations:
- `README.md` (root)
- `./docs/*.md` (feature documentation)
- `./docs/api/*.md` (API reference)
- `./docs/guides/*.md` (tutorials)
- `CLAUDE.md` (AI guidelines - separate from user docs)
- PRD Section 12 (Additional Context) for doc references

## Hard Rules

- ALWAYS research existing docs before suggesting updates
- ALWAYS check for duplicates before creating new docs
- ALWAYS ask user before applying changes
- NEVER update CLAUDE.md from this command (use /rules for that)
- Keep README.md concise - details go in ./docs/
