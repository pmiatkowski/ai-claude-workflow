# /task-clarify

Run a structured clarification session for the active task.

## Steps

1. Read `.temp/tasks/state.yml` to identify the active task.
2. Read the task's `prd.md` file.
3. Check `$ARGUMENTS`:
   - If user specified a number (e.g., `5`) — run exactly that many questions.
   - If user specified a topic (e.g., `auth flow`) — focus questions on that topic.
   - If no arguments — analyze the PRD's "Gaps & Ambiguities" and "Open Questions" sections and decide how many questions are needed (typically 3–8, scaled to complexity).
4. Run the clarification session using the format below.
5. After the final question, ask the user:
   > "That covers the key questions. Would you like another round of clarification, or shall I update the PRD with your answers?"

## Clarification Session Format

For each question: explain why it matters (1-2 sentences), present options in a table (option/description/tradeoffs), give your recommendation. Ask questions one at a time — maintain a natural flow, do NOT ask if the user wants to continue. Wait for response. Accept single option, combinations, or modifications. Note answers internally; summarize only at the end.

## After Session Ends

When the user says "update PRD" (or equivalent):
1. Rewrite `prd.md` incorporating all answers directly — no change annotations, the document should read as if always written this way.
2. Populate the Decision Matrix (Section 9): one row per question (D1, D2, D3... with topic, options, choice, reasoning, date).
3. Extract constraints to Section 10: invariants discovered + decision-derived constraints (`From D{N}: {constraint}`).
4. Update `.temp/tasks/state.yml` constraints (invariants list + decisions with id/constraint) and `updated_at`.
5. Tell the user what changed and suggest `/task-add-context` or `/task-plan` next.
